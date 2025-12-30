# Система Автокурса (AutoRate) — Legacy

> **Внимание:** Это документация **legacy-системы** расчёта курсов. Данная система используется в текущей production-версии, но планируется к замене.

---

## Краткое описание для бизнес-аналитика

### Что это
Система автоматически рассчитывает комиссию обменного направления, чтобы поддерживать конкурентную позицию в рейтинге BestChange.

### Как формируется комиссия

Итоговая комиссия = **Базовая** + **Корректировка по резервам** + **Корректировка по курсу**

---

**1. Базовая комиссия (по позиции в BestChange)**

Оператор задаёт:
- Целевой диапазон позиций (например, 3–5 место)
- Допустимый диапазон комиссии (например, 1–3%)

Система смотрит, какую комиссию ставят конкуренты на этих позициях, и ставит **на 0.01% ниже** первого подходящего — чтобы быть чуть выгоднее.

---

**2. Корректировка по резервам** *(опционально)*

Если резервов много → можно снизить комиссию (привлечь больше клиентов)
Если резервов мало → повысить комиссию (снизить нагрузку)

Настраивается через контрольные точки: "при отклонении резерва на X% — изменить комиссию на Y%"

> **Как включить:** Создать `AutoRateSetting` для платёжной системы + добавить `AutoRateCheckpoint` с типом `reserve`. Если настройки отсутствуют — корректировка = 0.

---

**3. Корректировка по динамике курса** *(опционально)*

Сравнивается текущий курс со средним за 24 часа.
При резких скачках курса комиссия корректируется для снижения рисков.

> **Как включить:** Добавить `AutoRateCheckpoint` с типом `by_base_rate` для обеих платёжных систем направления. Если настройки отсутствуют — корректировка = 0.

---

### Пример

| Параметр | Значение |
|----------|----------|
| Целевая позиция | 3–5 место |
| Допустимая комиссия | 1–3% |
| Комиссия конкурента на 3 месте | 2.5% |
| **Наша комиссия** | **2.49%** |

Плюс корректировки по резервам и курсу, если настроены.

---

### Итог

Система позволяет автоматически удерживать заданную позицию в рейтинге, при этом учитывая внутренние ограничения (резервы) и рыночные условия (волатильность курса).

---

## Техническое описание

## Обзор

Система автокурса автоматически рассчитывает комиссию обменного направления на основе:
1. Позиции в рейтинге BestChange
2. Текущих резервов платежных систем
3. Динамики базового курса валют

---

## Структура данных

### Основные модели

#### `Gera::ExchangeRate` (таблица: `gera_exchange_rates`)

Направление обмена между платежными системами.

| Поле | Тип | Описание |
|------|-----|----------|
| `income_payment_system_id` | integer | Входящая ПС |
| `outcome_payment_system_id` | integer | Исходящая ПС |
| `value` (alias: `comission`) | float | Базовая комиссия направления (%) |
| `auto_rate` | boolean | Флаг включения автокурса |
| `source` | string | Источник курсов: `bestchange`, `manual` |
| `margin` | float | Наценка (%) |
| `is_enabled` | boolean | Направление включено |

**Файл модели:** `vendor/gera → gera/app/models/gera/exchange_rate.rb`

---

#### `Gera::TargetAutorateSetting` (таблица: `gera_target_autorate_settings`)

Настройки автокурса для конкретного направления.

| Поле | Тип | Описание |
|------|-----|----------|
| `exchange_rate_id` | integer | Связь с направлением |
| `position_from` | integer | Целевая позиция в BestChange (от) |
| `position_to` | integer | Целевая позиция в BestChange (до) |
| `autorate_from` | float | Целевая комиссия (от, %) |
| `autorate_to` | float | Целевая комиссия (до, %) |

**Файл модели:** `vendor/gera → gera/app/models/gera/target_autorate_setting.rb`

**Условие применимости:**
```ruby
def could_be_calculated?
  position_from.present? && position_to.present? && autorate_from.present? && autorate_to.present?
end
```

---

#### `AutoRateSetting` (таблица: `auto_rate_settings`)

Настройки автокурса для платежной системы.

| Поле | Тип | Описание |
|------|-----|----------|
| `payment_system_id` | integer | Платежная система |
| `direction` | string | `'income'` или `'outcome'` |
| `min_fee_percents` | float | Минимальная комиссия (%) |
| `max_fee_percents` | float | Максимальная комиссия (%) |
| `base_reserve_cents` | bigint | Базовый резерв (в центах) |
| `base_reserve_currency` | string | Валюта резерва |
| `total_checkpoints` | integer | Количество контрольных точек |

**Файл модели:** `app/models/auto_rate_setting.rb`

---

#### `AutoRateCheckpoint` (таблица: `auto_rate_checkpoints`)

Контрольные точки для расчета комиссии.

| Поле | Тип | Описание |
|------|-----|----------|
| `auto_rate_setting_id` | integer | Связь с настройкой |
| `checkpoint_type` | string | `'reserve'` или `'by_base_rate'` |
| `direction` | string | `'plus'` или `'minus'` |
| `value_percents` | float | Порог срабатывания (%) |
| `min_boundary` | float | Минимальная граница комиссии |
| `max_boundary` | float | Максимальная граница комиссии |

**Файл модели:** `app/models/auto_rate_checkpoint.rb`

---

## Алгоритм расчета комиссии

### Ключевой сервис: `Gera::RateComissionCalculator`

**Файл:** `vendor/gera → gera/app/services/gera/rate_comission_calculator.rb`

Итоговая комиссия складывается из трех компонентов:

```ruby
def commission
  auto_comission_by_external_comissions + auto_comission_by_reserve + comission_by_base_rate
end
```

---

### Компонент 1: Комиссия по позиции в BestChange

**Метод:** `auto_comission_by_external_comissions`

**Логика:**
1. Загружаются данные обменников из `BestChange::Repository`
2. Фильтруются по диапазону позиций `position_from..position_to`
3. Из них выбираются те, чья комиссия попадает в диапазон `autorate_from..autorate_to`
4. Берется первый обменник, из его комиссии вычитается `AUTO_COMISSION_GAP` (0.01)

```ruby
# Строки 161-172
def auto_comission_by_external_comissions
  return 0 unless could_be_calculated?

  external_rates_in_target_position = external_rates[(position_from - 1)..(position_to - 1)]
  return autorate_from unless external_rates_in_target_position.present?

  external_rates_in_target_comission = external_rates_in_target_position.select { |rate|
    ((autorate_from)..(autorate_to)).include?(rate.target_rate_percent)
  }
  return autorate_from if external_rates_in_target_comission.empty?

  target_comission = external_rates_in_target_comission.first.target_rate_percent - AUTO_COMISSION_GAP
end
```

---

### Компонент 2: Комиссия по резервам

**Метод:** `auto_comission_by_reserve`

**Логика:**
1. Для income и outcome платежных систем ищутся `AutoRateSetting` с `direction: 'income'/'outcome'`
2. Сравнивается текущий резерв (`reserve`) с базовым резервом (`base`)
3. Определяется направление: `'plus'` если резерв >= базы, иначе `'minus'`
4. Рассчитывается процент отклонения: `(max - min) / min * 100`
5. Ищется checkpoint с `checkpoint_type: 'reserve'` и подходящим `value_percents`
6. Усредняются `min_boundary` и `max_boundary` от обеих платежных систем

```ruby
# Строки 96-110
def income_reserve_checkpoint
  income_auto_rate_setting.checkpoint(
    base_value: income_auto_rate_setting.reserve,
    additional_value: income_auto_rate_setting.base,
    type: 'reserve'
  )
end

# AutoRateSetting#checkpoint (app/models/auto_rate_setting.rb:18-21)
def checkpoint(base_value:, additional_value:, type:)
  direction = base_value >= additional_value ? 'plus' : 'minus'
  find_checkpoint(reserve_ratio: calculate_diff_in_percents(base_value, additional_value), direction: direction, type: type)
end
```

---

### Компонент 3: Комиссия по базовому курсу

**Метод:** `comission_by_base_rate`

**Логика:**
1. Получается текущий курс валют (`current_base_rate`)
2. Получается средний курс за последние 24 часа (`average_base_rate`)
3. Сравниваются значения
4. Ищется checkpoint с `checkpoint_type: 'by_base_rate'`
5. Усредняются границы

```ruby
# Строки 54-63
def current_base_rate
  return 1.0 if same_currencies?
  Gera::CurrencyRateHistoryInterval
    .where(cur_from_id: in_currency.local_id, cur_to_id: out_currency.local_id)
    .last.avg_rate
end

def average_base_rate
  return 1.0 if same_currencies?
  Gera::CurrencyRateHistoryInterval
    .where('interval_from > ?', DateTime.now.utc - 24.hours)
    .where(cur_from_id: in_currency.local_id, cur_to_id: out_currency.local_id)
    .average(:avg_rate)
end
```

---

## Применение комиссии к курсу

### 1. Получение итоговой комиссии

**Файл:** `gera/app/models/gera/exchange_rate.rb:159-161`

```ruby
def final_rate_percents
  @final_rate_percents ||= auto_rate? ? rate_comission_calculator.auto_comission : rate_comission_calculator.fixed_comission
end
```

### 2. Расчет конечного курса

**Файл:** `gera/app/models/gera/direction_rate.rb:139-145`

```ruby
def calculate_rate
  self.base_rate_value = currency_rate.rate_value
  raise UnknownExchangeRate unless exchange_rate

  self.rate_percent = exchange_rate.final_rate_percents  # ← Берется auto или fixed комиссия
  self.rate_value = calculate_finite_rate(base_rate_value, rate_percent)
end
```

### 3. Формула расчета конечного курса

**Файл:** `gera/app/models/concerns/gera/mathematic.rb`

```ruby
def calculate_finite_rate(base_rate, comission_percents)
  base_rate * (1 - comission_percents / 100.0)
end
```

---

## Источники данных

### BestChange::Repository

Хранит рейтинг обменников из BestChange в Redis.

**Файл:** `vendor/best_change → best_change/lib/best_change/repository.rb`

```ruby
BestChange::Repository.getRows(bestchange_key)  # Возвращает массив Row
```

### BestchangeCacheServer

DRb-сервер для кеширования данных BestChange.

**Файл:** `lib/bestchange_cache_server.rb`

- URI: `druby://localhost:8787`
- TTL кеша: 10 секунд
- Автообновление в фоновом потоке

### ReservesByPaymentSystems

Репозиторий резервов по платежным системам.

**Файл:** `app/repositories/reserves_by_payment_systems.rb`

```ruby
ReservesByPaymentSystems.reserve_by_payment_system(payment_system_id)
```

Данные берутся из Redis: `Redis.new.get('final_reserves')`

### CurrencyRateHistoryInterval

История курсов валют (Gera gem).

```ruby
Gera::CurrencyRateHistoryInterval
  .where(cur_from_id: ..., cur_to_id: ...)
  .last.avg_rate
```

---

## Фоновые задачи (Workers)

| Worker | Очередь | Расписание | Назначение |
|--------|---------|------------|------------|
| `Gera::DirectionsRatesWorker` | critical | Периодически | Пересчитывает все `direction_rates` |
| `BestChange::LoadingWorker` | default | Периодически | Загружает данные из BestChange |
| `ExchangeRateCacheUpdaterWorker` | critical | Каждую минуту | Обновляет кеш позиций Kassa в BC |
| `Gera::ExchangeRateUpdaterJob` | exchange_rates | По событию | Обновляет `comission` в направлении |
| `RateUpdaterWorker` | critical | По событию | Обновляет курс для заказа |

**Конфигурация:** `config/crontab_production.yml`

---

## API управления

### Обновление настроек автокурса

**Endpoint:** `PUT /operator_api/exchange_rates/:id`

**Параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `comission` | float | Ручная комиссия (%) |
| `is_enabled` | boolean | Включено направление |
| `position_from` | integer | Целевая позиция BC (от) |
| `position_to` | integer | Целевая позиция BC (до) |
| `autorate_from` | float | Целевая комиссия (от) |
| `autorate_to` | float | Целевая комиссия (до) |
| `source` | string | Источник курсов |
| `margin` | float | Наценка (%) |

**Файл:** `app/api/operator_api/exchange_rates.rb`

### Изменение позиции в BestChange

**Endpoint:** `PUT /operator_api/bestchange/byExchangeRate/:exchange_rate_id/position`

**Параметр:** `position` (integer) — целевая позиция (начинается с 0)

**Логика:** `BestChange::PositionService#change_position!`

---

## UI управления

| URL | Описание |
|-----|----------|
| `/operator/auto_rate_settings` | Список настроек автокурса для ПС |
| `/operator/auto_rate_settings/:id/edit` | Редактирование настройки |
| `/operator/auto_rate_settings/:id/auto_rate_checkpoints` | Контрольные точки |
| `/operator/exchange_rates` | Матрица направлений |
| `/operator/autorate_managers` | Менеджер автокурса |

---

## Схема работы

```
┌─────────────────────────────────────────────────────────────────────┐
│                           ИСТОЧНИКИ ДАННЫХ                          │
├───────────────────┬───────────────────┬─────────────────────────────┤
│  BestChange API   │  Резервы (Redis)  │  История курсов (MySQL)     │
│  (bm_*.dat файлы) │  final_reserves   │  currency_rate_history_     │
│                   │                   │  intervals                  │
└─────────┬─────────┴─────────┬─────────┴──────────────┬──────────────┘
          │                   │                        │
          ▼                   ▼                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     RateComissionCalculator                         │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐     │
│  │ by_external      │ │ by_reserve       │ │ by_base_rate     │     │
│  │ (позиция в BC)   │+│ (резервы ПС)     │+│ (динамика курса) │     │
│  │                  │ │                  │ │                  │     │
│  │ position_from/to │ │ AutoRateSetting  │ │ current vs avg   │     │
│  │ autorate_from/to │ │ checkpoints      │ │ за 24 часа       │     │
│  └──────────────────┘ └──────────────────┘ └──────────────────┘     │
│                               │                                      │
│                     ┌─────────▼─────────┐                           │
│                     │   auto_comission  │                           │
│                     │   (итоговая %)    │                           │
│                     └─────────┬─────────┘                           │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │     ExchangeRate      │
                    │   final_rate_percents │
                    │   (auto или fixed)    │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │     DirectionRate     │
                    │   base_rate_value     │ ← Курс валют
                    │   rate_percent        │ ← Комиссия
                    │   rate_value          │ ← Конечный курс
                    └───────────────────────┘
```

---

## Ключевые файлы

### Mercury (основное приложение)

| Файл | Описание |
|------|----------|
| `app/models/auto_rate_setting.rb` | Модель настроек для ПС |
| `app/models/auto_rate_checkpoint.rb` | Модель контрольных точек |
| `app/services/auto_rate_updater.rb` | Генерация checkpoint'ов |
| `app/repositories/reserves_by_payment_systems.rb` | Репозиторий резервов |
| `app/api/operator_api/exchange_rates.rb` | API управления |
| `app/workers/exchange_rate_cache_updater_worker.rb` | Обновление кеша |
| `lib/bestchange_cache_server.rb` | DRb-сервер кеша BC |
| `config/initializers/gera.rb` | Инициализация Gera |

### Gera gem (`/home/danil/code/alfagen/gera`)

| Файл | Описание |
|------|----------|
| `app/models/gera/exchange_rate.rb` | Модель направления |
| `app/models/gera/target_autorate_setting.rb` | Настройки автокурса |
| `app/models/gera/direction_rate.rb` | Конечный курс |
| `app/services/gera/rate_comission_calculator.rb` | **Расчет комиссии** |
| `app/jobs/gera/exchange_rate_updater_job.rb` | Обновление курса |

### BestChange gem (`/home/danil/code/alfagen/best_change`)

| Файл | Описание |
|------|----------|
| `lib/best_change/service.rb` | Сервис работы с BC |
| `lib/best_change/repository.rb` | Репозиторий данных BC |
| `lib/best_change/position_service.rb` | Изменение позиции |
| `lib/best_change/row.rb` | Строка рейтинга BC |
| `lib/best_change/record.rb` | Запись с расчетами |

---

## Константы

| Константа | Значение | Файл | Описание |
|-----------|----------|------|----------|
| `AUTO_COMISSION_GAP` | 0.0001 | rate_comission_calculator.rb | Отступ от комиссии конкурента |
| `NOT_ALLOWED_COMISSION_RANGE` | 0.7..1.4 | rate_comission_calculator.rb | Запрещенный диапазон (реферальная BC) |
| `EXCLUDED_PS_IDS` | [54, 56] | rate_comission_calculator.rb | Исключенные ПС |
| `STEP` | 0.005 | position_service.rb | Шаг изменения комиссии |
| `CACHE_TTL` | 10 | bestchange_cache_server.rb | TTL кеша BC (секунды) |

---

## Пример расчета

Допустим для направления QIWI RUB → BTC:

1. **Настройки:**
   - `position_from: 3`, `position_to: 5`
   - `autorate_from: 1.0`, `autorate_to: 3.0`

2. **Данные BestChange (позиции 2-4):**
   - Позиция 3: комиссия 2.5%
   - Позиция 4: комиссия 2.8%
   - Позиция 5: комиссия 3.1%

3. **Расчет `auto_comission_by_external_comissions`:**
   - Фильтр по позиции: [2.5, 2.8, 3.1]
   - Фильтр по комиссии (1.0-3.0): [2.5, 2.8]
   - Первый: 2.5%
   - Результат: 2.5 - 0.01 = **2.49%**

4. **Добавляются корректировки по резервам и курсу (если настроены)**

5. **Итоговая комиссия применяется к курсу:**
   ```
   finite_rate = base_rate * (1 - 2.49 / 100)
   ```
