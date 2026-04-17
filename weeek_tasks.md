# Performance Lab — Задачи для Weeek

## ✅ Выполнено

### UI / Дизайн
- [x] Dark/Light тема — полная поддержка всех экранов
- [x] Ghost UI система — pill-shape радиусы, стеклянные карточки
- [x] PLLogo — CustomPainter логотип с бейджами спорта
- [x] Пульсирующая анимация splash screen
- [x] Иконка приложения (Android, iOS, Web)
- [x] Бейдж «В разработке» на модуле Тренировок
- [x] Уведомления (in-app notification system)
- [x] FIFA-стиль карточка игрока с цветными tier

### Backend / Supabase
- [x] Realtime подписки (communities, users, matches)
- [x] Команды/матчи в БД через JSONB
- [x] RLS: members могут создавать события
- [x] Аватарки — загрузка в Storage + RLS
- [x] Автоочистка старых сообщений (>5 дней)
- [x] Очистка DM чатов

### Тренировки (Sprint 1 + Sprint 2)
- [x] Навигация — вкладка «Тренировка» в BottomNav
- [x] TrainingProvider — XP, левелинг, аналитика
- [x] ActiveWorkoutScreen — таймер, подходы, XP-диалог
- [x] ExerciseLibraryScreen — фильтр по мышцам
- [x] TrainingAnalyticsTab — 4 графика (fl_chart)

### Инфраструктура
- [x] Web деплой — GitHub Pages + yourperformancelab.ru
- [x] SSL/HTTPS сертификат
- [x] Open Graph мета-теги (Telegram/WhatsApp превью)
- [x] Скрипт деплоя (deploy.ps1)
- [x] Git — контроль версий

---

## 📋 В работе / Не завершено

### UI
- [ ] Показать аватарки в списке участников (members_screen)
- [ ] Показать аватарки в списке игроков события (event_manage_screen)
- [ ] Persistence темы — сохранять выбор в shared_preferences

### Backend
- [ ] Уведомления при входе нового участника
- [ ] Pull-to-refresh как fallback для Realtime
- [ ] RLS аудит — 42501 ошибки при создании пользователей
- [ ] Auth — Invalid Refresh Token на Web

### Code Quality
- [ ] Linting warnings — use_build_context_synchronously
- [ ] Протестировать аватарки на Android

---

## 🔮 Бэклог (Sprint 3+)

### Тренировки
- [ ] AI Lab — конструктор тренировок на Gemini
- [ ] Body Heatmap — тепловая карта нагрузки мышц (силуэт)
- [ ] Athlete Card — карточка в профиле при выборе «Тренировка»
- [ ] Radar Chart для тренировок (сила/выносливость/объём/частота)

### Возможные фичи
- [ ] Push-уведомления (Firebase Cloud Messaging)
- [ ] Публикация в Google Play / App Store
- [ ] Локализация (EN/RU)
- [ ] Онбординг для новых пользователей
