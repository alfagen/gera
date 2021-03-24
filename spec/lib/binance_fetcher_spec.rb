# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BinanceFetcher, type: :services, vcr: true do
    # Примеры ответа
    # {"symbol":"LTCBTC","priceChange":"-0.00002400","priceChangePercent":"-0.702","weightedAvgPrice":"0.00339802","prevClosePrice":"0.00342200","lastPrice":"0.00339700","lastQty":"2.21000000","bidPrice":"0.00339600","bidQty":"147.50000000","askPrice":"0.00339800","askQty":"146.60000000","openPrice":"0.00342100","highPrice":"0.00348700","lowPrice":"0.00327300","volume":"228476.78000000","quoteVolume":"776.36901097","openTime":1616459233596,"closeTime":1616545633596,"firstId":57208172,"lastId":57265292,"count":57121}

    subject { described_class.new(pair: CurrencyPair.new 'LTC_BTC').perform }

    it do
      expect(subject['highPrice']).to be_present
      expect(subject['lowPrice']).to be_present
    end
  end
end
