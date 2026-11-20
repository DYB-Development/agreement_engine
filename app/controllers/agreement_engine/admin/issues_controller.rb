# frozen_string_literal: true

module AgreementEngine
  module Admin
    class IssuesController < ::ApplicationController
      skip_before_action :require_accepted_agreements!, raise: false
      before_action :authenticate_admin!

      def create
        document = AgreementEngine::Document.issue!(
          type: issue_params[:document_type],
          page_version: KeystoneUi::Pages::Version.find(issue_params[:page_version_id]),
          version: issue_params[:version],
          effective_at: issue_params[:effective_at]
        )
        redirect_to agreement_engine.admin_document_path(document), notice: "Version #{document.version} was issued."
      end

      private

      def authenticate_admin!
        AgreementEngine.config.authenticate_admin!(self)
      end

      def issue_params
        params.require(:issue).permit(:document_type, :page_version_id, :version, :effective_at)
      end
    end
  end
end
