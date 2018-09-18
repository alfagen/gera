require 'spec_helper'

module Gera
  RSpec.describe CurrencyRatesWorker do
    it do
      expect( CurrencyRatesWorker.new.perform ).to be_truthy
    end
  end
end
