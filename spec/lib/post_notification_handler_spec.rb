# frozen_string_literal: true

require_relative "../plugin_helper"

describe DiscourseWorkflow::PostNotificationHandler do
  fab!(:workflow) { Fabricate(:workflow, name: "Notification Workflow") }
  fab!(:workflow_category, :category)
  fab!(:other_category, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: workflow_category.id,
      position: 1,
    )
  end
  fab!(:topic_owner, :user)
  fab!(:topic) { Fabricate(:topic, user: topic_owner, category: workflow_category) }
  fab!(:workflow_state) do
    Fabricate(
      :workflow_state,
      topic_id: topic.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )
  end
  fab!(:watching_same_category_user, :user)
  fab!(:watching_other_category_user, :user)

  before do
    CategoryUser.create!(
      user_id: watching_same_category_user.id,
      category_id: workflow_category.id,
      notification_level: DiscourseWorkflow::WATCHING_FIRST_POST,
    )

    CategoryUser.create!(
      user_id: watching_other_category_user.id,
      category_id: other_category.id,
      notification_level: DiscourseWorkflow::WATCHING_FIRST_POST,
    )
  end

  it "notifies only users watching-first-post for the topic category" do
    post = Fabricate(:post, topic: topic, user: topic_owner)
    other_notifications_before =
      watching_other_category_user
        .notifications
        .where(notification_type: Notification.types[:workflow_topic_arrival])
        .count

    expect do described_class.new(post, []).handle end.to change {
      watching_same_category_user
        .notifications
        .where(notification_type: Notification.types[:workflow_topic_arrival])
        .count
    }.by(1)

    expect(
      watching_other_category_user
        .notifications
        .where(notification_type: Notification.types[:workflow_topic_arrival])
        .count,
    ).to eq(other_notifications_before)
  end

  it "does not send workflow arrival notifications for ordinary replies" do
    Fabricate(:post, topic: topic, user: topic_owner)
    post = Fabricate(:post, topic: topic, user: topic_owner, post_number: 2)

    expect do described_class.new(post, []).handle end.not_to change {
      Notification.where(notification_type: Notification.types[:workflow_topic_arrival]).count
    }
  end

  it "loads watcher users in bulk as watcher counts grow" do
    allow(Notification).to receive(:create!)

    base_user_query_count =
      track_sql_queries { described_class.new(first_post_with_state, []).handle }.count do |query|
        query.start_with?("SELECT") && query.include?('FROM "users"')
      end

    3.times do
      user = Fabricate(:user)
      CategoryUser.create!(
        user_id: user.id,
        category_id: workflow_category.id,
        notification_level: DiscourseWorkflow::WATCHING_FIRST_POST,
      )
    end

    expanded_user_query_count =
      track_sql_queries { described_class.new(first_post_with_state, []).handle }.count do |query|
        query.start_with?("SELECT") && query.include?('FROM "users"')
      end

    expect(expanded_user_query_count).to be <= base_user_query_count + 1
  end

  def first_post_with_state
    next_topic = Fabricate(:topic, user: topic_owner, category: workflow_category)
    Fabricate(
      :workflow_state,
      topic_id: next_topic.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )
    Fabricate(:post, topic: next_topic, user: topic_owner)
  end
end
