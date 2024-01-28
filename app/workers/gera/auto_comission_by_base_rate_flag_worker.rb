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
        logger = Logger.new("#{Rails.root}/log/call_exchange_rate_updater_worker.log")
        logger.info("Calls perform_async from Gera::AutoComissionByBaseRateFlagWorker")
        ExchangeRateUpdaterWorker.perform_async(exchange_rate_id, { auto_comission_by_base_rate: false })
      end
    end
  end
end
