class WebhooksController < ApplicationController
  # Отключаем защиту CSRF, так как запрос делает бот Gitea, а не браузер
  skip_before_action :verify_authenticity_token

  def gitea
    # Проверяем секретный пароль из URL
    if params[:token] != ENV["WEBHOOK_SECRET"]
      render json: { error: "Доступ запрещен" }, status: :unauthorized
      return
    end

    # Запускаем обновление в фоновом потоке, чтобы сразу ответить Gitea "ОК",
    # иначе Gitea будет ждать окончания перезагрузки и выдаст ошибку таймаута.
    Thread.new do
      sleep 2
      system("(cd /home/fate-custom-wars-site-rails && git fetch --all && git reset --hard origin/main && RAILS_ENV=production /root/.local/share/mise/shims/bundle exec rails db:migrate && systemctl restart fate-puma) > log/update.log 2>&1")
    end

    render json: { ok: true, message: "Обновление запущено" }
  end
end
