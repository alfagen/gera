FactoryBot.define do
  factory :external_rate, class: GERA::ExternalRate do
    bank_id { 1 }
    cur_from { "MyString" }
    cur_to { "MyString" }
    rate { 1.5 }
    datetime { "2018-03-06 16:48:58" }
  end
end
