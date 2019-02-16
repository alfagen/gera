# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe PaymentSystem do
    before do
      allow(DirectionsRatesWorker).to receive(:perform_async)
    end
    subject { create :gera_payment_system }
    it { expect(subject).to be_persisted }
  end
end
