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
        raise "Time must be even to #{INTERVAL}" unless interval_from.min % INTERVAL.parts[:minutes] == 0
        raise "Time must be even to #{INTERVAL}" unless interval_to.min % INTERVAL.parts[:minutes] == 0
        raise 'Time must have zero seconds' unless interval_from.sec == 0
        raise 'Time must have zero seconds' unless interval_to.sec == 0
      end

      before_save do
        raise "min_rate (#{min_rate}) must be less or equal to max_rate (#{max_rate})" if min_rate > max_rate
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
            logger.info "#{self}: Create HistoryInterval #{f} -> #{f + INTERVAL}"
            transaction do
              create_by_interval! f, f + INTERVAL
            end
            logger.info "#{self}: Create HistoryInterval #{f} -> #{f + INTERVAL} - done"
          rescue ActiveRecord::RecordNotUnique => err
            logger.error err
          end
        end
      end
    end
  end
end
