# frozen_string_literal: true

module Gera
  # @abstract
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true
  end
end
