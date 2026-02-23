# frozen_string_literal: true

require_relative "../../../plugin_helper"

RSpec.describe Jobs::DiscourseWorkflow::TopicArrivalNotifier do
  fab!(:topic)

  let(:job) { described_class.new }

  it "alerts watchers for the first post when the topic exists" do
    post_alerter = instance_spy(PostAlerter)
    allow(PostAlerter).to receive(:new).and_return(post_alerter)

    job.execute(topic_id: topic.id)

    expect(post_alerter).to have_received(:after_save_post).with(topic.first_post, true)
  end

  it "no-ops when the topic cannot be found" do
    allow(PostAlerter).to receive(:new)

    job.execute(topic_id: -1)

    expect(PostAlerter).not_to have_received(:new)
  end
end
