# frozen_string_literal: true

module Gera
  class AutoComissionByBaseRateFlagWorker
    include Sidekiq::Worker
    include AutoLogger

    UPTIME = 1.hour

    def perform(exchange_rate_id, instant_start = false)
      unless instant_start
        self.class.perform_in(UPTIME, exchange_rate_id, true)
      else
        ExchangeRate.find(exchange_rate_id).update(auto_comission_by_base_rate: false)
      end
    end
  end
end
