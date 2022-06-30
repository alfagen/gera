# frozen_string_literal: true

module Gera
  class AutoComissionByBaseRateFlagWorker
    include Sidekiq::Worker
    include AutoLogger

    def perform(exchange_rate_id)
      ExchangeRate.find(exchange_rate_id).update(auto_comission_by_base_rate: false)
    end
  end
end
