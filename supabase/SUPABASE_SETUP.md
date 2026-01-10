# Supabase Setup Guide - Avatar POS

## Quick Start Guide

### 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Project Name**: avatar-pos
   - **Database Password**: (save this securely!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Free tier is fine for development

### 2. Run Database Migrations

Go to **SQL Editor** in your Supabase dashboard and run these scripts in order:

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

#### Step 2: Create Functions and Triggers

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
```

#### Step 3: Enable Row Level Security

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

#### Step 4: Create Authentication User & Insert Sample Data

**First, create a user account for authentication:**

1. Go to Supabase Dashboard → **Authentication** → **Users**
2. Click **Add User**
3. Fill in:
   - **Email**: your@email.com
   - **Password**: your-secure-password (min 6 characters)
4. Click **Create User**
5. **Copy the User ID** from the users list (you'll need it for the next step)

**Important: Insert the user into the users table:**

If you created the user **before** adding the trigger in Step 2, you need to manually insert them:

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

**Note:** New users created after Step 2 will be automatically added to the users table by the trigger.

**Then, insert sample data:**

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

### 3. Get API Keys

1. Go to **Project Settings** → **API**
2. Copy these keys:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: For client-side use
   - **service_role key**: For server-side use (keep secret!)

### 4. Install Flutter Package

Add to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

Run:

```bash
flutter pub get
```

### 5. Initialize Supabase in Flutter

Create `lib/core/config/supabase_config.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
}

// Global accessor
final supabase = Supabase.instance.client;
```

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Avatar POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 6. Create Repository Layer

Create `lib/features/products/repositories/product_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../home/models/product.dart';

class ProductRepository {
  final SupabaseClient _supabase = supabase;

  // Fetch all products
  Future<List<Product>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, categories(name)')
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Fetch single product
  Future<Product?> getProduct(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, categories(name)')
          .eq('id', id)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create product
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _supabase
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  Future<Product> updateProduct(String id, Product product) async {
    try {
      final response = await _supabase
          .from('products')
          .update(product.toJson())
          .eq('id', id)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String id) async {
    try {
      await _supabase
          .from('products')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, categories(name)')
          .or('name.ilike.%$query%,sku.ilike.%$query%,barcode.ilike.%$query%')
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, categories(name)')
          .lte('stock', 'min_stock')
          .eq('is_active', true)
          .order('stock');

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock products: $e');
    }
  }

  // Listen to product changes (realtime)
  Stream<List<Product>> watchProducts() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('name')
        .map((data) => data.map((json) => Product.fromJson(json)).toList());
  }
}
```

### 7. Update Product Provider

Update `lib/features/home/providers/products_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/product.dart';
import '../../products/repositories/product_repository.dart';

part 'products_provider.g.dart';

@riverpod
class Products extends _$Products {
  late final ProductRepository _repository;

  @override
  Future<List<Product>> build() async {
    _repository = ProductRepository();
    return await _repository.getProducts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getProducts());
  }

  Future<void> searchProducts(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.searchProducts(query));
  }
}
```

### 8. Environment Variables (Recommended)

Create `.env` file:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

Add to `.gitignore`:

```
.env
```

Install `flutter_dotenv`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

Load in `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## Testing the Setup

### Test in Supabase Dashboard

1. Go to **Table Editor**
2. View your tables and sample data
3. Try inserting/updating records manually

### Test in Flutter App

```dart
// Test connection
void testSupabaseConnection() async {
  try {
    final products = await supabase.from('products').select();
    debugPrint('Connected! Found ${products.length} products');
  } catch (e) {
    debugPrint('Connection failed: $e');
  }
}
```

---

## Common Issues & Solutions

### Issue: RLS blocking queries

**Solution**: Check your RLS policies or temporarily disable for testing

### Issue: CORS errors on web

**Solution**: Add your domain to allowed origins in Supabase dashboard

### Issue: Connection timeout

**Solution**: Check your internet connection and Supabase project status

### Issue: Authentication errors

**Solution**: Verify your API keys are correct and not expired

### Issue: RLS blocking inserts/updates

**Solution**: Make sure you've created a user account (Step 4) and logged in to the app. The app requires authentication to create/update products and transactions

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
