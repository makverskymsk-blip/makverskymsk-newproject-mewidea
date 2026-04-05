import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/sport_match.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/game_card.dart';
import '../../widgets/glass_button.dart';
import '../community/event_manage_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDayIndex = 0;
  final List<DateTime> _days = List.generate(
    120, (i) => DateTime.now().add(Duration(days: i)),
  );

  @override
  Widget build(BuildContext context) {
    final matchesProv = context.watch<MatchesProvider>();
    final authProv = context.watch<AuthProvider>();
    final communityProv = context.watch<CommunityProvider>();
    final selectedDate = _days[_selectedDayIndex];
    final dayMatches = matchesProv.getByDate(selectedDate);

    return Stack(
      children: [
        Container(color: AppColors.of(context).scaffoldBg),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Расписание', style: Theme.of(context).textTheme.headlineMedium),
                    SizedBox(
                      width: 150,
                      child: GlassButton(
                        text: 'Создать',
                        icon: Icons.add_rounded,
                        onPressed: () => _showCreateDialog(context, matchesProv, communityProv),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDaySelector(selectedDate),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (dayMatches.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              Icon(Icons.event_available, size: 64, color: AppColors.borderLight),
                              SizedBox(height: 12),
                              Text(
                                'На этот день игр пока нет',
                                style: TextStyle(color: AppColors.textHint),
                              ),
                            ],
                          ),
                        )
                      else
                        ...dayMatches.map(
                          (match) {
                            final userId = authProv.uid ?? '';
                            final isSubscriber =
                                communityProv.hasSubscriptionForEventDate(
                                    userId, match.dateTime);
                            final effectivePrice =
                                isSubscriber ? 0.0 : match.price;
                            // Check registration from persisted registeredPlayerIds, not the local flag
                            final isRegistered = match.registeredPlayerIds.contains(userId);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GameCard(
                                format: '${match.category.displayName} • ${match.format}',
                                time: Helpers.formatTime(match.dateTime),
                                date: Helpers.getRelativeDate(match.dateTime),
                                location: match.location,
                                price: isSubscriber
                                    ? 'Абонемент ✓'
                                    : Helpers.formatCurrency(match.price),
                                currentPlayers: match.registeredPlayerIds.length,
                                totalCapacity: match.totalCapacity,
                                isUserRegistered: isRegistered,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventManageScreen(matchId: match.id),
                                  ),
                                ),
                                onParticipate: () {
                                  final wasRegistered = match.registeredPlayerIds.contains(userId);
                                  matchesProv.toggleRegistration(match,
                                      userId: authProv.uid,
                                      userName: authProv.currentUser?.name);
                                  if (!wasRegistered) {
                                    // Just registered → charge
                                    authProv.updateBalance(-effectivePrice);
                                  } else {
                                    // Just unregistered → refund
                                    authProv.updateBalance(effectivePrice);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.sports_soccer, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'SPORTS CLUB',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(DateTime selectedDate) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedDayIndex == index;
          DateTime day = _days[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Helpers.formatDayOfWeek(day),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, MatchesProvider matchesProv, CommunityProvider communityProv) {
    final locationCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '20');
    SportCategory selectedCat = SportCategory.football;
    DateTime? selectedDT;
    String selectedFormat = '5x5';
    final formats = ['1x1', '2x2', '3x3', '4x4', '5x5', '6x6', '7x7', '8x8', '9x9', '10x10', '11x11'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.of(context).dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: AppColors.borderLight),
            ),
            title: const Text('Создать событие', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<SportCategory>(
                    dropdownColor: Colors.white,
                    initialValue: selectedCat,
                    decoration: const InputDecoration(labelText: 'Категория'),
                    items: SportCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedCat = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Format selector
                  const Text('Формат игры',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: formats.map((f) {
                      final isSelected = selectedFormat == f;
                      return GestureDetector(
                        onTap: () => setDialogState(() {
                          selectedFormat = f;
                          // Авто-рассчитываем вместимость
                          final perTeam = int.tryParse(f.split('x').first) ?? 5;
                          capacityCtrl.text = '${perTeam * 2 + (perTeam ~/ 2)}';
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.borderLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderLight,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (_, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null && ctx.mounted) {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.now(),
                          builder: (_, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: AppColors.primary),
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(ctx).copyWith(
                                alwaysUse24HourFormat: true,
                              ),
                              child: child!,
                            ),
                          ),
                        );
                        if (time != null) {
                          setDialogState(() {
                            selectedDT = DateTime(
                              date.year, date.month, date.day,
                              time.hour, time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            selectedDT == null
                                ? 'Выберите дату и время'
                                : Helpers.formatDateTime(selectedDT!),
                            style: TextStyle(
                              color: selectedDT == null ? AppColors.textHint : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(labelText: 'Локация'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Цена (₽)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Мест'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (selectedDT == null) return;
                  await matchesProv.addMatch(SportMatch(
                    id: '', // UUID will be generated by Supabase
                    communityId: communityProv.activeCommunity?.id,
                    category: selectedCat,
                    format: selectedFormat,
                    dateTime: selectedDT!,
                    location: locationCtrl.text.isEmpty ? 'Не указано' : locationCtrl.text,
                    price: double.tryParse(priceCtrl.text) ?? 500,
                    totalCapacity: int.tryParse(capacityCtrl.text) ?? 20,
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Создать', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    ),
    );
  }
}
