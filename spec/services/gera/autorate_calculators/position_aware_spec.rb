# frozen_string_literal: true

require 'spec_helper'

module Gera
  module AutorateCalculators
    RSpec.describe PositionAware do
      let(:exchange_rate) { double('ExchangeRate') }
      let(:target_autorate_setting) { double('TargetAutorateSetting') }

      let(:calculator) do
        described_class.new(
          exchange_rate: exchange_rate,
          external_rates: external_rates
        )
      end

      before do
        allow(exchange_rate).to receive(:target_autorate_setting).and_return(target_autorate_setting)
        allow(exchange_rate).to receive(:autorate_from).and_return(1.0)
        allow(exchange_rate).to receive(:autorate_to).and_return(3.0)
        allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
        # Сбрасываем конфигурацию перед каждым тестом
        Gera.our_exchanger_id = nil
        Gera.anomaly_threshold_percent = 50.0
      end

      describe '#call' do
        context 'UC-1: все позиции имеют одинаковый курс' do
          # Позиции 1-10 все имеют комиссию 2.5
          # position_from: 5, position_to: 10
          # Legacy вычтет GAP и займёт позицию 1
          # PositionAware должен оставить 2.5 и занять позицию 5-10

          let(:external_rates) do
            10.times.map { double('ExternalRate', target_rate_percent: 2.5) }
          end

          before do
            allow(exchange_rate).to receive(:position_from).and_return(5)
            allow(exchange_rate).to receive(:position_to).and_return(10)
          end

          it 'не перепрыгивает позицию выше' do
            # Позиция 4 (index 3) имеет комиссию 2.5
            # Если мы вычтем GAP (2.5 - 0.001 = 2.499), мы станем выше позиции 4
            # PositionAware должен вернуть 2.5 (равную позиции выше)
            expect(calculator.call).to eq(2.5)
          end
        end

        context 'UC-2: есть разрыв между позициями' do
          # Позиции 1-4 имеют комиссии 1.0, 1.2, 1.4, 1.6
          # Позиции 5-10 имеют комиссии 2.5, 2.6, 2.7, 2.8, 2.9, 3.0
          # position_from: 5, position_to: 10
          # После вычитания GAP (2.5 - 0.001 = 2.499) мы всё ещё хуже чем позиция 4 (1.6)
          # Поэтому безопасно занимать позицию 5

          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 1.0), # pos 1
              double('ExternalRate', target_rate_percent: 1.2), # pos 2
              double('ExternalRate', target_rate_percent: 1.4), # pos 3
              double('ExternalRate', target_rate_percent: 1.6), # pos 4
              double('ExternalRate', target_rate_percent: 2.5), # pos 5
              double('ExternalRate', target_rate_percent: 2.6), # pos 6
              double('ExternalRate', target_rate_percent: 2.7), # pos 7
              double('ExternalRate', target_rate_percent: 2.8), # pos 8
              double('ExternalRate', target_rate_percent: 2.9), # pos 9
              double('ExternalRate', target_rate_percent: 3.0)  # pos 10
            ]
          end

          before do
            allow(exchange_rate).to receive(:position_from).and_return(5)
            allow(exchange_rate).to receive(:position_to).and_return(10)
          end

          it 'безопасно вычитает GAP' do
            # 2.5 - 0.001 = 2.499 > 1.6 (позиция 4)
            # Не перепрыгиваем, возвращаем target - GAP
            expect(calculator.call).to eq(2.5 - 0.001)
          end
        end

        context 'UC-3: целевая позиция 1' do
          # Когда position_from = 1, нет позиции выше
          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 2.5), # pos 1
              double('ExternalRate', target_rate_percent: 2.8), # pos 2
              double('ExternalRate', target_rate_percent: 3.0)  # pos 3
            ]
          end

          before do
            allow(exchange_rate).to receive(:position_from).and_return(1)
            allow(exchange_rate).to receive(:position_to).and_return(3)
          end

          it 'безопасно вычитает GAP' do
            expect(calculator.call).to eq(2.5 - 0.001)
          end
        end

        context 'UC-4: позиция выше с очень близкой комиссией' do
          # Позиция 4 имеет комиссию 2.4999
          # Позиция 5 имеет комиссию 2.5
          # 2.5 - 0.001 = 2.499 > 2.4999 - мы перепрыгнем!
          # PositionAware должен скорректировать

          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 1.0),    # pos 1
              double('ExternalRate', target_rate_percent: 1.5),    # pos 2
              double('ExternalRate', target_rate_percent: 2.0),    # pos 3
              double('ExternalRate', target_rate_percent: 2.4999), # pos 4
              double('ExternalRate', target_rate_percent: 2.5),    # pos 5
              double('ExternalRate', target_rate_percent: 2.8)     # pos 6
            ]
          end

          before do
            allow(exchange_rate).to receive(:position_from).and_return(5)
            allow(exchange_rate).to receive(:position_to).and_return(6)
          end

          it 'не перепрыгивает позицию 4' do
            # 2.5 - 0.001 = 2.499 < 2.4999, значит перепрыгнем
            # Должны вернуть min(2.4999, 2.5) = 2.4999
            expect(calculator.call).to eq(2.4999)
          end
        end

        context 'UC-6: адаптивный GAP для плотного рейтинга' do
          # Разница между позициями 4 и 5 = 0.0005 (меньше стандартного GAP 0.001)
          # Должен использоваться адаптивный GAP = 0.0005 / 2 = 0.00025

          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 1.0),      # pos 1
              double('ExternalRate', target_rate_percent: 1.5),      # pos 2
              double('ExternalRate', target_rate_percent: 2.0),      # pos 3
              double('ExternalRate', target_rate_percent: 2.4995),   # pos 4
              double('ExternalRate', target_rate_percent: 2.5),      # pos 5
              double('ExternalRate', target_rate_percent: 2.8)       # pos 6
            ]
          end

          before do
            allow(exchange_rate).to receive(:position_from).and_return(5)
            allow(exchange_rate).to receive(:position_to).and_return(6)
          end

          it 'использует адаптивный GAP' do
            # diff = 2.5 - 2.4995 = 0.0005 < 0.001
            # adaptive_gap = 0.0005 / 2 = 0.00025
            # target = 2.5 - 0.00025 = 2.49975
            # 2.49975 > 2.4995 - не перепрыгиваем
            expect(calculator.call).to be_within(0.0000001).of(2.49975)
          end
        end

        context 'UC-6: минимальный GAP' do
          # Разница между позициями очень маленькая (0.00005)
          # Должен использоваться MIN_GAP = 0.0001

          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 1.0),       # pos 1
              double('ExternalRate', target_rate_percent: 1.5),       # pos 2
              double('ExternalRate', target_rate_percent: 2.0),       # pos 3
              double('ExternalRate', target_rate_percent: 2.49995),   # pos 4
              double('ExternalRate', target_rate_percent: 2.5),       # pos 5
              double('ExternalRate', target_rate_percent: 2.8)        # pos 6
            ]
          end

          before do
            allow(exchange_rate).to receive(:position_from).and_return(5)
            allow(exchange_rate).to receive(:position_to).and_return(6)
          end

          it 'использует минимальный GAP' do
            # diff = 2.5 - 2.49995 = 0.00005
            # adaptive_gap = 0.00005 / 2 = 0.000025 < MIN_GAP (0.0001)
            # используем MIN_GAP = 0.0001
            # target = 2.5 - 0.0001 = 2.4999
            # 2.4999 < 2.49995 - перепрыгиваем! Корректируем до 2.49995
            expect(calculator.call).to eq(2.49995)
          end
        end

        context 'UC-8: наш обменник в рейтинге' do
          # Наш обменник на позиции 3, мы должны его игнорировать

          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 1.0, exchanger_id: 101), # pos 1
              double('ExternalRate', target_rate_percent: 1.5, exchanger_id: 102), # pos 2
              double('ExternalRate', target_rate_percent: 2.0, exchanger_id: 999), # pos 3 - наш
              double('ExternalRate', target_rate_percent: 2.3, exchanger_id: 103), # pos 4
              double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 104), # pos 5
              double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 105)  # pos 6
            ]
          end

          before do
            Gera.our_exchanger_id = 999
            allow(exchange_rate).to receive(:position_from).and_return(4)
            allow(exchange_rate).to receive(:position_to).and_return(5)
          end

          it 'исключает наш обменник из расчёта' do
            # После фильтрации: позиции пересчитываются без нашего обменника (id=999)
            # Новые позиции: 1.0, 1.5, 2.3, 2.5, 2.8
            # position_from=4 -> 2.5 (index 3)
            # position_to=5 -> 2.8 (index 4)
            # target = 2.5 - GAP = 2.499
            # rate_above (pos 3) = 2.3, 2.499 > 2.3 - не перепрыгиваем
            expect(calculator.call).to eq(2.5 - 0.001)
          end
        end

        context 'UC-9: манипуляторы с аномальными курсами' do
          # Позиции 1-3 имеют нереально низкие комиссии (манипуляторы)
          # Они должны игнорироваться при проверке перепрыгивания

          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 0.1),  # pos 1 - манипулятор
              double('ExternalRate', target_rate_percent: 0.2),  # pos 2 - манипулятор
              double('ExternalRate', target_rate_percent: 0.3),  # pos 3 - манипулятор
              double('ExternalRate', target_rate_percent: 2.0),  # pos 4 - нормальный
              double('ExternalRate', target_rate_percent: 2.5),  # pos 5
              double('ExternalRate', target_rate_percent: 2.6),  # pos 6
              double('ExternalRate', target_rate_percent: 2.7),  # pos 7
              double('ExternalRate', target_rate_percent: 2.8),  # pos 8
              double('ExternalRate', target_rate_percent: 2.9),  # pos 9
              double('ExternalRate', target_rate_percent: 3.0)   # pos 10
            ]
          end

          before do
            Gera.anomaly_threshold_percent = 50.0
            allow(exchange_rate).to receive(:position_from).and_return(5)
            allow(exchange_rate).to receive(:position_to).and_return(10)
          end

          it 'игнорирует манипуляторов при проверке перепрыгивания' do
            # Медиана комиссий ≈ 2.5
            # Комиссии 0.1, 0.2, 0.3 отклоняются от медианы > 50%
            # После фильтрации аномалий: 2.0, 2.5, 2.6, 2.7, 2.8, 2.9, 3.0
            # position_from=5 -> индекс 4 после фильтрации
            # rate_above в clean_rates = 2.8 (индекс 3)
            # target = 2.5 - 0.001 = 2.499 < 2.8 - не перепрыгиваем реальных конкурентов
            expect(calculator.call).to eq(2.5 - 0.001)
          end
        end

        context 'when external_rates is empty' do
          let(:external_rates) { [] }

          before do
            allow(exchange_rate).to receive(:position_from).and_return(1)
            allow(exchange_rate).to receive(:position_to).and_return(3)
          end

          it 'returns autorate_from' do
            expect(calculator.call).to eq(1.0)
          end
        end

        context 'when no rates match target comission range' do
          let(:external_rates) do
            [
              double('ExternalRate', target_rate_percent: 5.0),
              double('ExternalRate', target_rate_percent: 6.0),
              double('ExternalRate', target_rate_percent: 7.0)
            ]
          end

          before do
            allow(exchange_rate).to receive(:position_from).and_return(1)
            allow(exchange_rate).to receive(:position_to).and_return(3)
          end

          it 'returns autorate_from' do
            expect(calculator.call).to eq(1.0)
          end
        end

        # UC-5: Диапазон позиций не совпадает с диапазоном курсов
        # Реализован вариант A: возвращаем autorate_from (минимально допустимую комиссию)
        # и занимаем позицию ниже целевого диапазона
        describe 'UC-5: диапазон позиций не совпадает с диапазоном курсов (Вариант A)' do
          context 'курсы конкурентов выше допустимого диапазона' do
            # autorate_from..autorate_to = 1.0..3.0
            # Курсы на позициях 2-4: 4.0, 4.5, 5.0 (все выше 3.0)
            # Ожидаемый результат: autorate_from = 1.0

            let(:external_rates) do
              [
                double('ExternalRate', target_rate_percent: 3.5), # pos 1
                double('ExternalRate', target_rate_percent: 4.0), # pos 2
                double('ExternalRate', target_rate_percent: 4.5), # pos 3
                double('ExternalRate', target_rate_percent: 5.0), # pos 4
                double('ExternalRate', target_rate_percent: 5.5)  # pos 5
              ]
            end

            before do
              allow(exchange_rate).to receive(:position_from).and_return(2)
              allow(exchange_rate).to receive(:position_to).and_return(4)
            end

            it 'возвращает autorate_from (вариант A)' do
              expect(calculator.call).to eq(1.0)
            end
          end

          context 'курсы конкурентов ниже допустимого диапазона' do
            # autorate_from..autorate_to = 1.0..3.0
            # Курсы на позициях 2-4: -0.5, -0.3, -0.1 (все ниже 1.0)
            # Мы не можем им соответствовать, возвращаем autorate_from

            let(:external_rates) do
              [
                double('ExternalRate', target_rate_percent: -0.8), # pos 1
                double('ExternalRate', target_rate_percent: -0.5), # pos 2
                double('ExternalRate', target_rate_percent: -0.3), # pos 3
                double('ExternalRate', target_rate_percent: -0.1), # pos 4
                double('ExternalRate', target_rate_percent: 0.2)   # pos 5
              ]
            end

            before do
              allow(exchange_rate).to receive(:position_from).and_return(2)
              allow(exchange_rate).to receive(:position_to).and_return(4)
            end

            it 'возвращает autorate_from (вариант A)' do
              expect(calculator.call).to eq(1.0)
            end
          end

          context 'нет курсов на целевых позициях (список короче)' do
            # position_from..position_to = 5..10
            # Но в списке только 3 позиции

            let(:external_rates) do
              [
                double('ExternalRate', target_rate_percent: 2.0), # pos 1
                double('ExternalRate', target_rate_percent: 2.5), # pos 2
                double('ExternalRate', target_rate_percent: 3.0)  # pos 3
              ]
            end

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
            # Позиция 1: 0.5 (лучший курс, вне диапазона - ниже 1.0)
            # Позиция 2: 4.0 (вне диапазона - выше 3.0)
            # Позиция 3: 2.5 (в диапазоне)
            # Позиция 4: 2.8 (в диапазоне)
            # Должен использовать курс с позиции 3

            let(:external_rates) do
              [
                double('ExternalRate', target_rate_percent: 0.5), # pos 1 - лучший, но вне диапазона
                double('ExternalRate', target_rate_percent: 4.0), # pos 2 - вне диапазона
                double('ExternalRate', target_rate_percent: 2.5), # pos 3 - в диапазоне
                double('ExternalRate', target_rate_percent: 2.8), # pos 4 - в диапазоне
                double('ExternalRate', target_rate_percent: 5.0)  # pos 5
              ]
            end

            before do
              allow(exchange_rate).to receive(:position_from).and_return(2)
              allow(exchange_rate).to receive(:position_to).and_return(4)
            end

            it 'использует первый подходящий курс в диапазоне' do
              # valid_rates = [2.5, 2.8]
              # target = 2.5 - GAP = 2.499
              # rate_above (pos 1) = 0.5, 2.499 > 0.5 - не перепрыгиваем
              expect(calculator.call).to eq(2.5 - 0.001)
            end
          end
        end
      end
    end
  end
end
