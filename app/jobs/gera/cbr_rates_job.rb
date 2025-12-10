# frozen_string_literal: true

require 'business_time'

module Gera
  # Import rates from Russian Central Bank
  # http://www.cbr.ru/scripts/XML_daily.asp?date_req=08/04/2018
  #
  class CbrRatesJob < ApplicationJob
    include AutoLogger

    # limits_concurrency to: 1, key: -> { 'gera_cbr_rates' }, duration: 1.minute

    CURRENCIES = %w[USD KZT EUR UAH UZS AZN BYN TRY THB IDR].freeze

    CBR_IDS = {
      'USD' => 'R01235',
      'KZT' => 'R01335',
      'EUR' => 'R01239',
      'UAH' => 'R01720',
      'UZS' => 'R01717',
      'AZN' => 'R01020A',
      'BYN' => 'R01090B',
      'TRY' => 'R01700J',
      'THB' => 'R01675',
      'IDR' => 'R01280'
    }.freeze

    ROUND = 15

    Error = Class.new StandardError
    WrongDate = Class.new Error

    URL = 'https://pay.hub.pp.ru/api/cbr'

    def perform
      logger.debug 'CbrRatesJob: before perform'
      ActiveRecord::Base.connection.clear_query_cache
      rates_by_date = load_rates
      logger.debug 'CbrRatesJob: before transaction'
      ActiveRecord::Base.transaction do
        rates_by_date.each do |date, rates|
          save_rates(date, rates)
        end
      end
      logger.debug 'CbrRatesJob: after transaction'
      make_snapshot
      logger.debug 'CbrRatesJob: after perform'
    end

    private

    def currencies
      @currencies ||= CURRENCIES.map { |iso_code| Money::Currency.find! iso_code }
    end

    def snapshot
      @snapshot ||= cbr.snapshots.create!
    end

    def avg_snapshot
      @avg_snapshot ||= cbr_avg.snapshots.create!
    end

    def make_snapshot
      save_snapshot_rates

      cbr.update_column :actual_snapshot_id, snapshot.id
      cbr_avg.update_column :actual_snapshot_id, avg_snapshot.id
    end

    def save_snapshot_rates
      CURRENCIES.each { |cur_from| save_snapshot_rate(cur_from.constantize, RUB) }
    end

    def save_snapshot_rate(cur_from, cur_to)
      pair = Gera::CurrencyPair.new cur_from, cur_to

      min_rate, max_rate = Gera::CbrExternalRate
                           .where(cur_from: cur_from.iso_code, cur_to: cur_to.iso_code)
                           .order('date asc')
                           .last(2)
                           .sort

      raise "No minimal rate #{cur_from}, #{cur_to}" unless min_rate
      raise "No maximal rate #{cur_from}, #{cur_to}" unless max_rate

      Gera::ExternalRate.create!(
        source: cbr,
        snapshot: snapshot,
        currency_pair: pair,
        rate_value: min_rate.rate
      )

      Gera::ExternalRate.create!(
        source: cbr,
        snapshot: snapshot,
        currency_pair: pair.inverse,
        rate_value: 1.0 / max_rate.rate
      )

      avg_rate = (max_rate.rate + min_rate.rate) / 2.0

      Gera::ExternalRate.create!(
        source: cbr_avg,
        snapshot: avg_snapshot,
        currency_pair: pair,
        rate_value: avg_rate
      )

      Gera::ExternalRate.create!(
        source: cbr_avg,
        snapshot: avg_snapshot,
        currency_pair: pair.inverse,
        rate_value: 1.0 / avg_rate
      )
    end

    def cbr_avg
      @cbr_avg ||= Gera::RateSourceCbrAvg.get!
    end

    def cbr
      @cbr ||= Gera::RateSourceCbr.get!
    end

    def days
      today = Date.today
      logger.info "Start import for #{today}"

      [
        1.business_day.ago(today),
        today.yesterday.yesterday,
        today.yesterday,
        today,
        today.tomorrow,
        1.business_day.from_now(today)
      ].uniq.sort
    end

    def load_rates
      rates_by_date = {}
      days.each do |date|
        rates_by_date[date] = fetch_rates(date)
      rescue WrongDate => err
        logger.warn err

        # HTTP redirection loop: http://www.cbr.ru/scripts/XML_daily.asp?date_req=09/01/2019
      rescue RuntimeError => err
        raise err unless err.message.include? 'HTTP redirection loop'

        logger.error err
      end
      rates_by_date
    end

    def fetch_rates(date)
      uri = URI.parse URL
      uri.query = 'date_req=' + date.strftime('%d/%m/%Y')

      logger.info "fetch rates for #{date} from #{uri}"

      doc = Nokogiri::XML URI.open(uri)
      root = doc.xpath('/ValCurs')

      root_date = root.attr('Date').text
      validate_date = date.strftime('%d.%m.%Y')

      return root if validate_date == root_date

      raise WrongDate, "Request and response dates are different #{uri}: #{validate_date} <> #{root_date}"
    end

    def save_rates(date, rates)
      return if Gera::CbrExternalRate.where(date: date, cur_from: currencies.map(&:iso_code)).count == currencies.count

      currencies.each do |cur|
        save_rate get_rate(rates, CBR_IDS[cur.iso_code]), cur, date unless Gera::CbrExternalRate.where(date: date, cur_from: cur.iso_code).exists?
      end
    end

    def get_rate(root, id)
      valute = root.xpath("Valute[@ID=\"#{id}\"]")
      original_rate = valute.xpath('Value').text.sub(',', '.').to_f
      nominal = valute.xpath('Nominal').text.sub(',', '.').to_f
      OpenStruct.new original_rate: original_rate, nominal: nominal
    end

    def save_rate(rate_struct, cur, date)
      original_rate = rate_struct.original_rate
      nominal = rate_struct.nominal

      rate = (original_rate / nominal).round(ROUND)

      Gera::CbrExternalRate.create!(
        cur_from: cur.iso_code,
        cur_to: RUB.iso_code,
        rate: rate,
        original_rate: original_rate,
        nominal: nominal,
        date: date
      )
    end
  end
end
