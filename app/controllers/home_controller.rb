class HomeController < ApplicationController
  layout "public"

  def index
    # Landing page for Tivo
    redirect_to_dashboard if user_signed_in?
  end

  private
    def redirect_to_dashboard
      redirect_to projects_path
    end
end
