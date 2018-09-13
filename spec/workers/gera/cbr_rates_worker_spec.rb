require 'rails_helper'

describe CBRRatesWorker do
  before do
    create :rate_source, :exmo
    create :rate_source, :cbr_avg
    create :rate_source, :cbr
  end
  let(:today) { Date.parse '13/03/2018' }
  it do
    expect(ExternalRate.count).to be_zero

    # На teamcity почему-то дата возвращается как 2018-03-12
    allow(Date).to receive(:today).and_return today
    Timecop.freeze(today) do
      VCR.use_cassette :cbrf do
        expect(CBRRatesWorker.new.perform).to be_truthy
      end
    end

    expect(ExternalRate.count).to eq 12
  end
end
