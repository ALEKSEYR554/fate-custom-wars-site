module Api
  class ApiController < ActionController::API
    # Разрешаем запросы из браузера с любых наших доменов
    before_action :allow_cors

    private

    def allow_cors
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
    end
  end
end
