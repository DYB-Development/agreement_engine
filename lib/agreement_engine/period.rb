# frozen_string_literal: true

module AgreementEngine
  module Period
    module_function

    def describe(period)
      return if period.blank?
      return "#{ActiveSupport::Duration.parse(period["duration"]).inspect} from acceptance" if period["duration"]

      starts = period["starts_on"]&.to_date
      ends = period["ends_on"]&.to_date
      return "#{day(starts)} to #{day(ends)}" if starts && ends
      return "from #{day(starts)}" if starts

      "until #{day(ends)}"
    end

    def day(date)
      date.strftime("%-d %B %Y")
    end
  end
end
