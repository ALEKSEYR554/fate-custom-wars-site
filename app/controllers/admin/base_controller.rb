module Admin
  class BaseController < ApplicationController
    # Встроенная базовая защита браузера. Поменяй пароль!
    http_basic_authenticate_with name: "#{ENV["CUSTOM_WARS_ADMIN_LOGIN"]}", password: "#{ENV["CUSTOM_WARS_ADMIN_PASSWORD"]}"
  end
end
