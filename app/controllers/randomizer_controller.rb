class RandomizerController < ApplicationController
  def index
    last_updated = Servant.maximum(:updated_at).to_i
    cache_key = "unique_traits_#{last_updated}"
    @unique_traits = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      Servant.pluck(Arel.sql("distinct unnest(traits)")).compact.reject(&:empty?).sort
    end
  end
end
