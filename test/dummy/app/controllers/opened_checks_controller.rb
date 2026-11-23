class OpenedChecksController < ApplicationController
  def show
    render json: agreement_engine_opened(params[:document_type])
  end
end
