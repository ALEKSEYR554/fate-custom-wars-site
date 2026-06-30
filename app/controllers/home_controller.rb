class HomeController < ApplicationController
  def index
    # @all_traits = Servant.pluck(:traits).flatten.uniq.compact.sort
  end
end
