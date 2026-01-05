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
    # - UC-12: Не вычитать GAP при одинаковых курсах (для любого position_from)
    # - UC-13: Защита от перепрыгивания позиции position_from - 1
    # - UC-14: Fallback на первую целевую позицию при отсутствии rate_above (issue #83)
    #
    # ОТМЕНЕНО:
    # - UC-9: Защита от аномалий по медиане (не работает с отрицательными курсами)
    class PositionAware < Base
      # Минимальный GAP (используется когда разница между позициями меньше стандартного)
      # Должен быть меньше AUTO_COMISSION_GAP чтобы адаптивная логика работала
      MIN_GAP = 0.00001

      def call
        debug_log("START position_from=#{position_from} position_to=#{position_to}")
        debug_log("autorate_from=#{autorate_from} autorate_to=#{autorate_to}")

        unless could_be_calculated?
          warn_log("SKIP: could_be_calculated?=false, exchange_rate_id=#{exchange_rate&.id}")
          return 0
        end

        # UC-8: Фильтрация своего обменника
        filtered = filtered_external_rates
        debug_log("Filtered rates count: #{filtered&.size}, our_exchanger_id: #{Gera.our_exchanger_id}")

        unless filtered.present?
          debug_log("RETURN autorate_from (no filtered rates)")
          return autorate_from
        end

        rates_in_target_position = filtered[(position_from - 1)..(position_to - 1)]
        debug_log("Target position rates [#{position_from - 1}..#{position_to - 1}]: #{rates_in_target_position&.compact&.map(&:target_rate_percent)&.first(5)}")

        unless rates_in_target_position.present?
          debug_log("RETURN autorate_from (no rates in target position)")
          return autorate_from
        end

        valid_rates = rates_in_target_position.compact.select do |rate|
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

      # Условное логирование (включается через Gera.autorate_debug_enabled).
      # Использует уровень warn для видимости в production-логах.
      def debug_log(message)
        return unless Gera.autorate_debug_enabled

        log_message(message)
      end

      # Постоянное логирование важных бизнес-событий (не зависит от autorate_debug_enabled).
      # Используется для аварийных путей (fallback failures), требующих внимания.
      def warn_log(message)
        log_message(message)
      end

      # Общий метод логирования с fallback в STDERR когда Rails недоступен
      def log_message(message)
        formatted = "[PositionAware] #{message}"
        if defined?(Rails) && Rails.logger
          Rails.logger.warn { formatted }
        else
          warn formatted
        end
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
      # @raise [ArgumentError] если external_rates nil (должен был быть отфильтрован в could_be_calculated?)
      def filtered_external_rates
        if external_rates.nil?
          raise ArgumentError, "external_rates is nil - should have been caught by could_be_calculated?"
        end

        return external_rates unless Gera.our_exchanger_id.present?

        external_rates.reject { |rate| rate&.exchanger_id == Gera.our_exchanger_id }
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

      # UC-13: Защита от перепрыгивания позиции position_from - 1
      # Если после вычитания GAP наш курс станет лучше чем у позиции выше — корректируем
      #
      # UC-14: Если position_from > 1, но позиции выше нет (rate_above = nil) — занимаем
      # первую целевую позицию если она в допустимом диапазоне autorate_from..autorate_to
      def adjust_for_position_above(target_comission, target_rate, rates)
        if position_from <= 1
          debug_log("adjust_for_position_above: position_from <= 1, no adjustment")
          return target_comission
        end

        # Берём ближайшую позицию выше целевого диапазона
        rate_above = rates[position_from - 2]
        debug_log("adjust_for_position_above: rate_above[#{position_from - 2}] = #{rate_above&.target_rate_percent}")

        # UC-14: Если позиции выше нет — занимаем первую целевую позицию
        unless rate_above
          debug_log("adjust_for_position_above: no rate_above, using fallback")
          # Постоянное логирование для fallback (важное бизнес-событие)
          warn_log("Fallback: no rate_above for position_from=#{position_from}, exchange_rate_id=#{exchange_rate.id}")
          return fallback_to_first_target_position(rates)
        end

        rate_above_comission = rate_above.target_rate_percent
        debug_log("adjust_for_position_above: comparing target_comission (#{target_comission}) < rate_above_comission (#{rate_above_comission}) = #{target_comission < rate_above_comission}")

        # Если после вычитания GAP комиссия станет меньше (выгоднее) чем у позиции выше -
        # мы перепрыгнём её. Нужно скорректировать.
        if target_comission < rate_above_comission
          # Устанавливаем комиссию равную позиции выше (не перепрыгиваем)
          debug_log("adjust_for_position_above: ADJUSTING to rate_above_comission = #{rate_above_comission}")
          return rate_above_comission
        end

        debug_log("adjust_for_position_above: no adjustment needed")
        target_comission
      end

      # UC-14 (issue #83): Fallback на первую целевую позицию при отсутствии позиций выше.
      # При position_from > 1 и rate_above = nil — ВСЕГДА используем курс первой целевой позиции,
      # если он в допустимом диапазоне autorate_from..autorate_to. Иначе — autorate_from.
      #
      # Edge cases:
      # 1. SUCCESS: first_target_rate существует и в диапазоне → round_commission(target)
      # 2. FAIL: first_target_rate = nil (нет данных на позиции) → autorate_from + warn_log
      # 3. FAIL: курс вне диапазона autorate_from..autorate_to → autorate_from + warn_log
      def fallback_to_first_target_position(rates)
        first_target_rate = rates[position_from - 1]

        unless first_target_rate
          warn_log("Fallback FAILED: first_target_rate is nil for position_from=#{position_from}, exchange_rate_id=#{exchange_rate.id}")
          return autorate_from
        end

        first_target_comission = first_target_rate.target_rate_percent
        debug_log("fallback: first_target_rate[#{position_from - 1}] = #{first_target_comission}")

        # Проверяем что первая целевая позиция в допустимом диапазоне
        unless (autorate_from..autorate_to).include?(first_target_comission)
          warn_log("Fallback FAILED: first_target=#{first_target_comission} out of range [#{autorate_from}..#{autorate_to}], exchange_rate_id=#{exchange_rate.id}")
          return autorate_from
        end

        # Всегда возвращаем курс первой целевой позиции (с округлением для консистентности)
        debug_log("fallback: using first_target_comission = #{first_target_comission}")
        round_commission(first_target_comission)
      end
    end
  end
end
