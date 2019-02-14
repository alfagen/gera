# frozen_string_literal: true

module Gera
  module HistoryIntervalConcern
    extend ActiveSupport::Concern
    INTERVAL = 5.minutes

    included do
      extend AutoLogger::Named.new(name: 'history_intervals')
      before_save do
        self.avg_rate = (max_rate + min_rate) / 2.0
      end

      before_save do
        raise "Время старта и финиша должно быть кратно #{INTERVAL}" unless interval_from.min % INTERVAL.parts[:minutes] == 0
        raise "Время старта и финиша должно быть кратно #{INTERVAL}" unless interval_to.min % INTERVAL.parts[:minutes] == 0
        raise 'Время старта и финиша должно быть секунд = 0' unless interval_from.sec == 0
        raise 'Время старта и финиша должно быть секунд = 0' unless interval_to.sec == 0
      end

      before_save do
        raise "min_rate (#{min_rate}) должен быть меньше или равен max_rate (#{max_rate})" if min_rate > max_rate
      end
    end

    class_methods do
      def create_multiple_intervals_from!(interval_from, interval_to = nil)
        interval_from -= interval_from.sec # Обнуляем секунды
        interval_from -= interval_from.min % INTERVAL.parts[:minutes]
        interval_to ||= Time.zone.now
        ((interval_to - interval_from) / 5.minutes).to_i.times do |i|
          f = interval_from + i * INTERVAL
          begin
            logger.info "#{self}: Создаю HistoryInterval #{f} -> #{f + INTERVAL}"
            transaction do
              create_by_interval! f, f + INTERVAL
            end
            logger.info "#{self}: Создаю HistoryInterval #{f} -> #{f + INTERVAL} - готово"
          rescue ActiveRecord::RecordNotUnique => err
            logger.error err
          end
        end
      end
    end
  end
end
