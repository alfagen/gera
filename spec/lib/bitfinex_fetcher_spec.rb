# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BitfinexFetcher, type: :services, vcr: true do
    # Примеры ответов
    #  {"mid":"0.00408895","bid":"0.0040889","ask":"0.004089","last_price":"0.0040889","low":"0.0040562","high":"0.0041476","volume":"7406.62321845","timestamp":"1532882027.7319012"}
    #  {"mid":"8228.25","bid":"8228.2","ask":"8228.3","last_price":"8228.3","low":"8055.0","high":"8313.3","volume":"13611.826947359996","timestamp":"1532874580.9087598"}

    subject { described_class.new(ticker: 'neousd').perform }

    it do
      expect(subject).to be_a Hash
      expect(subject['low']).to be_present
    end
  end
end
