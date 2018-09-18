module Gera
  module MoneySupport
    module CurrencyExtend
      # TODO Вынести в app
      attr_reader :local_id

      # TODO отказаться
      attr_reader :authorized_round

      # TODO Вынести в базу в app
      def minimal_output_value
        Money.from_amount @minimal_output_value, self
      end

      # TODO Вынести в базу в app
      def minimal_input_value
        Money.from_amount @minimal_input_value, self
      end

      def is_crypto?
        !!@is_crypto
      end

      def initialize_data!
        super

        data = self.class.table[@id]

        @is_crypto = data[:is_crypto]
        @local_id = data[:local_id]
        @minimal_input_value = data[:minimal_input_value]
        @minimal_output_value = data[:minimal_output_value]
        @authorized_round = data[:authorized_round]
      end
    end

    class ::Money::Currency
      prepend CurrencyExtend

      def self.find!(query)
        find(query) || raise("No found currency (#{query.inspect})")
      end

      # TODO Вынести в app
      #
      def self.find_by_local_id(local_id)
        local_id = local_id.to_i
        id, _ = self.table.find{|key, currency| currency[:local_id] == local_id}
        new(id)
      rescue UnknownCurrency
        nil
      end

      def self.all_crypto
        @all_crypto ||= all.select(&:is_crypto?)
      end

      def zero_money
        Money.from_amount(0, self)
      end
    end

    class ::Money
      # TODO Отказаться
      # Это сумма, до которой разрешено безопасное округление
      # при приеме суммы от клиента
      def authorized_round
        return self unless currency.authorized_round.is_a? Numeric
        Money.from_amount to_f.round(currency.authorized_round), currency
      end
    end
  end
end
