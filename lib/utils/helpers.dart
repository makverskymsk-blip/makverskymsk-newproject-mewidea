class Helpers {
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }

  static String formatCurrency(double amount) {
    final isNegative = amount < 0;
    final abs = amount.abs().toInt();
    final str = abs.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '${isNegative ? '−' : ''}$str ₽';
  }

  static String formatDayOfWeek(DateTime date) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[date.weekday - 1];
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Завтра';
    if (diff < 7) return 'Через $diff дн.';
    return formatDate(date);
  }

  static int daysUntilSubscriptionDeadline() {
    final now = DateTime.now();
    if (now.day >= 25) return 0;
    return 25 - now.day;
  }
}
