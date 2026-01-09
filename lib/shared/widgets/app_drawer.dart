import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Modern, minimalist navigation drawer
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.store_outlined, size: 28, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Avatar POS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Point of Sale System',
                    style: TextStyle(fontSize: 14, color: AppTheme.neutralDark),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    onTap: () {
                      context.go(AppRouter.home);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2,
                    label: 'Products',
                    onTap: () {
                      context.push(AppRouter.products);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag,
                    label: 'Cart',
                    onTap: () {
                      context.push(AppRouter.cart);
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'OTHER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutralDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      context.push(AppRouter.settings);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.neutralLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline, size: 20, color: AppTheme.neutralDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guest User',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Not signed in',
                          style: TextStyle(fontSize: 12, color: AppTheme.neutralDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern drawer item widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
