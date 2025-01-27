# frozen_string_literal: true

class ::Jobs::WorkflowAiTransitions < ::Jobs::Scheduled
  sidekiq_options retry: false

  every 1.hour

  def execute(args)
    ::DiscourseWorkflow::AiActions.new.transition_all
  end
end
