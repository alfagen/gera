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
  factory :rate_source_cbr, parent: :rate_source, class: Gera::RateSourceCbr
  factory :rate_source_cbr_avg, parent: :rate_source, class: Gera::RateSourceCbrAvg
  factory :rate_source_exmo, parent: :rate_source, class: Gera::RateSourceExmo
  factory :rate_source_bitfinex, parent: :rate_source, class: Gera::RateSourceBitfinex
  factory :rate_source_binance, parent: :rate_source, class: Gera::RateSourceBinance
  factory :rate_source_bybit, parent: :rate_source, class: Gera::RateSourceBybit
  factory :rate_source_garantexio, parent: :rate_source, class: Gera::RateSourceGarantexio
  factory :rate_source_cryptomus, parent: :rate_source, class: Gera::RateSourceCryptomus
  factory :rate_source_ff_fixed, parent: :rate_source, class: Gera::RateSourceFfFixed
  factory :rate_source_ff_float, parent: :rate_source, class: Gera::RateSourceFfFloat
end
