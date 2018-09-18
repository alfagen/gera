require 'spec_helper'

module Gera
  RSpec.describe CurrencyPair do
    let(:cp1) { CurrencyPair.new :usd, :rub }
    let(:cp2) { CurrencyPair.new 'USD_RUB' }
    let(:cp3) { CurrencyPair.new cur_from: Money::Currency.find(:usd), cur_to: Money::Currency.find(:rub) }

    it "identicaly" do
      expect(cp1).to eq cp2
      expect(cp3).to eq cp2

      h = {}
      h[cp1] = 1
      h[cp2] = 2
      h[cp3] = 3

      expect(h.count).to eq 1
    end
  end
end
