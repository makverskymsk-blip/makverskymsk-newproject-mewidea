import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// In‑app Privacy Policy screen — scrollable text.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Политика конфиденциальности',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _heading('Политика конфиденциальности'),
          _date('Дата вступления в силу: 23 апреля 2026 г.'),
          _paragraph(
            'Настоящая Политика конфиденциальности описывает порядок сбора, '
            'использования и защиты персональных данных пользователей приложения '
            'и веб-сервиса Performance Lab (далее — «Сервис»).',
          ),
          _section('1. Оператор данных'),
          _paragraph(
            'Оператором персональных данных является администратор сервиса '
            'Performance Lab.\n'
            'Контактный email: Makversky@yandex.ru',
          ),
          _section('2. Какие данные мы собираем'),
          _paragraph(
            'При использовании Сервиса мы можем обрабатывать следующие данные:',
          ),
          _bullet('Адрес электронной почты (email) — для регистрации, '
              'аутентификации и восстановления доступа.'),
          _bullet('Пароль — хранится исключительно в зашифрованном '
              '(хэшированном) виде.'),
          _bullet('Имя пользователя — отображается другим участникам '
              'сообщества.'),
          _bullet('Данные об участии в мероприятиях — посещение событий, '
              'результаты матчей, игровая статистика.'),
          _bullet('Финансовые записи — суммы абонементов и платежей внутри '
              'сообщества (без привязки к банковским картам).'),
          _section('3. Цели сбора данных'),
          _paragraph(
            'Персональные данные обрабатываются исключительно для:',
          ),
          _bullet('Регистрации и аутентификации пользователя в Сервисе.'),
          _bullet('Управления спортивными сообществами: учёт явки на '
              'тренировки и матчи.'),
          _bullet('Ведения спортивной статистики участников.'),
          _bullet('Расчёта абонементских взносов и внутренних финансовых '
              'операций сообщества.'),
          _bullet('Отправки служебных уведомлений (подтверждение email, '
              'сброс пароля).'),
          _section('4. Передача данных третьим лицам'),
          _paragraph(
            'Мы не продаём, не передаём и не предоставляем персональные данные '
            'пользователей рекламным сетям, аналитическим платформам или иным '
            'третьим лицам в коммерческих целях.\n\n'
            'Для хранения данных используется облачная платформа Supabase '
            '(серверы ЕС/США). Supabase действует как обработчик данных в '
            'соответствии со своей политикой конфиденциальности.',
          ),
          _section('5. Защита данных'),
          _paragraph('Мы применяем следующие меры для защиты ваших данных:'),
          _bullet('Все соединения защищены протоколом HTTPS/TLS.'),
          _bullet('Пароли хранятся в виде криптографических хэшей (bcrypt).'),
          _bullet('Доступ к базе данных ограничен политиками безопасности '
              'на уровне строк (Row Level Security).'),
          _bullet('API-ключи и секреты не хранятся в клиентском коде.'),
          _section('6. Хранение данных'),
          _paragraph(
            'Персональные данные хранятся в течение всего срока существования '
            'аккаунта пользователя. При удалении аккаунта данные удаляются '
            'в течение 30 дней.',
          ),
          _section('7. Права пользователя'),
          _paragraph('Вы имеете право:'),
          _bullet('Получить информацию о своих персональных данных.'),
          _bullet('Исправить неточные данные через настройки профиля.'),
          _bullet('Удалить аккаунт и все связанные данные — через настройки '
              'приложения или написав на Makversky@yandex.ru.'),
          _bullet('Отозвать согласие на обработку данных — для этого '
              'удалите аккаунт.'),
          _section('8. Файлы cookie'),
          _paragraph(
            'Веб-версия Сервиса может использовать технические cookie-файлы, '
            'необходимые для аутентификации. Рекламные и аналитические cookie '
            'не используются.',
          ),
          _section('9. Изменение Политики'),
          _paragraph(
            'Мы оставляем за собой право обновлять данную Политику. Актуальная '
            'версия всегда доступна на сайте yourperformancelab.ru/privacy.html. '
            'При существенных изменениях пользователи будут уведомлены через '
            'приложение.',
          ),
          _section('10. Контакты'),
          _paragraph(
            'По всем вопросам, связанным с обработкой персональных данных:\n'
            'Makversky@yandex.ru',
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2026 Performance Lab',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────

  static Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );

  static Widget _date(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );

  static Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  static Widget _paragraph(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      );

  static Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Icon(Icons.circle, size: 5, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
}
