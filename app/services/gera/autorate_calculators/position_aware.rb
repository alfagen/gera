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
    # - UC-12: Не вычитать GAP при одинаковых курсах (для любого position_from)
    class PositionAware < Base
      # Минимальный GAP (используется когда разница между позициями меньше стандартного)
      MIN_GAP = 0.0001

      def call
        debug_log("START position_from=#{position_from} position_to=#{position_to}")
        debug_log("autorate_from=#{autorate_from} autorate_to=#{autorate_to}")

        return 0 unless could_be_calculated?

        # UC-8: Фильтрация своего обменника
        filtered = filtered_external_rates
        debug_log("Filtered rates count: #{filtered&.size}, our_exchanger_id: #{Gera.our_exchanger_id}")

        unless filtered.present?
          debug_log("RETURN autorate_from (no filtered rates)")
          return autorate_from
        end

        rates_in_target_position = filtered[(position_from - 1)..(position_to - 1)]
        debug_log("Target position rates [#{position_from - 1}..#{position_to - 1}]: #{rates_in_target_position&.map(&:target_rate_percent)&.first(5)}")

        unless rates_in_target_position.present?
          debug_log("RETURN autorate_from (no rates in target position)")
          return autorate_from
        end

        valid_rates = rates_in_target_position.select do |rate|
          (autorate_from..autorate_to).include?(rate.target_rate_percent)
        end

        if valid_rates.empty?
          debug_log("RETURN autorate_from (no valid rates in commission range)")
          return autorate_from
        end

        target_rate = valid_rates.first
        debug_log("Target rate: #{target_rate.target_rate_percent}")

        # UC-12: При одинаковых курсах не вычитаем GAP (для любого position_from)
        if should_skip_gap?(filtered, target_rate)
          debug_log("UC-12: Skipping GAP, RETURN #{target_rate.target_rate_percent}")
          return round_commission(target_rate.target_rate_percent)
        end

        # UC-6: Адаптивный GAP
        gap = calculate_adaptive_gap(filtered, target_rate)
        debug_log("Calculated GAP: #{gap}")

        target_comission = round_commission(target_rate.target_rate_percent - gap)
        debug_log("Target comission after GAP: #{target_comission}")

        # Проверяем, не перепрыгнем ли мы позицию выше position_from
        adjusted_comission = adjust_for_position_above(target_comission, target_rate, filtered)
        debug_log("Adjusted comission: #{adjusted_comission}")

        result = round_commission(adjusted_comission)
        debug_log("FINAL RESULT: #{result}")
        result
      end

      private

      def debug_log(message)
        return unless Gera.autorate_debug_enabled

        Rails.logger.debug { "[PositionAware] #{message}" }
      end

      # UC-12: Проверяем, нужно ли пропустить вычитание GAP
      # Если курс на целевой позиции равен курсу на соседней позиции - не вычитаем GAP
      def should_skip_gap?(rates, target_rate)
        if position_from == 1
          # Для position_from=1: сравниваем с позицией НИЖЕ (следующей)
          return false if rates.size < 2

          next_rate = rates[1]
          next_rate && next_rate.target_rate_percent == target_rate.target_rate_percent
        else
          # Для position_from>1: сравниваем с позицией ВЫШЕ (предыдущей)
          return false if rates.size < position_from

          rate_above = rates[position_from - 2]
          rate_above && rate_above.target_rate_percent == target_rate.target_rate_percent
        end
      end

      # UC-8: Фильтрация своего обменника
      def filtered_external_rates
        return external_rates unless Gera.our_exchanger_id.present?

        external_rates.reject { |rate| rate.exchanger_id == Gera.our_exchanger_id }
      end

      # UC-6: Адаптивный GAP
      def calculate_adaptive_gap(rates, target_rate)
        if position_from <= 1
          debug_log("calculate_adaptive_gap: position_from <= 1, using AUTO_COMISSION_GAP")
          return AUTO_COMISSION_GAP
        end

        rate_above = rates[position_from - 2]
        debug_log("calculate_adaptive_gap: rate_above[#{position_from - 2}] = #{rate_above&.target_rate_percent}")

        unless rate_above
          debug_log("calculate_adaptive_gap: no rate_above, using AUTO_COMISSION_GAP")
          return AUTO_COMISSION_GAP
        end

        diff = target_rate.target_rate_percent - rate_above.target_rate_percent
        debug_log("calculate_adaptive_gap: diff = #{diff} (target #{target_rate.target_rate_percent} - above #{rate_above.target_rate_percent})")

        # Если разница между позициями меньше стандартного GAP,
        # используем половину разницы (но не меньше MIN_GAP)
        if diff.positive? && diff < AUTO_COMISSION_GAP
          gap = [diff / 2.0, MIN_GAP].max
          debug_log("calculate_adaptive_gap: using adaptive gap = #{gap}")
          gap
        else
          debug_log("calculate_adaptive_gap: using AUTO_COMISSION_GAP = #{AUTO_COMISSION_GAP}")
          AUTO_COMISSION_GAP
        end
      end

      def adjust_for_position_above(target_comission, target_rate, rates)
        if position_from <= 1
          debug_log("adjust_for_position_above: position_from <= 1, no adjustment")
          return target_comission
        end

        # UC-9: Найти ближайшую нормальную позицию выше
        rate_above = find_non_anomalous_rate_above(rates)
        debug_log("adjust_for_position_above: rate_above = #{rate_above&.target_rate_percent}")

        unless rate_above
          debug_log("adjust_for_position_above: NO rate_above found! Returning target_comission unchanged")
          return target_comission
        end

        rate_above_comission = rate_above.target_rate_percent
        debug_log("adjust_for_position_above: comparing target_comission (#{target_comission}) < rate_above_comission (#{rate_above_comission}) = #{target_comission < rate_above_comission}")

        # Если после вычитания GAP комиссия станет меньше (выгоднее) чем у позиции выше -
        # мы перепрыгнём её. Нужно скорректировать.
        if target_comission < rate_above_comission
          # Устанавливаем комиссию равную или чуть выше (хуже) чем у позиции выше,
          # но не хуже чем у целевой позиции
          safe_comission = [rate_above_comission, target_rate.target_rate_percent].min
          debug_log("adjust_for_position_above: ADJUSTING to safe_comission = #{safe_comission}")

          # Если одинаковые курсы - оставляем как есть, BestChange определит позицию по вторичным критериям
          return safe_comission
        end

        debug_log("adjust_for_position_above: no adjustment needed")
        target_comission
      end

      # UC-9: Найти ближайшую нормальную (не аномальную) позицию выше целевой
      def find_non_anomalous_rate_above(rates)
        if position_from <= 1
          debug_log("find_non_anomalous_rate_above: position_from <= 1, returning nil")
          return nil
        end

        # Берём все позиции выше целевой (от 0 до position_from - 2)
        rates_above = rates[0..(position_from - 2)]
        debug_log("find_non_anomalous_rate_above: rates_above[0..#{position_from - 2}] = #{rates_above&.map(&:target_rate_percent)}")

        unless rates_above.present?
          debug_log("find_non_anomalous_rate_above: no rates_above, returning nil")
          return nil
        end

        # Если фильтрация аномалий отключена - просто берём ближайшую позицию выше
        threshold = Gera.anomaly_threshold_percent
        debug_log("find_non_anomalous_rate_above: anomaly_threshold = #{threshold}, rates.size = #{rates.size}")

        unless threshold&.positive? && rates.size >= 3
          debug_log("find_non_anomalous_rate_above: anomaly filter disabled, returning rates_above.last = #{rates_above.last&.target_rate_percent}")
          return rates_above.last
        end

        # Вычисляем медиану для определения аномалий
        all_comissions = rates.map(&:target_rate_percent).sort
        median = all_comissions[all_comissions.size / 2]
        debug_log("find_non_anomalous_rate_above: median = #{median}")

        # Ищем ближайшую нормальную позицию сверху вниз
        result = rates_above.reverse.find do |rate|
          deviation = ((rate.target_rate_percent - median) / median * 100).abs
          debug_log("find_non_anomalous_rate_above: rate #{rate.target_rate_percent} deviation = #{deviation.round(4)}% (threshold: #{threshold})")
          deviation <= threshold
        end

        debug_log("find_non_anomalous_rate_above: result = #{result&.target_rate_percent || 'nil'}")
        result
      end
    end
  end
end
