# Проект: new_idea_works — Спортивное сообщество

## Общее описание

Flutter-приложение для управления спортивными сообществами. Позволяет игрокам создавать и вступать в сообщества, организовывать матчи, вести финансовый учёт (абонементы, баланс, компенсации), а также отслеживать статистику и рейтинг игроков.

**GitHub**: `https://github.com/makverskymsk-blip/makverskymsk-newproject-mewidea.git`
**Ветка**: `main`

---

## Технический стек

| Компонент | Технология |
|-----------|-----------|
| Фреймворк | Flutter (Dart) |
| Backend / БД | Supabase (PostgreSQL) |
| State management | Provider |
| Платформы | Web, Android, iOS |
| Деплой Web | GitHub Pages (`/docs`) |

---

## Структура проекта

```
lib/
├── app.dart                      # MaterialApp, роутинг, ThemeProvider
├── main.dart / main_dev.dart / main_prod.dart  # Entry points
├── config/
│   ├── app_config.dart           # Supabase URL/Key (dev/prod)
│   └── env_banner.dart           # DEV/PROD баннер
├── models/
│   ├── community.dart            # Модель сообщества
│   ├── sport_match.dart          # Модель матча
│   ├── subscription.dart         # Абонемент (Monthly)
│   ├── user_profile.dart         # Профиль пользователя
│   ├── match_stats.dart          # Статистика матча
│   ├── transaction.dart          # Финансовые транзакции
│   ├── achievement.dart          # Достижения
│   └── enums.dart                # SportCategory, MemberRole, etc.
├── providers/
│   ├── auth_provider.dart        # Аутентификация через Supabase Auth
│   ├── community_provider.dart   # CRUD сообществ, подписки, банк
│   ├── matches_provider.dart     # Матчи, команды, результаты
│   ├── wallet_provider.dart      # Баланс, транзакции
│   ├── stats_provider.dart       # Статистика игрока, достижения
│   └── theme_provider.dart       # Переключение Light/Dark темы
├── screens/
│   ├── auth/login_screen.dart    # Авторизация (email/password)
│   ├── splash_screen.dart        # Splash при загрузке
│   ├── main_navigation.dart      # BottomNavBar (4 вкладки)
│   ├── home/home_screen.dart     # Главная: ближайшие матчи, статистика
│   ├── schedule/schedule_screen.dart  # Расписание матчей
│   ├── wallet/wallet_screen.dart # Кошелёк: баланс, транзакции
│   ├── profile/profile_screen.dart # Профиль: карточка, меню, настройки
│   ├── stats/player_stats_screen.dart # Подробная статистика
│   └── community/
│       ├── community_hub_screen.dart    # Экран без сообщества (создать/вступить)
│       ├── community_manage_screen.dart # Мои сообщества, навигация
│       ├── members_screen.dart          # Участники + вкладка "Оплата"
│       ├── event_manage_screen.dart     # Управление событием (матчем)
│       ├── subscription_screen.dart     # Абонемент (месячный)
│       └── rate_players_screen.dart     # Оценка игроков после матча
├── services/
│   ├── supabase_service.dart     # Все RPC вызовы к Supabase
│   └── notification_service.dart # Уведомления (placeholder)
├── theme/
│   ├── app_colors.dart           # AppColors + AppThemeColors (Light/Dark)
│   └── app_theme.dart            # ThemeData для light/dark
├── widgets/
│   ├── bottom_nav_bar.dart       # Навигационная панель
│   ├── glass_card.dart           # Стеклянная карточка
│   ├── glass_button.dart         # Кнопка (outlined/filled)
│   ├── game_card.dart            # Карточка матча
│   ├── player_fifa_card.dart     # FIFA-стиль карточка игрока
│   ├── radar_chart.dart          # Радарная диаграмма навыков
│   └── achievement_badge.dart    # Бейдж достижения
└── utils/helpers.dart            # Форматирование валюты, дат
```

---

## База данных (Supabase)

### Основные таблицы
- `profiles` — пользователи (name, email, position, balance, community_ids[])
- `communities` — сообщества (name, sport, invite_code, owner_id, bank_balance)
- `matches` — матчи (community_id, date, status, format, teams, scores)
- `match_stats` — статистика по матчу (player_id, goals, assists, rating)
- `monthly_subscriptions` — абонементы (month, year, total_rent, subscribers[], compensation)
- `transactions` — финансовые операции (amount, type, description)
- `player_stats` — агрегированная статистика игрока (games, wins, avg_rating, atk, def, pas, spd, skl)
- `achievements` — достижения игрока

### RPC функции
- `join_community_by_code(code, user_id)` — вступление по коду
- `leave_community(community_id, user_id)` — выход
- `apply_compensation(...)` — применение компенсации из банка
- `calculate_subscription(...)` — расчёт абонемента

---

## Система тем (Light / Dark)

### Архитектура
1. **ThemeProvider** (`lib/providers/theme_provider.dart`) — хранит `ThemeMode`, метод `toggle()`
2. **AppTheme** (`lib/theme/app_theme.dart`) — `lightTheme` и `darkTheme` (ThemeData)
3. **AppColors** (`lib/theme/app_colors.dart`):
   - Статические цвета: `primary`, `accent`, `error`, `success`, `warning`
   - Тема-зависимые: `AppColors.of(context)` возвращает `AppThemeColors` с полями:
     - `scaffoldBg`, `cardBg`, `dialogBg`, `surfaceBg`
     - `textPrimary`, `textSecondary`, `textHint`
     - `borderLight`, `shadowColor`
     - `chipBg`

### Правило
> **НИКОГДА** не использовать `Colors.white`, `Colors.black`, `AppColors.textPrimary` (статический) в UI.
> Всегда `AppColors.of(context).textPrimary` и т.д.

### Переключатель
- В **Профиле** → Switch "Тёмная тема / Светлая тема"

---

## Работа 5 апреля 2026

### Коммит 1: `feat: dark theme support across all screens, dialogs, tabs; tier-colored player card stats`

#### Что реализовано:
1. **ThemeProvider** — создан провайдер с `toggle()` и `isDark`
2. **AppTheme** — определены `lightTheme` и `darkTheme`
3. **AppColors** — рефакторинг на `AppColors.of(context)` паттерн
4. **Все экраны** — Scaffold backgrounds → `t.scaffoldBg`
5. **20+ диалогов** — `backgroundColor: t.dialogBg`
6. **TabBar** (event_manage, members) — видимые вкладки в тёмной теме
7. **PlayerFifaCard** — цифры в цвет лиги (бронза/серебро/золото)
8. **GlassCard, GlassButton, GameCard** — тема-зависимые
9. **BottomNavBar** — адаптивный
10. **Switch в профиле** — переключатель темы

### Коммит 2: `fix: dark theme for dialogs, inputs, community tiles, subscription stats`

#### Что исправлено:
1. **Карточка участника (members_screen)**:
   - Зелёный highlight для оплаченных (bg: rgba(34,197,94,0.08), border: rgba(34,197,94,0.2))
   - Бейдж: «Активен» (зелёный) вместо «Абонемент»
   - Тени: `0 4px 12px rgba(0,0,0,0.05)`
   - Тема-зависимый popup menu

2. **FIFA-карточка игрока (player_fifa_card)**:
   - Glow для Gold: золотой, opacity 0.2, blur 20
   - Glow для Legendary: фиолетовый, opacity 0.2, blur 20
   - Базовая тень: `0 4px 12px rgba(0,0,0,0.05)`

3. **Профиль (profile_screen)**:
   - Убрана кнопка «Полная статистика»
   - Добавлены: «Создать сообщество», «Вступить по коду» (всегда видны)
   - Имя и ID в заголовке → тема-зависимые
   - `_dialogField` → тема-зависимые цвета
   - Dropdown «Вид спорта» → `dropdownColor: dialogBg`

4. **Вкладка Оплата (members_screen, debt tile)**:
   - Имя игрока → `AppColors.of(context).textPrimary`

5. **Компенсация из банка (subscription_screen)**:
   - Bottom sheet → тёмный фон (`dialogBg`)
   - Input сумма → `textPrimary` (видна в обеих темах)
   - Quick amount chips → тема-зависимые
   - Preview container → тема-зависимый
   - `_previewRow` → тема-зависимые label/value
   - `_statItem` (Записалось, Аренда, ~Оценка) → тема-зависимые

6. **Мои сообщества (community_manage_screen)**:
   - Карточка сообщества → `cardBg` + тень (вместо серого)
   - Иконки, подписи → тема-зависимые

---

## Работа 6 апреля 2026

### Утро: Статистика матчей и километраж игроков

1. **match_player_stats** — таблица для хранения индивидуальных статистик по матчу
2. **match_events** — таблица для голов, ассистов, карточек в реальном времени
3. **StatsProvider** — провайдер для загрузки/расчёта рейтинга и общей статистики
4. **MatchEventsProvider** — провайдер для событий внутри матча (голы, ассисты)
5. **player_stats_screen** — экран подробной статистики игрока
6. **rate_players_screen** — экран оценки игроков после матча
7. **match_live_screen** — экран лайв-матча с событиями
8. **radar_chart** — виджет радарной диаграммы навыков (ATK, DEF, PAS, SPD, SKL)

### Вечер: Realtime, синхронизация команд, аватарки

#### Коммит: `feat: Realtime sync, teams/matches JSONB persistence, avatar upload, RLS fix v1.1.0`

#### 1. Supabase Realtime — автообновление данных
- **watchCommunityChannel()** — слушает изменения конкретного сообщества (member_ids, bank_balance и др.)
- **watchUserChannel()** — слушает изменения профиля пользователя (баланс, community_ids)
- **CommunityProvider** — при загрузке/переключении сообщества автоподписка на Realtime, `_refreshActiveCommunity()` перечитывает данные
- **AuthProvider** — после логина подписка на изменения профиля, `_refreshUserProfile()` обновляет баланс/community_ids. При logout — отписка
- **Supabase Publications** — добавлены таблицы: `communities`, `users`, `match_player_stats`, `match_events`, `transactions`

> Что уже было: `matches` и `subscriptions` уже имели Realtime через `watchMatchesChannel` и `watchSubscriptionsChannel`

#### 2. Сохранение команд и матчей в БД (JSONB)
**Проблема**: eventTeams и innerMatches хранились только в памяти → другие пользователи не видели команды/счёт

**Решение**:
- SQL: `ALTER TABLE matches ADD COLUMN event_teams JSONB DEFAULT '[]'` + `inner_matches JSONB DEFAULT '[]'`
- **EventTeam.toJson()/fromJson()** — сериализация команд
- **InnerMatch.toJson()/fromJson()** — сериализация матчей
- **SupabaseService**: `_parseEventTeams()`, `_parseInnerMatches()` — парсинг из JSONB
- **MatchesProvider**: `_syncEventTeams()`, `_syncInnerMatches()` — автосохранение при любом изменении (addTeam, assignPlayer, updateScore и т.д.)

#### 3. RLS-фикс — обычные игроки могут создавать события
**Проблема**: Только owner/admin могли INSERT в `matches`. События от обычных members были невидимы

**Решение**: Заменена политика `matches_insert_admin` → `matches_insert_member` с добавлением `member_ids` в проверку

#### 4. Загрузка аватарок
- **Supabase Storage**: создан bucket `avatars` (Public) + RLS-политики
- **SupabaseService.uploadAvatar()** — загрузка в Storage, возврат publicUrl с cache buster
- **ProfileScreen** — аватар кликабельный с иконкой камеры, bottom sheet (камера/галерея), загрузка + отображение
- **Зависимость**: `image_picker` добавлен в pubspec.yaml

#### 5. Версионирование
- Версия обновлена: `1.0.0+1` → `1.1.0+2`
- **Правило**: перед каждой сборкой APK увеличивать `+N` (versionCode) в pubspec.yaml

---

## Известные задачи (TODO)

### Готово ✅
- [x] Dark/Light тема
- [x] Realtime для communities и users
- [x] Команды/матчи сохраняются в БД (JSONB)
- [x] RLS: members могут создавать события
- [x] Аватарки — код + Storage bucket + RLS

### В работе
- [ ] Протестировать аватарки на Android
- [ ] Показать аватарки в списке участников сообщества (members_screen)
- [ ] Показать аватарки в списке игроков события (event_manage_screen)
- [ ] Уведомления при входе нового участника
- [ ] Pull-to-refresh как fallback для Realtime
- [ ] **Persistence темы** — сохранять в shared_preferences
- [ ] **Web deploy** — обновить `flutter build web` → `/docs`
- [ ] **Linting warnings** — `use_build_context_synchronously`

---

## Работа 7-8 апреля 2026 — Модуль «Тренировка» (Sprint 1 + Sprint 2)

### Sprint 1: Навигация + Каркас (завершён ✅)

#### Навигация
- **BottomNavBar** — убрана вкладка «Кошелёк», на её месте «Тренировка» (`Icons.fitness_center_rounded`)
- **MainNavigation** — `WalletScreen` → `TrainingHubScreen`
- **Профиль** — sport selector теперь включает «Тренировка» (5-я кнопка)
- **Профиль** → Меню: добавлены «Кошелёк» и «Физические данные»

#### Модели
- `user_profile.dart` — новые поля: `gender`, `heightCm`, `weightKg`, `age`, `trainingXp`, `trainingLevel`
- XP-система: `xpForNextLevel = 500 × L^1.5`, ранги: Новичок → Любитель → Продвинутый → Ветеран → Элита → Легенда
- `enums.dart` — Gender, TrainingGoal, MuscleGroup

#### Инфраструктура
- `auth_provider.dart` — `updateUserField()` для сохранения пола/роста/веса/возраста
- `supabase_service.dart` — createUser/getUser/updateUser включают training-поля
- `main.dart` — `TrainingProvider` зарегистрирован в MultiProvider

#### SQL Миграция (выполнена в Supabase)
- Файл: `supabase/training_schema.sql`
- Sprint 1: 6 новых колонок в `users`
- Sprint 2: 6 новых таблиц + индексы + RLS

### Sprint 2: Логика тренировок (завершён ✅)

#### Новые файлы
| Файл | Назначение |
|------|-----------|
| `lib/models/exercise.dart` | Модель упражнения (Exercise) |
| `lib/models/workout_session.dart` | Модель сессии (WorkoutSession) + подхода (WorkoutSet) |
| `lib/screens/training/active_workout_screen.dart` | Экран активной тренировки |
| `lib/screens/training/exercise_library_screen.dart` | Библиотека упражнений |
| `lib/screens/training/training_analytics_tab.dart` | Аналитика с 4 графиками |

#### TrainingProvider (полная логика)
- **init()** — загрузка упражнений + история сессий
- **userId getter** — автоматически берёт из Supabase Auth если init() не вызвался
- **Упражнения**: add/remove/filterByMuscle
- **Тренировки**: startWorkout → addSet → finishWorkout / cancelWorkout
- **XP**: base (10/подход) + duration (1/мин) + tonnage (1/100кг) × consistency multiplier
- **Левелинг**: while-loop level-up, persist в Supabase
- **Аналитика**: tonnageHistory, sessionsPerWeekday, muscleGroupDistribution, xpHistory, avgDuration, avgTonnage, bestSession, currentStreak

#### SupabaseService — новые методы
- Exercises: `getExercises`, `createExercise`, `updateExercise`, `deleteExercise`
- Sessions: `createWorkoutSession`, `getWorkoutSessions`, `updateWorkoutSession`
- Sets: `createWorkoutSet`, `getWorkoutSets`, `updateWorkoutSet`, `deleteWorkoutSet`
- User: `updateTrainingXpAndLevel`

#### Экраны
- **TrainingHubScreen** — Dashboard (XP-карточка, 4 stat-карточки, библиотека, баннер активной тренировки), Журнал, Аналитика
- **ActiveWorkoutScreen** — running stats bar, exercise picker (bottom sheet), weight/reps ввод, swipe-to-delete, finish с XP-диалогом
- **ExerciseLibraryScreen** — горизонтальный фильтр по мышцам, add dialog, swipe-to-delete
- **TrainingAnalyticsTab** — 4 графика (fl_chart): линейный тоннаж (даты DD/MM/YY), столбчатый по дням недели, pie мышечных групп, линейный XP + карточка лучшей тренировки

### Баги / Решения
- **_userId null** — решено через getter с fallback на `Supabase.instance.client.auth.currentUser?.id`
- **app.dart init** — TrainingProvider.init() вызывается и при наличии community, и без

### Следующий спринт (Sprint 3)
- [ ] AI Lab — конструктор тренировок на Gemini
- [ ] Body Heatmap — тепловая карта нагрузки мышц (силуэт)
- [ ] Athlete Card — полноценная карточка в профиле (при выборе «Тренировка»)
- [ ] Radar Chart для тренировок (сила/выносливость/объём/частота)
