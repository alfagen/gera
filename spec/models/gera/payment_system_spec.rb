require 'spec_helper'

module Gera
  RSpec.describe PaymentSystem do
    before do
      allow(DirectionsRatesWorker).to receive(:perform_async)
    end
    subject { create :payment_system }
    it { expect(subject).to be_persisted }

    describe 'income_money_with_fee' do
      let(:base_amount) { 90 }
      context "regular comission" do
        it 'adds fee to base amount' do
          expect(subject).to receive(:calculate_total_using_regular_comission)
          subject.total_with_fee(base_amount)
        end
      end

      context "reverse comission" do
        before { subject.update(total_computation_method: :reverse_fee) }

         it 'substract fee from final amount' do
           expect(subject).to receive(:calculate_total_using_reverse_comission)
           subject.total_with_fee(base_amount)
        end
      end
    end
  end
end
