class RandomizerController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create_draft, :update_draft ]

  def index
    last_updated = Servant.maximum(:updated_at).to_i
    @unique_traits = Rails.cache.fetch("unique_traits_#{last_updated}", expires_in: 24.hours) do
      Servant.pluck(Arel.sql("distinct unnest(traits)")).compact.reject(&:empty?).sort
    end
  end

  # Создание новой ссылки
  def create_draft
    session = DraftSession.create!(data: params[:data].to_unsafe_h)
    render json: { slug: session.slug }
  end

  # Обновление при реролле
  def update_draft
    session = DraftSession.find_by(slug: params[:slug])
    if session && session.expires_at > Time.current
      session.update!(data: params[:data].to_unsafe_h)
      render json: { ok: true }
    else
      render json: { error: "Сессия не найдена или истекла" }, status: :not_found
    end
  end

  # Страница для игроков (только чтение)
  def viewer
    @session = DraftSession.find_by(slug: params[:slug])
    if !@session || @session.expires_at < Time.current
      render plain: "Ссылка недействительна или её срок действия (1 час) истёк.", status: :not_found
    end
  end
end
