require 'spec_helper'

module Gera
  RSpec.describe EXMORatesWorker do
    before do
      create :rate_source_exmo
      create :rate_source_cbr_avg
      create :rate_source_cbr
      create :rate_source_manual
    end

    it do
      expect( CurrencyRate.count ).to be_zero
      VCR.use_cassette :exmo do
        expect( EXMORatesWorker.new.perform ).to be_truthy
      end
      expect( CurrencyRate.count ).to eq 134
    end
  end
end
