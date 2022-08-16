# frozen_string_literal: true

module Gera
  class RateSourceBinance < RateSource
    def self.supported_currencies
      %i[BTC BCH DSH ETH ETC LTC XRP XMR ZEC NEO EOS ADA XEM WAVES TRX DOGE BNB XLM DOT USDT UNI LINK].map { |m| Money::Currency.find! m }
    end

    validate :external_rates_snapshot_count, on: :update, if: :actual_snapshot_id_changed?

    private

    def external_rates_snapshot_count
      _, snapshot_candidate_id = actual_snapshot_id_change
      snapshot_candidate = snapshots.find(snapshot_candidate_id)
      valid_snapshot_external_rates_count = available_pairs.count
      return if snapshot_candidate.external_rates.count == valid_snapshot_external_rates_count

      snapshot_candidate.destroy
      raise 'Snapshot is not valid'
    end
  end
end
