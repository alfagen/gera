module Gera
  module CurrenciesPurger
    def self.purge_all(env)
      raise unless env == Rails.env

      DirectionRateSnapshot.batch_purge if DirectionRateSnapshot.table_exists?
      DirectionRate.batch_purge

      ExternalRate.batch_purge
      ExternalRateSnapshot.batch_purge

      CurrencyRate.batch_purge
      RateSource.update_all actual_snapshot_id: nil
      CurrencyRateSnapshot.batch_purge
    end
  end
end
