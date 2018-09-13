require 'rails_helper'

describe GERA::CurrencyRatesWorker do
  it do
    expect( GERA::CurrencyRatesWorker.new.perform ).to be_truthy
  end
end
