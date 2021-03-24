FactoryBot.define do
  sequence :title do |n|
   "rate_source_key#{n}"
  end

  sequence :key do |n|
   "rate_source_key#{n}"
  end

  factory :rate_source, class: Gera::RateSource do
    # initialize_with { Gera::ExchangeRate.find_or_create_by(key: key, title: title) }
    key { generate :key }
    title { generate :title }
  end
  factory :rate_source_manual, parent: :rate_source, class: Gera::RateSourceManual
  factory :rate_source_cbr, parent: :rate_source, class: Gera::RateSourceCBR
  factory :rate_source_cbr_avg, parent: :rate_source, class: Gera::RateSourceCBRAvg
  factory :rate_source_exmo, parent: :rate_source, class: Gera::RateSourceEXMO
  factory :rate_source_bitfinex, parent: :rate_source, class: Gera::RateSourceBitfinex
  factory :rate_source_binance, parent: :rate_source, class: Gera::RateSourceBinance
end
