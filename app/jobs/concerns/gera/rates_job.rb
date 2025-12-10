# frozen_string_literal: true

require 'rest-client'

module Gera
  module RatesJob
    extend ActiveSupport::Concern

    Error = Class.new(StandardError)

    def perform
      logger.debug "RatesJob: before perform for #{rate_source.class.name}"
      ActiveRecord::Base.connection.clear_query_cache

      @rates = load_rates
      create_rate_source_snapshot
      save_all_rates
      rate_source_snapshot.id
    rescue ActiveRecord::RecordNotUnique, RestClient::TooManyRequests => error
      raise error if Rails.env.test?

      logger.error error
      Bugsnag.notify(error) do |b|
        b.severity = :warning
        b.meta_data = { error: error }
      end
    end

    private

    attr_reader :rate_source_snapshot, :rates
    delegate :actual_for, to: :rate_source_snapshot

    def create_rate_source_snapshot
      @rate_source_snapshot ||= rate_source.snapshots.create!(actual_for: Time.zone.now)
    end

    def save_all_rates
      batched_rates = rates.each_with_object({}) do |(pair, data), hash|
        buy_key, sell_key = rate_keys.values_at(:buy, :sell)

        buy_price  = data.is_a?(Array) ? data[buy_key]  : data[buy_key.to_s]
        sell_price = data.is_a?(Array) ? data[sell_key] : data[sell_key.to_s]

        next unless buy_price && sell_price

        # Convert CurrencyPair to string for JSON serialization
        pair_str = pair.respond_to?(:to_str) ? pair.to_str : pair.to_s
        hash[pair_str] = { 'buy' => buy_price.to_f, 'sell' => sell_price.to_f }
      end

      ExternalRatesBatchJob.perform_later(
        rate_source_snapshot.id,
        rate_source.id,
        batched_rates
      )
    end

    def rate_keys
      raise NotImplementedError, 'You must define #rate_keys in your job'
    end
  end
end
