# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExchangeRate do
    before do
      allow(DirectionsRatesJob).to receive(:perform_later)
    end
    subject { create :gera_exchange_rate }
    it { expect(subject).to be_persisted }
  end
end
