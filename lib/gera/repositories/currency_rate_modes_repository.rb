module Gera
  class CurrencyRateModesRepository
    def snapshot
      @snapshot ||= find_or_create_active_snapshot
    end

    def find_currency_rate_mode_by_pair pair
      modes_by_pair[pair.key]
    end

    def add_currency!(currency)
      snapshot.currency_rate_modes.group(:cur_from).count.keys.each do |cur_from|
        snapshot.currency_rate_modes.create! cur_from: cur_from, cur_to: currency
      end

      snapshot.currency_rate_modes.group(:cur_to).count.keys.each do |cur_to|
        snapshot.currency_rate_modes.create! cur_from: currency, cur_to: cur_to
      end

      @modes_by_pair = build_modes_by_pair
    end

    private

    def find_or_create_active_snapshot
      CurrencyRateModeSnapshot.status_active.first ||  CurrencyRateModeSnapshot.create!(status: :active).create_modes!
    end

    def modes_by_pair
      @modes_by_pair ||= build_modes_by_pair
    end

    def build_modes_by_pair
      snapshot.currency_rate_modes.each_with_object({}) { |crm, modes| modes[crm.currency_pair.key] = crm }
    end
  end
end
