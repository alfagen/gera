# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExchangeRate do
    before do
      allow(DirectionsRatesWorker).to receive(:perform_async)
    end
    subject { create :gera_exchange_rate }
    it { expect(subject).to be_persisted }
  end
end
