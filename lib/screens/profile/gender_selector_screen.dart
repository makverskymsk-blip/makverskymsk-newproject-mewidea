import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

/// Gender selection screen accessible from profile settings.
class GenderSelectorScreen extends StatelessWidget {
  const GenderSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final currentGender = user?.gender;
    final t = AppColors.of(context);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Выбор пола',
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Пол влияет на расчёт калорий\nи подбор тренировок',
                style: TextStyle(
                  color: t.textHint,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _GenderCard(
                      icon: Icons.male_rounded,
                      label: 'Мужской',
                      genderKey: 'male',
                      isSelected: currentGender == 'male',
                      color: const Color(0xFF4A90D9),
                      onTap: () => _selectGender(context, 'male'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _GenderCard(
                      icon: Icons.female_rounded,
                      label: 'Женский',
                      genderKey: 'female',
                      isSelected: currentGender == 'female',
                      color: const Color(0xFFE91E8C),
                      onTap: () => _selectGender(context, 'female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Height, Weight, Age inputs
              _buildMetricField(
                context,
                label: 'Рост (см)',
                icon: Icons.height_rounded,
                initialValue: user?.heightCm?.toString() ?? '',
                onSaved: (val) {
                  final v = int.tryParse(val);
                  if (v != null && v > 0) {
                    auth.updateUserField('height_cm', v);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMetricField(
                context,
                label: 'Вес (кг)',
                icon: Icons.monitor_weight_outlined,
                initialValue: user?.weightKg?.toStringAsFixed(1) ?? '',
                isDecimal: true,
                onSaved: (val) {
                  final v = double.tryParse(val.replaceAll(',', '.'));
                  if (v != null && v > 0) {
                    auth.updateUserField('weight_kg', v);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMetricField(
                context,
                label: 'Возраст',
                icon: Icons.cake_outlined,
                initialValue: user?.age?.toString() ?? '',
                onSaved: (val) {
                  final v = int.tryParse(val);
                  if (v != null && v > 0) {
                    auth.updateUserField('age', v);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectGender(BuildContext context, String gender) {
    final auth = context.read<AuthProvider>();
    auth.updateUserField('gender', gender);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(gender == 'male' ? '♂ Мужской выбран' : '♀ Женский выбран'),
        backgroundColor: gender == 'male'
            ? const Color(0xFF4A90D9)
            : const Color(0xFFE91E8C),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildMetricField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String initialValue,
    required ValueChanged<String> onSaved,
    bool isDecimal = false,
  }) {
    final t = AppColors.of(context);
    final controller = TextEditingController(text: initialValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderLight.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: t.isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: t.textHint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
              style: TextStyle(color: t.textPrimary),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: t.textHint, fontSize: 13),
                border: InputBorder.none,
              ),
              onSubmitted: onSaved,
            ),
          ),
          GestureDetector(
            onTap: () => onSaved(controller.text),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String genderKey;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.genderKey,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : t.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : t.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: t.isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : t.surfaceBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.4)
                      : t.borderLight,
                ),
              ),
              child: Icon(
                icon,
                size: 36,
                color: isSelected ? color : t.textHint,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 15,
                color: isSelected ? color : t.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Icon(Icons.check_circle_rounded, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
