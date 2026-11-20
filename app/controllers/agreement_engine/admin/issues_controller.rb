# frozen_string_literal: true

module AgreementEngine
  module Admin
    class IssuesController < ::ApplicationController
      skip_before_action :require_accepted_agreements!, raise: false
      before_action :authenticate_admin!

      def new
        @page_versions = published_page_versions
      end

      def create
        document = AgreementEngine::Document.issue!(
          type: issue_params[:document_type],
          page_version: KeystoneUi::Pages::Version.find(issue_params[:page_version_id]),
          version: issue_params[:version],
          effective_at: issue_params[:effective_at],
          period: period
        )
        redirect_to agreement_engine.admin_document_path(document), notice: "Version #{document.version} was issued."
      rescue ActiveRecord::RecordInvalid => invalid
        @error = invalid.record.errors.full_messages.to_sentence
        @page_versions = published_page_versions
        render :new, status: :unprocessable_entity
      end

      private

      def published_page_versions
        KeystoneUi::Pages::Version.live.includes(:page).order(:page_id)
      end

      def authenticate_admin!
        AgreementEngine.config.authenticate_admin!(self)
      end

      def issue_params
        params.require(:issue).permit(:document_type, :page_version_id, :version, :effective_at, :period_starts_on, :period_ends_on, :period_duration)
      end

      def period
        return {"duration" => issue_params[:period_duration]} if issue_params[:period_duration].present?
        return if issue_params[:period_starts_on].blank? && issue_params[:period_ends_on].blank?

        {"starts_on" => issue_params[:period_starts_on].presence, "ends_on" => issue_params[:period_ends_on].presence}.compact
      end
    end
  end
end
