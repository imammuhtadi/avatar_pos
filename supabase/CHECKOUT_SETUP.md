# Checkout System - Supabase Setup

## Database Functions for Checkout

Run these SQL scripts in your Supabase SQL Editor:

### 1. Create Checkout Function

This function handles the entire checkout process atomically:

- Creates transaction record
- Creates transaction items
- Updates product stock
- Returns the complete transaction with items

```sql
-- Function to process checkout
CREATE OR REPLACE FUNCTION process_checkout(
  p_cashier_id UUID DEFAULT NULL,
  p_items JSONB DEFAULT '[]'::JSONB,
  p_payment_method TEXT DEFAULT 'cash',
  p_customer_name TEXT DEFAULT NULL,
  p_customer_phone TEXT DEFAULT NULL,
  p_customer_email TEXT DEFAULT NULL,
  p_paid_amount DECIMAL DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_transaction_id UUID;
  v_transaction_number TEXT;
  v_subtotal DECIMAL := 0;
  v_tax DECIMAL := 0;
  v_discount DECIMAL := 0;
  v_total DECIMAL := 0;
  v_change_amount DECIMAL := 0;
  v_item JSONB;
  v_product_price DECIMAL;
  v_product_stock INTEGER;
  v_result JSONB;
BEGIN
  -- Generate transaction number (format: TRX-YYYYMMDD-XXXXX)
  v_transaction_number := 'TRX-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                          LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');

  -- Calculate subtotal from items
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    -- Get product price and validate stock
    SELECT price, stock INTO v_product_price, v_product_stock
    FROM products
    WHERE id = (v_item->>'product_id')::UUID
    AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Product % not found or inactive', v_item->>'product_id';
    END IF;

    IF v_product_stock < (v_item->>'quantity')::INTEGER THEN
      RAISE EXCEPTION 'Insufficient stock for product %', v_item->>'product_id';
    END IF;

    -- Add to subtotal
    v_subtotal := v_subtotal + (v_product_price * (v_item->>'quantity')::INTEGER);
  END LOOP;

  -- Calculate tax (10% - adjust as needed)
  v_tax := v_subtotal * 0.10;

  -- Calculate total
  v_total := v_subtotal + v_tax - v_discount;

  -- Calculate change
  IF p_paid_amount IS NOT NULL THEN
    v_change_amount := p_paid_amount - v_total;
    IF v_change_amount < 0 THEN
      RAISE EXCEPTION 'Insufficient payment amount';
    END IF;
  END IF;

  -- Create transaction
  INSERT INTO transactions (
    transaction_number,
    cashier_id,
    customer_name,
    customer_phone,
    customer_email,
    subtotal,
    tax,
    discount,
    total,
    payment_method,
    payment_status,
    paid_amount,
    change_amount,
    notes
  ) VALUES (
    v_transaction_number,
    p_cashier_id,
    p_customer_name,
    p_customer_phone,
    p_customer_email,
    v_subtotal,
    v_tax,
    v_discount,
    v_total,
    p_payment_method,
    'completed',
    p_paid_amount,
    v_change_amount,
    p_notes
  ) RETURNING id INTO v_transaction_id;

  -- Create transaction items and update stock
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    -- Get product details
    SELECT price INTO v_product_price
    FROM products
    WHERE id = (v_item->>'product_id')::UUID;

    -- Insert transaction item
    INSERT INTO transaction_items (
      transaction_id,
      product_id,
      product_name,
      total,
      quantity,
      unit_price,
      subtotal
    )
    SELECT
      v_transaction_id,
      (v_item->>'product_id')::UUID,
      p.name,
      v_product_price * (v_item->>'quantity')::INTEGER,
      (v_item->>'quantity')::INTEGER,
      v_product_price,
      v_product_price * (v_item->>'quantity')::INTEGER
    FROM products p
    WHERE p.id = (v_item->>'product_id')::UUID;

    -- Update product stock
    UPDATE products
    SET
      stock = stock - (v_item->>'quantity')::INTEGER,
      updated_at = NOW()
    WHERE id = (v_item->>'product_id')::UUID;
  END LOOP;

  -- Return complete transaction with items
  SELECT jsonb_build_object(
    'transaction', row_to_json(t.*),
    'items', (
      SELECT jsonb_agg(row_to_json(ti.*))
      FROM transaction_items ti
      WHERE ti.transaction_id = v_transaction_id
    )
  ) INTO v_result
  FROM transactions t
  WHERE t.id = v_transaction_id;

  RETURN v_result;
END;
$$;
```

### 2. Create Helper Functions

```sql
-- Function to get transaction with items
CREATE OR REPLACE FUNCTION get_transaction_with_items(p_transaction_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'transaction', row_to_json(t.*),
    'items', (
      SELECT jsonb_agg(row_to_json(ti.*))
      FROM transaction_items ti
      WHERE ti.transaction_id = p_transaction_id
    )
  ) INTO v_result
  FROM transactions t
  WHERE t.id = p_transaction_id;

  RETURN v_result;
END;
$$;

-- Function to get today's transactions
CREATE OR REPLACE FUNCTION get_today_transactions()
RETURNS SETOF transactions
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT *
  FROM transactions
  WHERE DATE(created_at) = CURRENT_DATE
  ORDER BY created_at DESC;
$$;

-- Function to get sales summary
CREATE OR REPLACE FUNCTION get_sales_summary(
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_start_date TIMESTAMPTZ;
  v_end_date TIMESTAMPTZ;
  v_result JSONB;
BEGIN
  v_start_date := COALESCE(p_start_date, CURRENT_DATE);
  v_end_date := COALESCE(p_end_date, CURRENT_DATE + INTERVAL '1 day');

  SELECT jsonb_build_object(
    'total_transactions', COUNT(*),
    'total_revenue', COALESCE(SUM(total), 0),
    'total_tax', COALESCE(SUM(tax), 0),
    'total_discount', COALESCE(SUM(discount), 0),
    'payment_methods', (
      SELECT jsonb_object_agg(
        payment_method,
        jsonb_build_object(
          'count', count,
          'total', total
        )
      )
      FROM (
        SELECT
          payment_method,
          COUNT(*) as count,
          SUM(total) as total
        FROM transactions
        WHERE created_at >= v_start_date
        AND created_at < v_end_date
        GROUP BY payment_method
      ) pm
    )
  ) INTO v_result
  FROM transactions
  WHERE created_at >= v_start_date
  AND created_at < v_end_date;

  RETURN v_result;
END;
$$;
```

### 3. Grant Permissions

```sql
-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION process_checkout TO authenticated;
GRANT EXECUTE ON FUNCTION get_transaction_with_items TO authenticated;
GRANT EXECUTE ON FUNCTION get_today_transactions TO authenticated;
GRANT EXECUTE ON FUNCTION get_sales_summary TO authenticated;
```

### 4. Test the Checkout Function

```sql
-- Test checkout (replace UUIDs with actual values from your database)
SELECT process_checkout(
  p_cashier_id := 'YOUR_USER_ID'::UUID,
  p_items := '[
    {"product_id": "PRODUCT_ID_1", "quantity": 2},
    {"product_id": "PRODUCT_ID_2", "quantity": 1}
  ]'::JSONB,
  p_payment_method := 'cash',
  p_customer_name := 'John Doe',
  p_paid_amount := 100.00
);
```

## Usage Notes

1. **Transaction Number Format**: `TRX-YYYYMMDD-XXXXX`

   - Example: `TRX-20260110-12345`

2. **Tax Calculation**: Currently set to 10%

   - Modify `v_tax := v_subtotal * 0.10;` to change rate

3. **Stock Management**: Automatically deducts stock on checkout

   - Validates stock availability before processing

4. **Payment Methods**:

   - `cash`
   - `card`
   - `digital_wallet`
   - `bank_transfer`

5. **Error Handling**:
   - Validates product exists and is active
   - Checks sufficient stock
   - Validates payment amount
   - All operations are atomic (rollback on error)
