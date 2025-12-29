# frozen_string_literal: true

# Standalone тесты для калькуляторов автокурса
# Не требуют полной загрузки Rails

require 'virtus'

# Загружаем только необходимые файлы
require_relative '../../../../app/services/gera/autorate_calculators/base'
require_relative '../../../../app/services/gera/autorate_calculators/legacy'
require_relative '../../../../app/services/gera/autorate_calculators/position_aware'

RSpec.describe 'AutorateCalculators' do
  let(:exchange_rate) { double('ExchangeRate') }
  let(:target_autorate_setting) { double('TargetAutorateSetting') }

  before do
    allow(exchange_rate).to receive(:target_autorate_setting).and_return(target_autorate_setting)
    allow(exchange_rate).to receive(:autorate_from).and_return(1.0)
    allow(exchange_rate).to receive(:autorate_to).and_return(3.0)
    allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
  end

  describe Gera::AutorateCalculators::Legacy do
    let(:calculator) do
      described_class.new(
        exchange_rate: exchange_rate,
        external_rates: external_rates
      )
    end

    context 'с валидными rates' do
      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 2.5),
          double('ExternalRate', target_rate_percent: 2.8),
          double('ExternalRate', target_rate_percent: 3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
      end

      it 'вычитает GAP из первого matching rate' do
        expect(calculator.call).to eq(2.5 - 0.0001)
      end
    end

    context 'когда rates пустые' do
      let(:external_rates) { [] }

      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
      end

      it 'возвращает autorate_from' do
        expect(calculator.call).to eq(1.0)
      end
    end
  end

  describe Gera::AutorateCalculators::PositionAware do
    let(:calculator) do
      described_class.new(
        exchange_rate: exchange_rate,
        external_rates: external_rates
      )
    end

    context 'UC-1: все позиции имеют одинаковый курс' do
      let(:external_rates) do
        10.times.map { double('ExternalRate', target_rate_percent: 2.5) }
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(10)
      end

      it 'не перепрыгивает позицию выше, возвращает ту же комиссию' do
        # Позиция 4 имеет 2.5, после GAP было бы 2.499 < 2.5 - перепрыгнем!
        # PositionAware должен вернуть 2.5
        expect(calculator.call).to eq(2.5)
      end
    end

    context 'UC-2: есть разрыв между позициями' do
      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 1.0),
          double('ExternalRate', target_rate_percent: 1.2),
          double('ExternalRate', target_rate_percent: 1.4),
          double('ExternalRate', target_rate_percent: 1.6),
          double('ExternalRate', target_rate_percent: 2.5),
          double('ExternalRate', target_rate_percent: 2.6),
          double('ExternalRate', target_rate_percent: 2.7),
          double('ExternalRate', target_rate_percent: 2.8),
          double('ExternalRate', target_rate_percent: 2.9),
          double('ExternalRate', target_rate_percent: 3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(10)
      end

      it 'безопасно вычитает GAP когда есть разрыв' do
        # 2.5 - 0.0001 = 2.4999 > 1.6 - не перепрыгиваем
        expect(calculator.call).to eq(2.5 - 0.0001)
      end
    end

    context 'UC-3: целевая позиция 1' do
      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 2.5),
          double('ExternalRate', target_rate_percent: 2.8),
          double('ExternalRate', target_rate_percent: 3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
      end

      it 'вычитает GAP когда нет позиции выше' do
        expect(calculator.call).to eq(2.5 - 0.0001)
      end
    end

    context 'UC-4: позиция выше с очень близкой комиссией' do
      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 1.0),
          double('ExternalRate', target_rate_percent: 1.5),
          double('ExternalRate', target_rate_percent: 2.0),
          double('ExternalRate', target_rate_percent: 2.4999),
          double('ExternalRate', target_rate_percent: 2.5),
          double('ExternalRate', target_rate_percent: 2.8)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(6)
      end

      it 'не перепрыгивает позицию 4' do
        # 2.5 - 0.0001 = 2.4999 = 2.4999, курсы равны
        # Возвращаем 2.4999 (равный позиции выше)
        expect(calculator.call).to eq(2.4999)
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
          # target = 2.5 - GAP = 2.4999
          # rate_above (pos 1) = 0.5, 2.4999 > 0.5 - не перепрыгиваем
          expect(calculator.call).to eq(2.5 - 0.0001)
        end
      end
    end
  end
end
