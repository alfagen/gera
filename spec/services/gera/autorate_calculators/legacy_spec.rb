# frozen_string_literal: true

require 'spec_helper'

module Gera
  module AutorateCalculators
    RSpec.describe Legacy do
      let(:exchange_rate) { double('ExchangeRate') }
      let(:target_autorate_setting) { double('TargetAutorateSetting') }
      let(:currency_rate) { double('CurrencyRate', rate_value: base_rate) }
      let(:base_rate) { 100.0 }

      let(:calculator) do
        described_class.new(
          exchange_rate: exchange_rate,
          external_rates: external_rates
        )
      end

      let(:external_rate_1) { { 'rate' => (base_rate * 0.975).to_s, 'changer_id' => 1 } }
      let(:external_rate_2) { { 'rate' => (base_rate * 0.972).to_s, 'changer_id' => 2 } }
      let(:external_rate_3) { { 'rate' => (base_rate * 0.969).to_s, 'changer_id' => 3 } }
      let(:external_rates) { [external_rate_1, external_rate_2, external_rate_3] }

      let(:calculator) do
        described_class.new(
          exchange_rate: exchange_rate,
          external_rates: external_rates
        )
      end

      before do
        allow(exchange_rate).to receive(:target_autorate_setting).and_return(target_autorate_setting)
        allow(exchange_rate).to receive(:currency_rate).and_return(currency_rate)
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
        allow(exchange_rate).to receive(:autorate_from).and_return(1.0)
        allow(exchange_rate).to receive(:autorate_to).and_return(3.0)
      end

      describe '#call' do
        context 'when could_be_calculated? is false' do
          before do
            allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(false)
          end

          it 'returns 0' do
            expect(calculator.call).to eq(0)
          end
        end

        context 'when external_rates is nil' do
          let(:external_rates) { nil }

          before do
            allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
          end

          it 'returns 0' do
            expect(calculator.call).to eq(0)
          end
        end

        context 'when external_rates_in_target_position is empty' do
          let(:external_rates) { [] }

          before do
            allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
          end

          it 'returns autorate_from' do
            expect(calculator.call).to eq(1.0)
          end
        end

        context 'when no rates match target comission range' do
          let(:external_rate_1) { { 'rate' => (base_rate * 0.95).to_s, 'changer_id' => 1 } }
          let(:external_rate_2) { { 'rate' => (base_rate * 0.94).to_s, 'changer_id' => 2 } }
          let(:external_rate_3) { { 'rate' => (base_rate * 0.93).to_s, 'changer_id' => 3 } }

          before do
            allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
          end

          it 'returns autorate_from' do
            expect(calculator.call).to eq(1.0)
          end
        end

        context 'when rates match target comission range' do
          before do
            allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
          end

          it 'returns first matching rate minus GAP' do
            # first matching rate commission is 2.5%, GAP is 0.001
            expect(calculator.call).to be_within(0.0001).of(2.5 - 0.001)
          end
        end
      end
    end
  end
end
