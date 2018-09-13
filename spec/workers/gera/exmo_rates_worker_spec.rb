require 'rails_helper'

describe EXMORatesWorker do
  before do
    create :rate_source, :exmo
    create :rate_source, :cbr_avg
    create :rate_source, :cbr
    create :rate_source, :manual
  end

  it do
    expect( CurrencyRate.count ).to be_zero
    VCR.use_cassette :exmo do
      expect( EXMORatesWorker.new.perform ).to be_truthy
    end
    expect( CurrencyRate.count ).to eq 134
  end
end
