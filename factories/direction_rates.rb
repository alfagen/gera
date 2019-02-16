FactoryBot.define do
  factory :gera_direction_rate, class: 'Gera::DirectionRate' do
    association :exchange_rate, factory: :gera_exchange_rate, is_enabled: true
    association :snapshot, factory: :direction_rate_snapshot

    # Universe.currency_rates_repository.find_currency_rate_by_pair(exchange_rate.currency_pair)
    association :currency_rate, cur_from: Money::Currency.find('USD'), cur_to: Money::Currency.find('RUB')
    comission { 10 }
  end
end
