module Api
  # Наследуемся от ActionController::Base вместо ApiController,
  # так как нам нужно отдать красивую HTML-страницу, а не JSON!
  class SwaggerController < ActionController::Base
    def index
      # Рендерим шаблон без использования глобального layout
      render "swagger/index", layout: false
    end
  end
end
