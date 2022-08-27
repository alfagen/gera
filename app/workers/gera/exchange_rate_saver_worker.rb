# frozen_string_literal: true

module Gera
  class ExchangeRateSaverWorker
    include Sidekiq::Worker
    include AutoLogger

    def perform
      ExchangeRate.redis_list.each do |exchange_rate_json|
        ExchangeRate.find(exchange_rate_json.id).update_attributes(exchange_rate_json)
      end
    end
  end
end
