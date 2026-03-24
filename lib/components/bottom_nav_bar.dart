import 'package:flutter/material.dart';
import '../../pages/collections_page.dart';
import '../../pages/add_item_page.dart';
import '../../pages/search_page.dart';
import '../../pages/profile_page.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    this.isDark = false,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const CollectionsPage();
        break;
      case 1:
        page = const AddItemPage();
        break;
      case 2:
        page = const SearchPage();
        break;
      case 3:
        page = const ProfilePage();
        break;
      default:
        page = const CollectionsPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? const Color(0xFF3A5A53)
        : const Color(0xFFA8BDB1);
    final borderColor = isDark
        ? const Color(0xFF2D4740)
        : const Color(0xFF95AB9F);
    final activeColor = isDark ? Colors.white : const Color(0xFF2D3D35);
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.6)
        : const Color(0xFF5A6D60);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.grid_view_rounded,
                label: 'Collections',
                isSelected: selectedIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _onItemTapped(context, 0),
              ),
              _NavBarItem(
                icon: Icons.add,
                label: 'Add Item',
                isSelected: selectedIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _onItemTapped(context, 1),
              ),
              _NavBarItem(
                icon: Icons.search,
                label: 'Search',
                isSelected: selectedIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _onItemTapped(context, 2),
              ),
              _NavBarItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: selectedIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _onItemTapped(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
