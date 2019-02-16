# frozen_string_literal: true

module Gera
  class DirectionRateSnapshot < ApplicationRecord
    has_many :direction_rates, foreign_key: :snapshot_id
  end
end
