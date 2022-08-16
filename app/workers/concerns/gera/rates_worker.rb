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
      logger.debug 'RatesWorker: after transaction'
      rate_source.update(actual_snapshot_id: snapshot.id) if snapshot.present?

      CurrencyRatesWorker.new.perform
      logger.debug 'RatesWorker: after perform'
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
      ExternalRate.create!(
        currency_pair: currency_pair,
        snapshot: snapshot,
        source: rate_source,
        rate_value: buy_price.to_f
      )
      ExternalRate.create!(
        currency_pair: currency_pair.inverse,
        snapshot: snapshot,
        source: rate_source,
        rate_value: 1.0 / sell_price.to_f
      )
    rescue ActiveRecord::RecordNotUnique => err
      raise error if Rails.env.test?

      if err.message.include? 'external_rates_unique_index'
        logger.debug "save_rate_for_date: #{actual_for} , #{currency_pair} -> #{err}"
        if defined? Bugsnag
          Bugsnag.notify 'Try to rewrite rates' do |b|
            b.meta_data = { actual_for: actual_for, snapshot_id: snapshot.id, currency_pair: currency_pair }
          end
        end
      else
        logger.error "save_rate_for_date: #{actual_for} , #{pair} -> #{err}"
        raise error
      end
    end
  end
end
