require 'spec_helper'

module GERA
  RSpec.describe ExchangeRate do
    before do
      allow(DirectionsRatesWorker).to receive(:perform_async)
    end
    subject { create :exchange_rate }
    it { expect(subject).to be_persisted }
  end
end
