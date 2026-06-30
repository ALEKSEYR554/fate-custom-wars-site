class ServantsController < ApplicationController
  def show
    # Ищем слугу по game_id (например, 1S-001)
    @servant = Servant.find_by(game_id: params[:game_id])

    # Если не нашли - выдаем ошибку 404
    render plain: "Слуга не найден", status: :not_found unless @servant
  end
end
