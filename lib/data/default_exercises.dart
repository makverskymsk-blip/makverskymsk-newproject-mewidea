/// Default exercise library — seeded on first launch.
/// Each entry: {'name': ..., 'muscle_group': ..., 'secondary_muscles': [...]}
const List<Map<String, dynamic>> kDefaultExercises = [
  // ═══════════════════════════════════════════════
  //  ГРУДЬ (Chest)
  // ═══════════════════════════════════════════════
  {'name': 'Жим штанги лёжа', 'muscle_group': 'Грудь', 'secondary_muscles': ['Трицепс', 'Плечи']},
  {'name': 'Жим гантелей лёжа', 'muscle_group': 'Грудь', 'secondary_muscles': ['Трицепс', 'Плечи']},
  {'name': 'Жим штанги на наклонной скамье', 'muscle_group': 'Грудь', 'secondary_muscles': ['Плечи', 'Трицепс']},
  {'name': 'Жим гантелей на наклонной скамье', 'muscle_group': 'Грудь', 'secondary_muscles': ['Плечи', 'Трицепс']},
  {'name': 'Жим штанги на скамье с отрицательным наклоном', 'muscle_group': 'Грудь', 'secondary_muscles': ['Трицепс']},
  {'name': 'Разводка гантелей лёжа', 'muscle_group': 'Грудь', 'secondary_muscles': <String>[]},
  {'name': 'Сведение рук в кроссовере', 'muscle_group': 'Грудь', 'secondary_muscles': <String>[]},
  {'name': 'Отжимания от пола', 'muscle_group': 'Грудь', 'secondary_muscles': ['Трицепс', 'Плечи']},
  {'name': 'Отжимания на брусьях', 'muscle_group': 'Грудь', 'secondary_muscles': ['Трицепс', 'Плечи']},
  {'name': 'Пуловер с гантелью', 'muscle_group': 'Грудь', 'secondary_muscles': ['Спина']},

  // ═══════════════════════════════════════════════
  //  СПИНА (Back)
  // ═══════════════════════════════════════════════
  {'name': 'Подтягивания широким хватом', 'muscle_group': 'Спина', 'secondary_muscles': ['Бицепс']},
  {'name': 'Подтягивания обратным хватом', 'muscle_group': 'Спина', 'secondary_muscles': ['Бицепс']},
  {'name': 'Тяга штанги в наклоне', 'muscle_group': 'Спина', 'secondary_muscles': ['Бицепс']},
  {'name': 'Тяга гантели в наклоне', 'muscle_group': 'Спина', 'secondary_muscles': ['Бицепс']},
  {'name': 'Тяга верхнего блока к груди', 'muscle_group': 'Спина', 'secondary_muscles': ['Бицепс']},
  {'name': 'Тяга верхнего блока за голову', 'muscle_group': 'Спина', 'secondary_muscles': ['Бицепс']},
  {'name': 'Тяга нижнего блока к поясу', 'muscle_group': 'Спина', 'secondary_muscles': ['Бицепс']},
  {'name': 'Тяга Т-грифа', 'muscle_group': 'Спина', 'secondary_muscles': ['Бицепс']},
  {'name': 'Становая тяга', 'muscle_group': 'Спина', 'secondary_muscles': ['Ноги']},
  {'name': 'Гиперэкстензия', 'muscle_group': 'Спина', 'secondary_muscles': <String>[]},

  // ═══════════════════════════════════════════════
  //  ПЛЕЧИ (Shoulders)
  // ═══════════════════════════════════════════════
  {'name': 'Жим штанги стоя (армейский)', 'muscle_group': 'Плечи', 'secondary_muscles': ['Трицепс']},
  {'name': 'Жим гантелей сидя', 'muscle_group': 'Плечи', 'secondary_muscles': ['Трицепс']},
  {'name': 'Жим Арнольда', 'muscle_group': 'Плечи', 'secondary_muscles': ['Трицепс']},
  {'name': 'Махи гантелями в стороны', 'muscle_group': 'Плечи', 'secondary_muscles': <String>[]},
  {'name': 'Махи гантелями перед собой', 'muscle_group': 'Плечи', 'secondary_muscles': <String>[]},
  {'name': 'Разводка гантелей в наклоне', 'muscle_group': 'Плечи', 'secondary_muscles': ['Спина']},
  {'name': 'Тяга штанги к подбородку', 'muscle_group': 'Плечи', 'secondary_muscles': ['Трицепс']},
  {'name': 'Шраги со штангой', 'muscle_group': 'Плечи', 'secondary_muscles': <String>[]},
  {'name': 'Шраги с гантелями', 'muscle_group': 'Плечи', 'secondary_muscles': <String>[]},

  // ═══════════════════════════════════════════════
  //  БИЦЕПС (Biceps)
  // ═══════════════════════════════════════════════
  {'name': 'Сгибание рук со штангой стоя', 'muscle_group': 'Бицепс', 'secondary_muscles': <String>[]},
  {'name': 'Сгибание рук с гантелями стоя', 'muscle_group': 'Бицепс', 'secondary_muscles': <String>[]},
  {'name': 'Молотки с гантелями', 'muscle_group': 'Бицепс', 'secondary_muscles': <String>[]},
  {'name': 'Сгибание рук на скамье Скотта', 'muscle_group': 'Бицепс', 'secondary_muscles': <String>[]},
  {'name': 'Концентрированные сгибания', 'muscle_group': 'Бицепс', 'secondary_muscles': <String>[]},
  {'name': 'Сгибание рук с EZ-грифом', 'muscle_group': 'Бицепс', 'secondary_muscles': <String>[]},
  {'name': 'Сгибание рук на нижнем блоке', 'muscle_group': 'Бицепс', 'secondary_muscles': <String>[]},

  // ═══════════════════════════════════════════════
  //  ТРИЦЕПС (Triceps)
  // ═══════════════════════════════════════════════
  {'name': 'Жим штанги узким хватом', 'muscle_group': 'Трицепс', 'secondary_muscles': ['Грудь']},
  {'name': 'Французский жим лёжа', 'muscle_group': 'Трицепс', 'secondary_muscles': <String>[]},
  {'name': 'Французский жим стоя с гантелью', 'muscle_group': 'Трицепс', 'secondary_muscles': <String>[]},
  {'name': 'Разгибание рук на верхнем блоке', 'muscle_group': 'Трицепс', 'secondary_muscles': <String>[]},
  {'name': 'Разгибание рук с канатом', 'muscle_group': 'Трицепс', 'secondary_muscles': <String>[]},
  {'name': 'Разгибание руки с гантелью в наклоне', 'muscle_group': 'Трицепс', 'secondary_muscles': <String>[]},
  {'name': 'Отжимания узким хватом', 'muscle_group': 'Трицепс', 'secondary_muscles': ['Грудь']},

  // ═══════════════════════════════════════════════
  //  НОГИ (Legs)
  // ═══════════════════════════════════════════════
  {'name': 'Приседания со штангой', 'muscle_group': 'Ноги', 'secondary_muscles': ['Спина']},
  {'name': 'Фронтальные приседания', 'muscle_group': 'Ноги', 'secondary_muscles': ['Спина']},
  {'name': 'Жим ногами в тренажёре', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},
  {'name': 'Выпады с гантелями', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},
  {'name': 'Выпады со штангой', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},
  {'name': 'Болгарские выпады', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},
  {'name': 'Разгибание ног в тренажёре', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},
  {'name': 'Сгибание ног в тренажёре', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},
  {'name': 'Подъём на носки стоя', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},
  {'name': 'Подъём на носки сидя', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},
  {'name': 'Румынская тяга', 'muscle_group': 'Ноги', 'secondary_muscles': ['Спина']},
  {'name': 'Гакк-приседания', 'muscle_group': 'Ноги', 'secondary_muscles': <String>[]},

  // ═══════════════════════════════════════════════
  //  ПРЕСС (Abs)
  // ═══════════════════════════════════════════════
  {'name': 'Скручивания', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},
  {'name': 'Скручивания на наклонной скамье', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},
  {'name': 'Подъём ног в висе', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},
  {'name': 'Подъём ног лёжа', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},
  {'name': 'Планка', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},
  {'name': 'Боковая планка', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},
  {'name': 'Русские скручивания', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},
  {'name': 'Велосипед (пресс)', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},
  {'name': 'Скручивания в кроссовере (молитва)', 'muscle_group': 'Пресс', 'secondary_muscles': <String>[]},

  // ═══════════════════════════════════════════════
  //  КАРДИО (Cardio)
  // ═══════════════════════════════════════════════
  {'name': 'Бег на дорожке', 'muscle_group': 'Кардио', 'secondary_muscles': ['Ноги']},
  {'name': 'Велотренажёр', 'muscle_group': 'Кардио', 'secondary_muscles': ['Ноги']},
  {'name': 'Эллиптический тренажёр', 'muscle_group': 'Кардио', 'secondary_muscles': <String>[]},
  {'name': 'Гребной тренажёр', 'muscle_group': 'Кардио', 'secondary_muscles': ['Спина']},
  {'name': 'Скакалка', 'muscle_group': 'Кардио', 'secondary_muscles': ['Ноги']},
  {'name': 'Берпи', 'muscle_group': 'Кардио', 'secondary_muscles': ['Грудь', 'Ноги']},
  {'name': 'Прыжки на бокс', 'muscle_group': 'Кардио', 'secondary_muscles': ['Ноги']},
  {'name': 'Бег на улице', 'muscle_group': 'Кардио', 'secondary_muscles': ['Ноги']},
];
