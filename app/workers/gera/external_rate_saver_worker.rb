# frozen_string_literal: true

module Gera
  class ExternalRateSaverWorker
    include Sidekiq::Worker
    include AutoLogger

    def perform
      ExternalRate.redis_list.each do |external_rate_json|
        ExternalRate.create!(external_rate_json)
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
end
