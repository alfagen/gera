# frozen_string_literal: true

require 'spec_helper'

module Gera
  module AutorateCalculators
    RSpec.describe Legacy do
      let(:exchange_rate) { double('ExchangeRate') }
      let(:target_autorate_setting) { double('TargetAutorateSetting') }
      let(:external_rate_1) { double('ExternalRate', target_rate_percent: 2.5) }
      let(:external_rate_2) { double('ExternalRate', target_rate_percent: 2.8) }
      let(:external_rate_3) { double('ExternalRate', target_rate_percent: 3.1) }
      let(:external_rates) { [external_rate_1, external_rate_2, external_rate_3] }

      let(:calculator) do
        described_class.new(
          exchange_rate: exchange_rate,
          external_rates: external_rates
        )
      end

      before do
        allow(exchange_rate).to receive(:target_autorate_setting).and_return(target_autorate_setting)
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
          let(:external_rate_1) { double('ExternalRate', target_rate_percent: 5.0) }
          let(:external_rate_2) { double('ExternalRate', target_rate_percent: 6.0) }
          let(:external_rate_3) { double('ExternalRate', target_rate_percent: 7.0) }

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
            # first matching rate is 2.5, GAP is 0.0001
            expect(calculator.call).to eq(2.5 - 0.0001)
          end
        end

        # UC-5: Диапазон позиций не совпадает с диапазоном курсов
        # Реализован вариант A: возвращаем autorate_from (минимально допустимую комиссию)
        # и занимаем позицию ниже целевого диапазона
        describe 'UC-5: диапазон позиций не совпадает с диапазоном курсов (Вариант A)' do
          before do
            allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
          end

          context 'курсы конкурентов выше допустимого диапазона' do
            # autorate_from..autorate_to = 1.0..3.0
            # Курсы на позициях 1-3: 4.0, 4.5, 5.0 (все выше 3.0)
            # Ожидаемый результат: autorate_from = 1.0

            let(:external_rate_1) { double('ExternalRate', target_rate_percent: 4.0) }
            let(:external_rate_2) { double('ExternalRate', target_rate_percent: 4.5) }
            let(:external_rate_3) { double('ExternalRate', target_rate_percent: 5.0) }

            it 'возвращает autorate_from (вариант A)' do
              expect(calculator.call).to eq(1.0)
            end
          end

          context 'курсы конкурентов ниже допустимого диапазона' do
            # autorate_from..autorate_to = 1.0..3.0
            # Курсы на позициях 1-3: -0.5, -0.3, -0.1 (все ниже 1.0)
            # Мы не можем им соответствовать, возвращаем autorate_from

            let(:external_rate_1) { double('ExternalRate', target_rate_percent: -0.5) }
            let(:external_rate_2) { double('ExternalRate', target_rate_percent: -0.3) }
            let(:external_rate_3) { double('ExternalRate', target_rate_percent: -0.1) }

            it 'возвращает autorate_from (вариант A)' do
              expect(calculator.call).to eq(1.0)
            end
          end

          context 'нет курсов на целевых позициях (список короче)' do
            # position_from..position_to = 5..10
            # Но в списке только 3 позиции

            before do
              allow(exchange_rate).to receive(:position_from).and_return(5)
              allow(exchange_rate).to receive(:position_to).and_return(10)
            end

            it 'возвращает autorate_from (вариант A)' do
              expect(calculator.call).to eq(1.0)
            end
          end

          context 'частичное совпадение: только некоторые позиции вне диапазона' do
            # autorate_from..autorate_to = 1.0..3.0
            # Позиция 1: 4.0 (вне диапазона)
            # Позиция 2: 2.5 (в диапазоне)
            # Должен использовать курс с позиции 2

            let(:external_rate_1) { double('ExternalRate', target_rate_percent: 4.0) }
            let(:external_rate_2) { double('ExternalRate', target_rate_percent: 2.5) }
            let(:external_rate_3) { double('ExternalRate', target_rate_percent: 2.8) }

            it 'использует первый подходящий курс в диапазоне' do
              # valid_rates = [2.5, 2.8]
              # target = 2.5 - GAP = 2.4999
              expect(calculator.call).to eq(2.5 - 0.0001)
            end
          end
        end

        context 'когда target_autorate_setting равен nil' do
          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 2.5),
              double('ExternalRate', target_rate_percent: 2.6)
            ]
          end

          before do
            allow(exchange_rate).to receive(:target_autorate_setting).and_return(nil)
            allow(exchange_rate).to receive(:position_from).and_return(1)
            allow(exchange_rate).to receive(:position_to).and_return(3)
          end

          it 'возвращает 0 (could_be_calculated? = false)' do
            expect(calculator.call).to eq(0)
          end
        end
      end
    end
  end
end
