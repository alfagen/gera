# frozen_string_literal: true

require 'open-uri'
require 'rest-client'

module Gera
  # Import rates from all sources
  #
  module RatesWorker
    Error = Class.new StandardError

    def perform
      logger.debug 'RatesWorker: before perform'
      # Alternative approach is `Model.uncached do`
      ActiveRecord::Base.connection.clear_query_cache

      rates = load_rates # Load before a transaction
      logger.debug 'RatesWorker: before transaction'
      create_snapshot
      rates.each do |pair, data|
        save_rate pair, data
      end
      snapshot.id
      # EXMORatesWorker::Error: Error 40016: Maintenance work in progress
    rescue ActiveRecord::RecordNotUnique, RestClient::TooManyRequests => error
      raise error if Rails.env.test?

      logger.error error
      Bugsnag.notify error do |b|
        b.severity = :warning
        b.meta_data = { error: error }
      end
    end

    private

    attr_reader :snapshot

    delegate :actual_for, to: :snapshot

    def create_snapshot
      @snapshot ||= rate_source.snapshots.create! actual_for: Time.zone.now
    end

    def create_external_rates(currency_pair, data, sell_price:, buy_price:)
      ExternalRateSaverWorker.perform_async(currency_pair, snapshot.id, rate_source.class.name, rate_source.id, buy_price.to_f)
      ExternalRateSaverWorker.perform_async(currency_pair.inverse, snapshot.id, rate_source.class.name, rate_source.id, 1.0 / sell_price.to_f)
    end
  end
end
