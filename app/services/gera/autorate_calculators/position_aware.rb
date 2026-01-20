# frozen_string_literal: true

module Gera
  module AutorateCalculators
    # Калькулятор с учётом позиций выше целевого диапазона.
    # Гарантирует, что обменник займёт позицию внутри диапазона position_from..position_to,
    # а не перепрыгнет выше.
    #
    # Поддерживает:
    # - UC-6: Адаптивный GAP для плотных рейтингов
    # - UC-8: Исключение своего обменника из расчёта
    # - UC-9: Защита от манипуляторов с аномальными курсами
    class PositionAware < Base
      # Минимальный GAP (используется когда разница между позициями меньше стандартного)
      MIN_GAP = 0.0001

      def call
        return 0 unless could_be_calculated?

        # UC-8: Фильтрация своего обменника
        filtered = filtered_external_rates
        return autorate_from unless filtered.present?

        rates_in_target_position = filtered[(position_from - 1)..(position_to - 1)]
        return autorate_from unless rates_in_target_position.present?

        valid_rates = rates_in_target_position.select do |rate|
          (autorate_from..autorate_to).include?(target_rate_percent(rate))
        end
        return autorate_from if valid_rates.empty?

        target_rate = valid_rates.first

        # UC-6: Адаптивный GAP
        gap = calculate_adaptive_gap(filtered, target_rate)
        target_comission = target_rate_percent(target_rate) - gap

        # Проверяем, не перепрыгнем ли мы позицию выше position_from
        adjusted_comission = adjust_for_position_above(target_comission, target_rate, filtered)

        adjusted_comission
      end

      private

      # UC-8: Фильтрация своего обменника
      def filtered_external_rates
        return external_rates unless Gera.our_exchanger_id.present?

        external_rates.reject { |rate| changer_id(rate) == Gera.our_exchanger_id }
      end

      # UC-6: Адаптивный GAP
      def calculate_adaptive_gap(rates, target_rate)
        return AUTO_COMISSION_GAP if position_from <= 1

        rate_above = rates[position_from - 2]
        return AUTO_COMISSION_GAP unless rate_above

        diff = target_rate_percent(target_rate) - target_rate_percent(rate_above)

        # Если разница между позициями меньше стандартного GAP,
        # используем половину разницы (но не меньше MIN_GAP)
        if diff.positive? && diff < AUTO_COMISSION_GAP
          [diff / 2.0, MIN_GAP].max
        else
          AUTO_COMISSION_GAP
        end
      end

      def adjust_for_position_above(target_comission, target_rate, rates)
        return target_comission if position_from <= 1

        # UC-9: Найти ближайшую нормальную позицию выше
        rate_above = find_non_anomalous_rate_above(rates)
        return target_comission unless rate_above

        rate_above_comission = target_rate_percent(rate_above)

        # Если после вычитания GAP комиссия станет меньше (выгоднее) чем у позиции выше -
        # мы перепрыгнём её. Нужно скорректировать.
        if target_comission < rate_above_comission
          # Устанавливаем комиссию равную или чуть выше (хуже) чем у позиции выше,
          # но не хуже чем у целевой позиции
          safe_comission = [rate_above_comission, target_rate_percent(target_rate)].min

          # Если одинаковые курсы - оставляем как есть, BestChange определит позицию по вторичным критериям
          return safe_comission
        end

        target_comission
      end

      # UC-9: Найти ближайшую нормальную (не аномальную) позицию выше целевой
      def find_non_anomalous_rate_above(rates)
        return nil if position_from <= 1

        # Берём все позиции выше целевой (от 0 до position_from - 2)
        rates_above = rates[0..(position_from - 2)]
        return nil unless rates_above.present?

        # Если фильтрация аномалий отключена - просто берём ближайшую позицию выше
        threshold = Gera.anomaly_threshold_percent
        return rates_above.last unless threshold&.positive? && rates.size >= 3

        # Вычисляем медиану для определения аномалий
        all_comissions = rates.map { |rate| target_rate_percent(rate) }.sort
        median = all_comissions[all_comissions.size / 2]

        # Ищем ближайшую нормальную позицию сверху вниз
        rates_above.reverse.find do |rate|
          deviation = ((target_rate_percent(rate) - median) / median * 100).abs
          deviation <= threshold
        end
      end
    end
  end
end
