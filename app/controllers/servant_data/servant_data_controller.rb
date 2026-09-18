module ServantData
  class ServantDataController < ApplicationController
    before_action :set_cache_headers, only: [ :serve_sprite, :serve_ce ]
    def serve_sprite
      safe_filename = File.basename(params[:filename])

      # ИСПОЛЬЗУЕМ params[:servant_code]
      file_path = Rails.root.join("storage", "servant_data", params[:servant_code], safe_filename)

      if File.exist?(file_path)
        # Убрали type:, Рельсы сами поймут, что это картинка
        send_file file_path, disposition: "inline"
      else
        render plain: "Файл спрайта не найден", status: :not_found
      end
    end

    def serve_ce
      safe_filename = File.basename(params[:filename])
      file_path = Rails.root.join("storage", "craft_essences", safe_filename)
      if File.exist?(file_path)
        send_file file_path, disposition: "inline"
      else
        render plain: "Карта не найдена", status: :not_found
      end
    end

    def serve_servant_page
      # тут пока пусто
    end

    def set_cache_headers
      # Cache-Control: public, max-age=31536000
      expires_in 1.year, public: true
    end
  end
end
