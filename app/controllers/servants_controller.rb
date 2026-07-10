class ServantsController < ApplicationController
  def show
    # Ищем слугу по game_id (например, 1S-001)
    @servant = Servant.find_by(game_id: params[:game_id])

    # Если не нашли - выдаем ошибку 404
    render plain: "Слуга не найден", status: :not_found unless @servant
  end

  def index
    if ActiveRecord::Base.connection.table_exists?("servants")
      last_updated = Servant.maximum(:updated_at).to_i
      @unique_traits = Rails.cache.fetch("unique_traits_#{last_updated}") do
        Servant.pluck(Arel.sql("distinct unnest(traits)")).compact.reject(&:empty?).sort
      end
      # Грузим в память нужные поля всех слуг сразу
      @all_servants = Servant.order(:id).select(:game_id, :name, :servant_class, :rarity, :traits)
    else
      @unique_traits = []
      @all_servants = []
    end
  end
end
