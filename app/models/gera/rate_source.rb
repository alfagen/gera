module GERA
  class RateSource < ApplicationRecord
    extend CurrencyPairGenerator
    RateNotFound = Class.new StandardError
    self.table_name = 'rate_sources'

    CBR_ID  = 1
    EXMO_ID = 2
    MANUAL_ID = 3
    CBR_AVG_ID = 4
    BITFINEX_ID = 5

    has_many :snapshots, class_name: 'ExternalRateSnapshot'
    has_many :external_rates, foreign_key: :source_id

    belongs_to :actual_snapshot, class_name: 'ExternalRateSnapshot', optional: true

    scope :ordered, -> { order :priority }
    scope :enabled, -> { where is_enabled: true }

    validates :key, presence: true, uniqueness: true

    before_create do
      self.priority ||= RateSource.maximum(:priority).to_i + 1 if self.class.attribute_names.include? 'priority'
    end

    # TODO Избавиться от шорткатов
    #
    def self.exmo
      find EXMO_ID
    end

    def self.cbr
      find CBR_ID
    end

    def self.cbr_avg
      find CBR_AVG_ID
    end

    def self.bitfinex
      find BITFINEX_ID
    end

    def self.manual
      find MANUAL_ID
    end

    def find_rate_by_currency_pair!(pair)
      find_rate_by_currency_pair(pair) || raise(RateNotFound, pair)
    end

    def find_rate_by_currency_pair(pair)
      actual_rates.find_by_currency_pair pair
    end

    def to_s
      name
    end

    def actual_rates
      external_rates.where(snapshot_id: actual_snapshot_id)
    end

    def to_s
      title
    end

    def is_currency_supported?(cur)
      cur = Money::Currency.find cur unless cur.is_a? Money::Currency
      supported_currencies.include? cur
    end

    def supported_currencies
      self.class::SUPPORTED_CURRENCIES.map { |c| Money::Currency.find! c }
    end

    def available_pairs
      self.class.available_pairs
    end

    private

    def validate_currency!(*curs)
      curs.each do |cur|
        raise "Источник #{self} не поддерживает валюту #{cur}" unless is_currency_supported? cur
      end
    end
  end
end
