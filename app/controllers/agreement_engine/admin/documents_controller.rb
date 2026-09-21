# frozen_string_literal: true

module AgreementEngine
  module Admin
    class DocumentsController < ::ApplicationController
      skip_before_action :require_accepted_agreements!, raise: false
      before_action :authenticate_admin!
      before_action :set_document, only: [:show, :edit, :update, :destroy]

      def index
        @documents = AgreementEngine::Document.order(created_at: :desc)
        @documents = apply_scope(@documents)
      end

      def show
      end

      def new
        @document = AgreementEngine::Document.new
      end

      def create
        @document = AgreementEngine::Document.new(document_params)

        if @document.save
          redirect_to agreement_engine.admin_document_path(@document), notice: "Document was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @document.update(document_params)
          redirect_to agreement_engine.admin_document_path(@document), notice: "Document was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @document.destroy
        redirect_to agreement_engine.admin_documents_path, notice: "Document was successfully deleted.", status: :see_other
      end

      private

      def authenticate_admin!
        AgreementEngine.config.authenticate_admin!(self)
      end

      def set_document
        @document = AgreementEngine::Document.find(params[:id])
      end

      def document_params
        params.require(:document).permit(:document_type, :version, :summary, :effective_at, :content)
      end

      def apply_scope(documents)
        case params[:scope]
        when "published" then documents.published
        when "draft" then documents.draft
        else documents
        end
      end
    end
  end
end
