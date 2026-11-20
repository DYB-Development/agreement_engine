# frozen_string_literal: true

module AgreementEngine
  module Admin
    class DocumentsController < ::ApplicationController
      skip_before_action :require_accepted_agreements!, raise: false
      before_action :authenticate_admin!
      before_action :set_document, only: [:show, :destroy]

      def index
        @documents = AgreementEngine::Document.order(created_at: :desc)
        @documents = apply_scope(@documents)
      end

      def show
      end

      def destroy
        if @document.destroy
          redirect_to agreement_engine.admin_documents_path, notice: "Document was successfully deleted.", status: :see_other
        else
          redirect_to agreement_engine.admin_document_path(@document), alert: @document.errors.full_messages.to_sentence, status: :see_other
        end
      end

      private

      def authenticate_admin!
        AgreementEngine.config.authenticate_admin!(self)
      end

      def set_document
        @document = AgreementEngine::Document.find_by!(code: params[:id])
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
