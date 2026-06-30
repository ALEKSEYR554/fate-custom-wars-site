Rails.application.routes.draw do
  get "servants/show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # API subdomain
  constraints subdomain: "api" do
    scope module: "api" do
      root to: "swagger#index", as: :api_root
      get "get_servant_with_traits", to: "servants#get_servant_with_traits"

      get "servant/:servant_code", to: "servants#get_from_code", constraints: { game_id: /[^\/]+/ }
    end
  end

  constraints subdomain: "content" do
    scope module: "content" do
      get "videos/random", to: "content#serve_random_video"
      get "videos/:filename", to: "content#serve_video", constraints: { filename: /[^\/]+/ }
    end
  end

  constraints subdomain: "servant-data" do
    scope module: "servant_data" do
      get "sprite/:servant_code/:filename", to: "servant_data#serve_sprite", constraints: { filename: /[^\/]+/ }
      get "servant-page/:servant_code", to: "servant_data#serve_servant_page"
    end
  end

  get "randomizer", to: "randomizer#index"
  # Страница слуги
  get "servants/:game_id", to: "servants#show"

  get "random_servants", to: redirect("/random_servants/main.html")

  get "random_servants/:filename", to: "random_servants#serve", constraints: { filename: /[^\/]+/ }

  get "smeshariki", to: redirect("/smeshariki/index.html")

  # Наш стандартный маршрут для выдачи файлов
  get "smeshariki/:filename", to: "smeshariki#serve", constraints: { filename: /[^\/]+/ }

  get "corona/*filename", to: "corona#serve", format: false
  get "corona", to: redirect("/corona/index.html")
  post "webhook/gitea", to: "webhooks#gitea"

  root "home#index"
  # Defines the root path route ("/")
  # root "posts#index"
  #
  match "*path", to: redirect(subdomain: "", path: "/"), via: :all
end
