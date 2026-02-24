# frozen_string_literal: true
require_relative "../plugin_helper"

describe ::DiscourseWorkflow::Transition do
  fab!(:category_1, :category)
  fab!(:category_2, :category)

  fab!(:workflow) do
    Fabricate(:workflow, name: "Test Workflow", description: "Test Workflow Description")
  end
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_1.id,
      name: "Step 1",
      description: "Step 1 Description",
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_2.id,
      name: "Step 2",
      description: "Step 2 Description",
    )
  end

  fab!(:option_1, :workflow_option)

  fab!(:step_option_1) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_1.id,
      target_step_id: step_2.id,
    )
  end

  fab!(:topic) { Fabricate(:topic, category: category_1) }

  fab!(:workflow_state) do
    Fabricate(
      :workflow_state,
      topic_id: topic.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )
  end

  fab!(:user)

  fab!(:transition) { DiscourseWorkflow::Transition.new }

  it "creates an audit log entry" do
    expect { transition.transition(user.id, topic, option_1.slug) }.to change {
      ::DiscourseWorkflow::WorkflowAuditLog.count
    }.by(1)
  end

  it "updates the topic with a small action Post" do
    expect { transition.transition(user.id, topic, option_1.slug) }.to change {
      ::Post.where(topic_id: topic.id).count
    }.by(1)
  end

  it "writes a transition action that includes from and to step names" do
    transition.transition(user.id, topic, option_1.slug)

    small_action_post =
      Post.where(topic_id: topic.id, post_type: Post.types[:small_action]).order(:id).last
    expect(small_action_post.raw).to include(step_1.name)
    expect(small_action_post.raw).to include(step_2.name)
  end

  it "does not perform per-transition target-step lookup queries" do
    sql_queries = track_sql_queries { transition.transition(user, topic, option_1.slug) }

    target_step_lookup_queries =
      sql_queries.select do |query|
        query.include?('FROM "workflow_steps"') && query.include?('"workflow_steps"."id" =') &&
          query.include?("LIMIT 1")
      end

    expect(target_step_lookup_queries).to eq([])
  end

  it "writes ending category name from the target step category" do
    transition.transition(user, topic, option_1.slug)

    audit_log = DiscourseWorkflow::WorkflowAuditLog.order(:id).last
    expect(audit_log.starting_category_name).to eq(category_1.name)
    expect(audit_log.ending_category_name).to eq(category_2.name)
  end
end
