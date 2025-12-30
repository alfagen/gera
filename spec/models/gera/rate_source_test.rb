# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gera::RateSource', type: :model do
  fixtures :gera_rate_sources

  describe "RateSource model" do
    it "loads fixtures correctly" do
      source = gera_rate_sources(:cbr)
      expect(source).to be_persisted
      expect(source.name).to eq "Central Bank of Russia"
      expect(source.type).to eq "Gera::RateSourceCbr"
      expect(source.is_enabled).to be true
    end

    it "creates new rate source" do
      source = Gera::RateSource.create!(
        name: "Test Source",
        type: "Gera::RateSourceManual",
        is_enabled: true
      )
      expect(source).to be_persisted
      expect(source.name).to eq "Test Source"
    end

    it "validates presence of name" do
      source = Gera::RateSource.new
      expect(source).not_to be_valid
      expect(source.errors[:name]).to include "can't be blank"
    end
  end
end