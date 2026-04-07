import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: t.navBarBg,
        border: Border(
          top: BorderSide(color: t.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: t.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: t.textHint,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            currentIndex: currentIndex,
            onTap: onTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Главная',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                label: 'Игры',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_rounded),
                label: 'Тренировка',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Профиль',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
