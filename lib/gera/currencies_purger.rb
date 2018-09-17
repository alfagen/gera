module GERA
  module CurrenciesPurger
    def self.purge_all(env)
      raise unless env == Rails.env

      if Rails.env.prodiction?
        puts 'Disable all sidekiqs'
        Sidekiq::Cron::Job.all.each(&:disable!)
        sleep 2
      end

      DirectionRateSnapshot.batch_purge if DirectionRateSnapshot.table_exists?
      DirectionRate.batch_purge

      ExternalRate.batch_purge
      ExternalRateSnapshot.batch_purge

      CurrencyRate.batch_purge
      RateSource.update_all actual_snapshot_id: nil
      CurrencyRateSnapshot.batch_purge

      if Rails.env.prodiction?
        puts 'Enable all sidekiqs'
        Sidekiq::Cron::Job.all.each(&:enable!)
      end
    end
  end
end
