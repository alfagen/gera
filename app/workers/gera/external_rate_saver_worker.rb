# frozen_string_literal: true

module Gera
    class ExternalRateSaverWorker
      include Sidekiq::Worker
      include AutoLogger
  
      sidekiq_options queue: :external_rates
  
      def perform(currency_pair, snapshot_id, source_type, source_id, rate_value)
        rate_source = source_type.constantize.find(source_id)
        candidate_snapshot = ExternalRateSnapshot.find(snapshot_id)
        ExternalRate.create!(
          currency_pair: CurrencyPair.new(currency_pair),
          snapshot: candidate_snapshot,
          source: rate_source,
          rate_value: rate_value
        )
        if rate_source.actual_snapshot.external_rates.count == candidate_snapshot.external_rates.count
          rate_source.update(actual_snapshot_id: candidate_snapshot.id)
          CurrencyRatesWorker.new.perform
        end
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
