require 'virtus'
require 'money'

module Gera
  # Валютная пара
  #
  class CurrencyPair
    include Virtus.value_object strict: true

    values do
      attribute :cur_from, Money::Currency
      attribute :cur_to,   Money::Currency
    end

    # Варианты:
    #
    # new cur_from: :rub, cur_to: usd
    # new :rub, :usd
    # new 'rub/usd'
    def initialize(*args)
      if args.first.is_a? Hash
        super(args.first).freeze

      elsif args.count ==1
        initialize(*args.first.split(/[\/_-]/)).freeze

      elsif args.count == 2
        super(cur_from: args[0], cur_to: args[1]).freeze

      else
        raise "WTF? #{args}"
      end
    end

    delegate :include?, :first, :last, :second, :join, to: :to_a

    def self.all
      @all ||= Money::Currency.all.each_with_object([]) { |cur_from, list|
        Money::Currency.all.each { |cur_to| list << CurrencyPair.new(cur_from, cur_to) }
      }.freeze
    end

    def inspect
      to_s
    end

    def inverse
      self.class.new cur_to, cur_from
    end

    def cur_to=(value)
      if value.is_a? Money::Currency
        super value
      else
        super Money::Currency.find(value) || raise("Не известная валюта #{value} в cur_to")
      end
    end

    def cur_from=(value)
      if value.is_a? Money::Currency
        super value
      else
        super Money::Currency.find(value) || raise("Не известная валюта #{value} в cur_from")
      end
    end

    def change_to(cur)
      CurrencyPair.new cur_from, cur
    end

    def change_from(cur)
      CurrencyPair.new cur, cur_to
    end

    def same?
      cur_from == cur_to
    end

    def to_a
      [cur_from, cur_to]
    end

    # Для людей
    def to_s
      join '/'
    end

    # Для машин
    def key
      join '_'
    end
  end
end
