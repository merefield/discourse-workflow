# frozen_string_literal: true

require_relative "../../../plugin_helper"

RSpec.describe Jobs::DiscourseWorkflow::AiTransitions do
  let(:job) { described_class.new }

  it "delegates scheduled execution to AI workflow transitions" do
    ai_actions = instance_spy(DiscourseWorkflow::AiActions)
    allow(DiscourseWorkflow::AiActions).to receive(:new).and_return(ai_actions)

    job.execute({})

    expect(DiscourseWorkflow::AiActions).to have_received(:new)
    expect(ai_actions).to have_received(:transition_all)
  end
end
