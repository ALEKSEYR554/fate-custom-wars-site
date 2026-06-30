module ServantData
  class ServantDataController < ApplicationController
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

    def serve_servant_page
      # тут пока пусто
    end
  end
end
