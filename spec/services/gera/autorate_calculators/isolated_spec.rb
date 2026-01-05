# frozen_string_literal: true

# Полностью изолированные тесты - не загружают Rails и spec_helper

require 'rspec'
require 'virtus'

# Загружаем только необходимые файлы
$LOAD_PATH.unshift File.expand_path('../../../../app/services', __dir__)
$LOAD_PATH.unshift File.expand_path('../../../../lib', __dir__)

require 'gera/autorate_calculators/base'
require 'gera/autorate_calculators/legacy'
require 'gera/autorate_calculators/position_aware'

# Stub для Gera модуля - настройки конфигурации
module Gera
  class << self
    attr_accessor :our_exchanger_id, :autorate_debug_enabled
  end
end

RSpec.describe 'AutorateCalculators (isolated)' do
  let(:exchange_rate) { double('ExchangeRate') }
  let(:target_autorate_setting) { double('TargetAutorateSetting') }

  before do
    allow(exchange_rate).to receive(:target_autorate_setting).and_return(target_autorate_setting)
    allow(exchange_rate).to receive(:autorate_from).and_return(1.0)
    allow(exchange_rate).to receive(:autorate_to).and_return(3.0)
    allow(exchange_rate).to receive(:id).and_return(1)
    allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
    # Сбрасываем конфигурацию Gera
    Gera.our_exchanger_id = nil
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

    # UC-5: Диапазон позиций не совпадает с диапазоном курсов
    # Реализован вариант A: возвращаем autorate_from
    describe 'UC-5: диапазон позиций не совпадает с диапазоном курсов (Вариант A)' do
      context 'курсы конкурентов выше допустимого диапазона' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 4.0),
            double('ExternalRate', target_rate_percent: 4.5),
            double('ExternalRate', target_rate_percent: 5.0)
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(1)
          allow(exchange_rate).to receive(:position_to).and_return(3)
        end

        it 'возвращает autorate_from (вариант A)' do
          expect(calculator.call).to eq(1.0)
        end
      end

      context 'курсы конкурентов ниже допустимого диапазона' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: -0.5),
            double('ExternalRate', target_rate_percent: -0.3),
            double('ExternalRate', target_rate_percent: -0.1)
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(1)
          allow(exchange_rate).to receive(:position_to).and_return(3)
        end

        it 'возвращает autorate_from (вариант A)' do
          expect(calculator.call).to eq(1.0)
        end
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
          # target = 2.5 - GAP = 2.499
          # rate_above (pos 1) = 0.5, 2.499 > 0.5 - не перепрыгиваем
          expect(calculator.call).to eq(2.5 - 0.0001)
        end
      end
    end

    # UC-12: Не вычитать GAP при одинаковых курсах (для любого position_from)
    describe 'UC-12: пропуск GAP при одинаковых курсах' do
      context 'position_from=1, одинаковые курсы на позициях 1 и 2' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 1),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 2),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 3)
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(1)
          allow(exchange_rate).to receive(:position_to).and_return(3)
        end

        it 'возвращает курс без GAP' do
          expect(calculator.call).to eq(2.5)
        end
      end

      context 'position_from=2, одинаковые курсы на позициях 1 и 2' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 1),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 2),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 3)
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(2)
          allow(exchange_rate).to receive(:position_to).and_return(3)
        end

        it 'возвращает курс без GAP' do
          expect(calculator.call).to eq(2.5)
        end
      end

      context 'position_from=3, одинаковые курсы на позициях 2 и 3' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 2.0, exchanger_id: 1),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 2),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 3),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 4)
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(3)
          allow(exchange_rate).to receive(:position_to).and_return(4)
        end

        it 'возвращает курс без GAP' do
          expect(calculator.call).to eq(2.5)
        end
      end

      context 'position_from=5, одинаковые курсы на позициях 4 и 5' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 1.0, exchanger_id: 1),
            double('ExternalRate', target_rate_percent: 1.5, exchanger_id: 2),
            double('ExternalRate', target_rate_percent: 2.0, exchanger_id: 3),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 4),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 5),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 6)
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(5)
          allow(exchange_rate).to receive(:position_to).and_return(6)
        end

        it 'возвращает курс без GAP' do
          expect(calculator.call).to eq(2.5)
        end
      end

      context 'position_from=2, РАЗНЫЕ курсы на позициях 1 и 2' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 2.0, exchanger_id: 1),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 2),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 3)
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(2)
          allow(exchange_rate).to receive(:position_to).and_return(3)
        end

        it 'вычитает GAP так как курсы разные' do
          # target_rate = 2.5, rate_above = 2.0
          # diff = 0.5 > AUTO_COMISSION_GAP, используем стандартный GAP
          # target_comission = 2.5 - 0.0001 = 2.4999
          # 2.4999 > 2.0, не перепрыгиваем
          expect(calculator.call).to eq(2.5 - 0.0001)
        end
      end
    end

    # UC-14: Fallback на первую целевую позицию при отсутствии rate_above (issue #83)
    # При position_from > 1 и rate_above = nil — ВСЕГДА занимаем первую целевую позицию
    describe 'UC-14: fallback при отсутствии rate_above' do
      context 'когда rate_above = nil (разреженный список)' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 1.0),   # pos 1
            double('ExternalRate', target_rate_percent: 1.5),   # pos 2
            double('ExternalRate', target_rate_percent: 2.0),   # pos 3
            nil,                                                 # pos 4 - отсутствует
            double('ExternalRate', target_rate_percent: 2.5),   # pos 5
            double('ExternalRate', target_rate_percent: 2.6),   # pos 6
            double('ExternalRate', target_rate_percent: 2.7)    # pos 7
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(5)
          allow(exchange_rate).to receive(:position_to).and_return(7)
        end

        it 'всегда использует курс первой целевой позиции' do
          # rate_above = rates[3] = nil
          # UC-14: ВСЕГДА используем first_target_rate = rates[4] = 2.5
          expect(calculator.call).to eq(2.5)
        end
      end

      context 'когда rate_above = nil (другой пример)' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 1.0),   # pos 1
            double('ExternalRate', target_rate_percent: 1.5),   # pos 2
            double('ExternalRate', target_rate_percent: 2.0),   # pos 3
            nil,                                                 # pos 4 - отсутствует
            double('ExternalRate', target_rate_percent: 2.4),   # pos 5
            double('ExternalRate', target_rate_percent: 2.6)    # pos 6
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(5)
          allow(exchange_rate).to receive(:position_to).and_return(6)
        end

        it 'всегда использует курс первой целевой позиции' do
          # rate_above = rates[3] = nil
          # UC-14: ВСЕГДА используем first_target_rate = rates[4] = 2.4
          expect(calculator.call).to eq(2.4)
        end
      end

      context 'когда first_target_rate вне допустимого диапазона' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 1.0),   # pos 1
            double('ExternalRate', target_rate_percent: 1.5),   # pos 2
            nil,                                                 # pos 3 - отсутствует
            double('ExternalRate', target_rate_percent: 5.0),   # pos 4 - вне диапазона
            double('ExternalRate', target_rate_percent: 5.5)    # pos 5
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(4)
          allow(exchange_rate).to receive(:position_to).and_return(5)
        end

        it 'возвращает autorate_from' do
          # valid_rates пуст (5.0 и 5.5 > 3.0)
          expect(calculator.call).to eq(1.0)
        end
      end

      context 'когда rate_above = nil И first_target вне диапазона, но valid_rates не пуст' do
        # Edge case: first_target_rate (для fallback) вне диапазона,
        # но valid_rates содержит другие позиции в диапазоне
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 1.0),   # pos 1
            double('ExternalRate', target_rate_percent: 1.5),   # pos 2
            double('ExternalRate', target_rate_percent: 2.0),   # pos 3
            nil,                                                 # pos 4 - отсутствует (rate_above)
            double('ExternalRate', target_rate_percent: 5.0),   # pos 5 - first_target, но вне диапазона!
            double('ExternalRate', target_rate_percent: 2.5),   # pos 6 - в диапазоне
            double('ExternalRate', target_rate_percent: 2.8)    # pos 7 - в диапазоне
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(5)
          allow(exchange_rate).to receive(:position_to).and_return(7)
        end

        it 'возвращает autorate_from так как first_target_rate вне диапазона' do
          # valid_rates = [2.5, 2.8] (после фильтрации по диапазону)
          # target_rate = 2.5
          # rate_above = rates[3] = nil → fallback
          # UC-14: first_target_rate = rates[4] = 5.0 (ВНЕ диапазона 1.0..3.0!)
          # Должен вернуть autorate_from = 1.0
          expect(calculator.call).to eq(1.0)
        end
      end

      context 'когда rate_above = nil И first_target_rate = nil' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 1.0),   # pos 1
            double('ExternalRate', target_rate_percent: 1.5),   # pos 2
            double('ExternalRate', target_rate_percent: 2.0),   # pos 3
            nil,                                                 # pos 4 - отсутствует (rate_above)
            nil,                                                 # pos 5 - целевая, но nil
            double('ExternalRate', target_rate_percent: 2.6)    # pos 6
          ]
        end

        before do
          allow(exchange_rate).to receive(:position_from).and_return(5)
          allow(exchange_rate).to receive(:position_to).and_return(6)
        end

        it 'возвращает autorate_from (first_target_rate = nil)' do
          # rates_in_target_position = [nil, 2.6]
          # valid_rates = [2.6] (после compact)
          # target_rate = 2.6, rate_above = rates[3] = nil
          # UC-14: first_target_rate = rates[4] = nil → возвращаем autorate_from
          expect(calculator.call).to eq(1.0)
        end
      end
    end

    # UC-6: Адаптивный GAP для плотных рейтингов
    describe 'UC-6: адаптивный GAP для плотных рейтингов' do
      before do
        allow(exchange_rate).to receive(:position_from).and_return(3)
        allow(exchange_rate).to receive(:position_to).and_return(5)
        allow(exchange_rate).to receive(:autorate_from).and_return(1.0)
        allow(exchange_rate).to receive(:autorate_to).and_return(3.0)
      end

      context 'когда разница между позициями меньше стандартного GAP' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 2.0, exchanger_id: 100),
            double('ExternalRate', target_rate_percent: 2.00003, exchanger_id: 101), # rate_above
            double('ExternalRate', target_rate_percent: 2.00005, exchanger_id: 102), # target_rate (позиция 3)
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 103),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 104)
          ]
        end

        it 'использует MIN_GAP когда diff/2 <= MIN_GAP' do
          # diff = 2.00005 - 2.00003 = 0.00002
          # adaptive_gap = max(0.00002 / 2, MIN_GAP) = max(0.00001, 0.00001) = 0.00001 (MIN_GAP)
          # target_comission = 2.00005 - 0.00001 = 1.99994, округляется до 1.9999
          # adjust_for_position_above: 1.9999 < 2.00003? Да → корректируем до 2.00003
          # round(2.00003, 4) = 2.0
          expect(calculator.call).to eq(2.0)
        end
      end

      context 'когда разница достаточна для адаптивного GAP' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 2.0, exchanger_id: 100),
            double('ExternalRate', target_rate_percent: 2.0005, exchanger_id: 101), # rate_above
            double('ExternalRate', target_rate_percent: 2.001, exchanger_id: 102), # target_rate
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 103),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 104)
          ]
        end

        it 'использует стандартный GAP когда diff >= AUTO_COMISSION_GAP' do
          # diff = 2.001 - 2.0005 = 0.0005 >= AUTO_COMISSION_GAP (0.0001)
          # Адаптивный режим НЕ используется, gap = AUTO_COMISSION_GAP = 0.0001
          # Результат = 2.001 - 0.0001 = 2.0009
          expect(calculator.call).to eq(2.0009)
        end
      end

      context 'когда position_from = 1 (нет позиции выше)' do
        before do
          allow(exchange_rate).to receive(:position_from).and_return(1)
          allow(exchange_rate).to receive(:position_to).and_return(3)
        end

        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 100),
            double('ExternalRate', target_rate_percent: 2.6, exchanger_id: 101),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 102)
          ]
        end

        it 'использует стандартный GAP' do
          # position_from = 1, используем стандартный AUTO_COMISSION_GAP = 0.0001
          expect(calculator.call).to eq(2.5 - 0.0001)
        end
      end
    end

    # UC-8: Исключение своего обменника из расчёта
    describe 'UC-8: исключение своего обменника из расчёта' do
      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
        allow(exchange_rate).to receive(:autorate_from).and_return(1.0)
        allow(exchange_rate).to receive(:autorate_to).and_return(3.0)
      end

      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 2.0, exchanger_id: 999), # наш обменник
          double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 100),
          double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 101)
        ]
      end

      context 'когда our_exchanger_id задан' do
        before do
          Gera.our_exchanger_id = 999
        end

        after do
          Gera.our_exchanger_id = nil
        end

        it 'исключает свой обменник и берёт следующий' do
          # Наш обменник (id=999) исключается
          # Следующий - 2.5, минус GAP = 2.4999
          expect(calculator.call).to eq(2.5 - 0.0001)
        end
      end

      context 'когда our_exchanger_id не задан' do
        before do
          Gera.our_exchanger_id = nil
        end

        it 'не исключает обменники' do
          # Берём первый - 2.0, минус GAP = 1.9999
          expect(calculator.call).to eq(2.0 - 0.0001)
        end
      end

      context 'когда rate содержит nil exchanger_id' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 2.0, exchanger_id: nil),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 100),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 101)
          ]
        end

        before do
          Gera.our_exchanger_id = 999
        end

        after do
          Gera.our_exchanger_id = nil
        end

        it 'не падает на nil exchanger_id' do
          # rate с nil exchanger_id не равен 999, поэтому не исключается
          expect(calculator.call).to eq(2.0 - 0.0001)
        end
      end
    end

    # UC-13: Защита от перепрыгивания позиции position_from - 1
    describe 'UC-13: защита от перепрыгивания позиции выше' do
      before do
        allow(exchange_rate).to receive(:position_from).and_return(3)
        allow(exchange_rate).to receive(:position_to).and_return(5)
        allow(exchange_rate).to receive(:autorate_from).and_return(1.0)
        allow(exchange_rate).to receive(:autorate_to).and_return(3.0)
      end

      context 'когда после вычитания GAP курс станет лучше позиции выше' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 1.5, exchanger_id: 100),
            double('ExternalRate', target_rate_percent: 2.0001, exchanger_id: 101), # rate_above
            double('ExternalRate', target_rate_percent: 2.0002, exchanger_id: 102), # target_rate
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 103),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 104)
          ]
        end

        it 'использует адаптивный GAP и не перепрыгивает' do
          # target_rate = 2.0002, rate_above = 2.0001
          # target_comission = 2.0002 - GAP (адаптивный)
          # diff = 2.0002 - 2.0001 = 0.0001
          # adaptive_gap = max(0.0001/2, MIN_GAP) = max(0.00005, 0.00001) = 0.00005
          # target_comission = 2.0002 - 0.00005 = 2.00015, round(4) = 2.0002
          # 2.0002 > 2.0001 → не перепрыгиваем
          expect(calculator.call).to eq(2.0002)
        end
      end

      context 'когда курс после GAP перепрыгнет позицию выше' do
        let(:external_rates) do
          [
            double('ExternalRate', target_rate_percent: 1.5, exchanger_id: 100),
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 101), # rate_above
            double('ExternalRate', target_rate_percent: 2.5, exchanger_id: 102), # target_rate (одинаковый)
            double('ExternalRate', target_rate_percent: 2.6, exchanger_id: 103),
            double('ExternalRate', target_rate_percent: 2.8, exchanger_id: 104)
          ]
        end

        it 'не вычитает GAP при одинаковых курсах (UC-12)' do
          # UC-12: курсы одинаковые, GAP не вычитаем
          expect(calculator.call).to eq(2.5)
        end
      end
    end
  end
end
