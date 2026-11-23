# frozen_string_literal: true

module AgreementEngine
  module ReadingCheck
    extend ActiveSupport::Concern

    included do
      helper_method :elapsed_reading_seconds
    end

    private

    def record_served
      return unless @version

      served = session[:agreement_engine_served] ||= {}
      served[@version.id.to_s] ||= Time.current.to_i
    end

    def too_soon?
      minimum = reading_type.minimum_reading_seconds
      return false if minimum.zero?

      served_at.nil? || Time.current.to_i - served_at < minimum
    end

    def too_soon_reason(doing)
      I18n.t("agreement_engine.reading.too_soon.#{doing}", document: reading_type.title, seconds: reading_type.minimum_reading_seconds)
    end

    def reading_evidence
      evidence = {}
      minimum = reading_type.minimum_reading_seconds
      evidence.merge!(minimum_seconds: minimum, measured_seconds: Time.current.to_i - served_at) unless minimum.zero?
      evidence.merge!(opened_on: opened_on_page, opened_at: Time.zone.at(served_at).iso8601) if opened_on_page && reading_type.requires_opening? && served_at
      evidence.merge!(scroll: scroll_report) if reading_type.requires_scroll?
      evidence.presence
    end

    def scroll_report
      report = params[:reading]
      return {reported_by: nil} unless report

      {reported_by: "browser", end_reached: report[:end_reached] == "true", end_in_view_on_load: report[:end_in_view_on_load] == "true"}
    end

    def elapsed_reading_seconds
      served_at ? Time.current.to_i - served_at : 0
    end

    def served_at
      session.dig(:agreement_engine_served, @version.id.to_s)
    end

    def opened_on_page
      nil
    end
  end
end
