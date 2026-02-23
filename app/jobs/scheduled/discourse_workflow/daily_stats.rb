# frozen_string_literal: true

module Jobs
  module DiscourseWorkflow
    class DailyStats < ::Jobs::Scheduled
      sidekiq_options retry: false

      every 24.hours

      def execute(args = {})
        ::DiscourseWorkflow::Stats.new.calculate_daily_stats
      end
    end
  end
end
