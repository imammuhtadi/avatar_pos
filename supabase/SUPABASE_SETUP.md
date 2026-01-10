# Supabase Setup Guide - Avatar POS

Complete database setup for the Avatar POS system including tables, functions, triggers, and security policies.

---

## 📋 Table of Contents

1. [Create Supabase Project](#1-create-supabase-project)
2. [Run Database Migrations](#2-run-database-migrations)
   - [Step 1: Create Core Tables](#step-1-create-core-tables)
   - [Step 2: Create Functions and Triggers](#step-2-create-functions-and-triggers)
   - [Step 3: Enable Row Level Security](#step-3-enable-row-level-security)
   - [Step 4: Create User & Insert Sample Data](#step-4-create-authentication-user--insert-sample-data)
3. [Configure Flutter App](#3-configure-flutter-app)
4. [Common Issues](#common-issues)

---

## 1. Create Supabase Project

**Instructions:**

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click **"New Project"**
4. Fill in:
   - **Project Name**: `avatar-pos`
   - **Database Password**: Save this securely!
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Free tier (for development)
5. Wait for project to finish setting up (~2 minutes)

---

## 2. Run Database Migrations

**Instructions:**

Go to **SQL Editor** in your Supabase dashboard and run these SQL scripts **in order**:

#### Step 1: Create Core Tables

```sql
-- 1. Users table (extends auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'cashier' CHECK (role IN ('admin', 'manager', 'cashier')),
  phone TEXT,
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- 2. Categories table
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  color TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_categories_name ON categories(name);

-- 3. Products table
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  sku TEXT UNIQUE,
  barcode TEXT UNIQUE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  cost DECIMAL(10, 2) CHECK (cost >= 0),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  min_stock INTEGER DEFAULT 0,
  unit TEXT DEFAULT 'pcs',
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);

-- 4. Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_number TEXT UNIQUE NOT NULL,
  cashier_id UUID REFERENCES users(id) ON DELETE SET NULL,
  customer_name TEXT,
  customer_phone TEXT,
  customer_email TEXT,
  subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
  tax DECIMAL(10, 2) DEFAULT 0 CHECK (tax >= 0),
  discount DECIMAL(10, 2) DEFAULT 0 CHECK (discount >= 0),
  total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'card', 'digital_wallet', 'bank_transfer')),
  payment_status TEXT NOT NULL DEFAULT 'completed' CHECK (payment_status IN ('pending', 'completed', 'refunded', 'cancelled')),
  paid_amount DECIMAL(10, 2) CHECK (paid_amount >= 0),
  change_amount DECIMAL(10, 2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transactions_number ON transactions(transaction_number);
CREATE INDEX idx_transactions_cashier ON transactions(cashier_id);
CREATE INDEX idx_transactions_date ON transactions(created_at);
CREATE INDEX idx_transactions_status ON transactions(payment_status);

-- 5. Transaction items table
CREATE TABLE transaction_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  product_sku TEXT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
  subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
  discount DECIMAL(10, 2) DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id);
CREATE INDEX idx_transaction_items_product ON transaction_items(product_id);

-- 6. Stock movements table
CREATE TABLE stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  movement_type TEXT NOT NULL CHECK (movement_type IN ('purchase', 'sale', 'adjustment', 'return')),
  quantity INTEGER NOT NULL,
  previous_stock INTEGER NOT NULL,
  new_stock INTEGER NOT NULL,
  reference_id UUID,
  reference_type TEXT,
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_type ON stock_movements(movement_type);
CREATE INDEX idx_stock_movements_date ON stock_movements(created_at);
```

---

#### Step 2: Create Functions and Triggers

**What this does:**

- Auto-creates user records when someone signs up
- Updates `updated_at` timestamps automatically
- Generates unique transaction numbers
- Handles stock updates after transactions
- Processes complete checkout transactions
- Provides helper functions for querying transactions

**SQL to run:**

```sql
-- Function to automatically create user record when auth user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'cashier'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user record on auth signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to update updated_at timestamp
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate transaction number
DROP FUNCTION IF EXISTS generate_transaction_number();

CREATE OR REPLACE FUNCTION generate_transaction_number()
RETURNS TEXT AS $$
DECLARE
  today TEXT;
  count INTEGER;
  new_number TEXT;
BEGIN
  today := TO_CHAR(NOW(), 'YYYYMMDD');

  SELECT COUNT(*) INTO count
  FROM transactions
  WHERE transaction_number LIKE 'TRX-' || today || '%';

  new_number := 'TRX-' || today || '-' || LPAD((count + 1)::TEXT, 4, '0');

  RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Function to update stock after transaction
DROP TRIGGER IF EXISTS trigger_update_stock_after_transaction ON transactions;
DROP FUNCTION IF EXISTS update_stock_after_transaction();

CREATE OR REPLACE FUNCTION update_stock_after_transaction()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.payment_status = 'completed' AND (OLD.payment_status IS NULL OR OLD.payment_status != 'completed') THEN
    UPDATE products p
    SET stock = stock - ti.quantity,
        updated_at = NOW()
    FROM transaction_items ti
    WHERE ti.transaction_id = NEW.id
      AND ti.product_id = p.id;

    INSERT INTO stock_movements (product_id, movement_type, quantity, previous_stock, new_stock, reference_id, reference_type, created_by)
    SELECT
      ti.product_id,
      'sale',
      -ti.quantity,
      p.stock + ti.quantity,
      p.stock,
      NEW.id,
      'transaction',
      NEW.cashier_id
    FROM transaction_items ti
    JOIN products p ON p.id = ti.product_id
    WHERE ti.transaction_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_after_transaction
  AFTER INSERT OR UPDATE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_stock_after_transaction();

-- Checkout function - Process complete checkout transaction
DROP FUNCTION IF EXISTS process_checkout CASCADE;

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
  -- Generate transaction number
  v_transaction_number := 'TRX-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                          LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');

  -- Calculate subtotal and validate stock
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    SELECT price, stock INTO v_product_price, v_product_stock
    FROM products
    WHERE id = (v_item->>'product_id')::UUID AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Product % not found or inactive', v_item->>'product_id';
    END IF;

    IF v_product_stock < (v_item->>'quantity')::INTEGER THEN
      RAISE EXCEPTION 'Insufficient stock for product %', v_item->>'product_id';
    END IF;

    v_subtotal := v_subtotal + (v_product_price * (v_item->>'quantity')::INTEGER);
  END LOOP;

  -- Calculate tax (10%)
  v_tax := v_subtotal * 0.10;
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
    transaction_number, cashier_id, customer_name, customer_phone, customer_email,
    subtotal, tax, discount, total, payment_method, payment_status,
    paid_amount, change_amount, notes
  ) VALUES (
    v_transaction_number, p_cashier_id, p_customer_name, p_customer_phone, p_customer_email,
    v_subtotal, v_tax, v_discount, v_total, p_payment_method, 'completed',
    p_paid_amount, v_change_amount, p_notes
  ) RETURNING id INTO v_transaction_id;

  -- Create transaction items and update stock
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    SELECT price INTO v_product_price
    FROM products WHERE id = (v_item->>'product_id')::UUID;

    INSERT INTO transaction_items (
      transaction_id, product_id, product_name, total, quantity, unit_price, subtotal
    )
    SELECT
      v_transaction_id, (v_item->>'product_id')::UUID, p.name,
      v_product_price * (v_item->>'quantity')::INTEGER,
      (v_item->>'quantity')::INTEGER, v_product_price,
      v_product_price * (v_item->>'quantity')::INTEGER
    FROM products p WHERE p.id = (v_item->>'product_id')::UUID;

    UPDATE products
    SET stock = stock - (v_item->>'quantity')::INTEGER, updated_at = NOW()
    WHERE id = (v_item->>'product_id')::UUID;
  END LOOP;

  -- Return complete transaction with items
  SELECT jsonb_build_object(
    'transaction', row_to_json(t.*),
    'items', (
      SELECT jsonb_agg(row_to_json(ti.*))
      FROM transaction_items ti WHERE ti.transaction_id = v_transaction_id
    )
  ) INTO v_result
  FROM transactions t WHERE t.id = v_transaction_id;

  RETURN v_result;
END;
$$;

-- Helper functions for transactions
DROP FUNCTION IF EXISTS get_transaction_with_items CASCADE;
DROP FUNCTION IF EXISTS get_today_transactions CASCADE;
DROP FUNCTION IF EXISTS get_all_transactions CASCADE;
DROP FUNCTION IF EXISTS get_sales_summary CASCADE;

CREATE OR REPLACE FUNCTION get_transaction_with_items(p_transaction_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'transaction', row_to_json(t.*),
    'items', (
      SELECT jsonb_agg(row_to_json(ti.*))
      FROM transaction_items ti WHERE ti.transaction_id = p_transaction_id
    )
  ) INTO v_result FROM transactions t WHERE t.id = p_transaction_id;
  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION get_today_transactions()
RETURNS SETOF transactions LANGUAGE sql SECURITY DEFINER AS $$
  SELECT * FROM transactions
  WHERE DATE(created_at) = CURRENT_DATE
  ORDER BY created_at DESC;
$$;

CREATE OR REPLACE FUNCTION get_all_transactions(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS SETOF transactions LANGUAGE sql SECURITY DEFINER AS $$
  SELECT * FROM transactions
  ORDER BY created_at DESC
  LIMIT p_limit OFFSET p_offset;
$$;

CREATE OR REPLACE FUNCTION get_sales_summary(
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
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
      SELECT jsonb_object_agg(payment_method, jsonb_build_object('count', count, 'total', total))
      FROM (
        SELECT payment_method, COUNT(*) as count, SUM(total) as total
        FROM transactions
        WHERE created_at >= v_start_date AND created_at < v_end_date
        GROUP BY payment_method
      ) pm
    )
  ) INTO v_result
  FROM transactions
  WHERE created_at >= v_start_date AND created_at < v_end_date;

  RETURN v_result;
END;
$$;

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION process_checkout TO authenticated;
GRANT EXECUTE ON FUNCTION get_transaction_with_items TO authenticated;
GRANT EXECUTE ON FUNCTION get_today_transactions TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_transactions TO authenticated;
GRANT EXECUTE ON FUNCTION get_sales_summary TO authenticated;
```

---

#### Step 3: Enable Row Level Security

**What this does:**

- Enables Row Level Security (RLS) on all tables
- Sets up policies to control who can read/write data
- Requires authentication for creating/updating products and transactions
- Allows anyone to read products and categories

**SQL to run:**

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

-- RLS Policies for products (read for all, write for authenticated users)
DROP POLICY IF EXISTS "Anyone can read products" ON products;
CREATE POLICY "Anyone can read products" ON products
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert products" ON products;
CREATE POLICY "Authenticated users can insert products" ON products
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can update products" ON products;
CREATE POLICY "Authenticated users can update products" ON products
  FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can delete products" ON products;
CREATE POLICY "Authenticated users can delete products" ON products
  FOR DELETE USING (auth.role() = 'authenticated');

-- RLS Policies for categories
DROP POLICY IF EXISTS "Anyone can read categories" ON categories;
CREATE POLICY "Anyone can read categories" ON categories
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage categories" ON categories;
CREATE POLICY "Authenticated users can manage categories" ON categories
  FOR ALL USING (auth.role() = 'authenticated');

-- RLS Policies for transactions
DROP POLICY IF EXISTS "Authenticated users can read transactions" ON transactions;
CREATE POLICY "Authenticated users can read transactions" ON transactions
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can create transactions" ON transactions;
CREATE POLICY "Authenticated users can create transactions" ON transactions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for transaction_items
DROP POLICY IF EXISTS "Authenticated users can read transaction items" ON transaction_items;
CREATE POLICY "Authenticated users can read transaction items" ON transaction_items
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert transaction items" ON transaction_items;
CREATE POLICY "Authenticated users can insert transaction items" ON transaction_items
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

---

#### Step 4: Create Authentication User & Insert Sample Data

**What this does:**

- Creates your first user account for logging in
- Inserts the user into the `users` table
- Adds sample categories and products for testing

**Instructions:**

**A. Create User Account:**

1. Go to Supabase Dashboard → **Authentication** → **Users**
2. Click **"Add User"**
3. Fill in:
   - **Email**: `your@email.com`
   - **Password**: `your-secure-password` (min 6 characters)
4. Click **"Create User"**
5. **Copy the User ID** from the users list

**B. Insert User into Users Table:**

If you created the user **before** running Step 2, manually insert them with this SQL:

```sql
-- Replace 'YOUR_USER_ID' with the actual UUID from Authentication → Users
-- Replace 'your@email.com' with your actual email
INSERT INTO public.users (id, email, full_name, role)
VALUES (
  'YOUR_USER_ID'::uuid,
  'your@email.com',
  'Your Name',
  'cashier'
)
ON CONFLICT (id) DO NOTHING;
```

> **Note:** New users created **after** Step 2 will be automatically added to the `users` table by the trigger.

**C. Insert Sample Data:**

Run this SQL to add sample categories and products:

```sql
-- Insert sample categories
INSERT INTO categories (name, description, icon, color) VALUES
  ('Electronics', 'Electronic devices and accessories', '📱', '#6366F1'),
  ('Food & Beverage', 'Food and drink items', '🍔', '#10B981'),
  ('Clothing', 'Apparel and fashion items', '👕', '#F59E0B'),
  ('Home & Garden', 'Home improvement and garden supplies', '🏠', '#EF4444');

-- Insert sample products
INSERT INTO products (name, description, sku, price, stock, category_id) VALUES
  ('Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 'ELEC-001', 29.99, 50, (SELECT id FROM categories WHERE name = 'Electronics')),
  ('Mechanical Keyboard', 'RGB mechanical gaming keyboard', 'ELEC-002', 89.99, 25, (SELECT id FROM categories WHERE name = 'Electronics')),
  ('USB-C Cable', 'High-speed USB-C charging cable', 'ELEC-003', 12.99, 100, (SELECT id FROM categories WHERE name = 'Electronics')),
  ('Bluetooth Speaker', 'Portable waterproof speaker', 'ELEC-004', 45.99, 30, (SELECT id FROM categories WHERE name = 'Electronics'));
```

---

## 3. Configure Flutter App

### Get API Keys

**Instructions:**

1. Go to **Project Settings** → **API**
2. Copy these keys:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: For client-side use
   - **service_role key**: For server-side use (keep secret!)

### Setup Environment Variables

**Instructions:**

1. Create a `.env` file in your project root:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

2. Add `.env` to your `.gitignore` file (already done in this project)

3. Replace the values with your actual Supabase URL and anon key from Step 3

> **Note:** The Flutter app code already includes all necessary Supabase configuration, repositories, and providers. Check the `lib/` folder for implementation details.

---

## 4. Common Issues

### ❌ RLS blocking queries

**Solution:** Check your RLS policies or temporarily disable for testing

### ❌ CORS errors on web

**Solution:** Add your domain to allowed origins in Supabase dashboard

### ❌ Connection timeout

**Solution:** Check your internet connection and Supabase project status

### ❌ Authentication errors

**Solution:** Verify your API keys are correct and not expired

### ❌ RLS blocking inserts/updates

**Solution:** Make sure you've created a user account (Step 4) and logged in to the app. The app requires authentication to create/update products and transactions

### ❌ Foreign key constraint violation (cashier_id)

**Solution:** Your user exists in `auth.users` but not in `public.users`. Run the SQL in Step 4B to insert your user into the users table

---

## Next Steps

1. ✅ Set up authentication (sign up/login)
2. ✅ Implement offline-first with local cache
3. ✅ Add image upload to Supabase Storage
4. ✅ Set up realtime subscriptions
5. ✅ Implement transaction creation
6. ✅ Add analytics and reporting
7. ✅ Set up automated backups

---

## Useful Resources

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Flutter Package](https://pub.dev/packages/supabase_flutter)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
