FactoryBot.define do
  sequence :title do |n|
   "rate_source_key#{n}"
  end

  sequence :key do |n|
   "rate_source_key#{n}"
  end

  factory :rate_source, class: GERA::RateSource do
    # initialize_with { GERA::ExchangeRate.find_or_create_by(key: key, title: title) }
    key { generate :key }
    title { generate :title }
  end
  factory :rate_source_manual, parent: :rate_source, class: GERA::RateSourceManual
  factory :rate_source_cbr, parent: :rate_source, class: GERA::RateSourceCBR
  factory :rate_source_cbr_avg, parent: :rate_source, class: GERA::RateSourceCBRAvg
  factory :rate_source_exmo, parent: :rate_source, class: GERA::RateSourceEXMO
end
