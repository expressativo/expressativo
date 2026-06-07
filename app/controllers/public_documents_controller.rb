class PublicDocumentsController < ApplicationController
  layout "public"

  def show
    @document = Document.where.not(public_token: nil).find_by!(public_token: params[:public_token])
    @project = @document.project
  end
end
