# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe DiscourseWorkflow::WorkflowChartsController, type: :request do
  fab!(:admin, :admin)
  fab!(:allowed_user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:blocked_user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:allowed_group, :group)

  fab!(:workflow) { Fabricate(:workflow, name: "Burn Down Workflow") }
  fab!(:other_workflow) { Fabricate(:workflow, name: "Other Workflow") }

  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:category_3, :category)
  fab!(:category_4, :category)
  fab!(:other_category, :category)

  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_1.id,
      position: 1,
      name: "Queue",
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_2.id,
      position: 2,
      name: "Review",
    )
  end
  fab!(:step_3) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_3.id,
      position: 3,
      name: "Approval",
    )
  end
  fab!(:step_4) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_4.id,
      position: 4,
      name: "Done",
    )
  end
  fab!(:other_step) do
    Fabricate(
      :workflow_step,
      workflow_id: other_workflow.id,
      category_id: other_category.id,
      position: 1,
      name: "Other Queue",
    )
  end

  before do
    SiteSetting.workflow_enabled = true
    SiteSetting.workflow_charts_allowed_groups = allowed_group.id.to_s
    GroupUser.create!(group: allowed_group, user: allowed_user)

    category_1.update_columns(color: "112233")
    category_2.update_columns(color: "445566")
    category_3.update_columns(color: "778899")
    category_4.update_columns(color: "2196f3")

    topics = 10.times.map { Fabricate(:topic, category: category_1) }
    topics.each do |topic|
      Fabricate(
        :workflow_state,
        topic_id: topic.id,
        workflow_id: workflow.id,
        workflow_step_id: step_1.id,
      )
    end

    create_stats_history
  end

  it "returns forbidden when user is not admin and not in configured groups" do
    sign_in(blocked_user)

    get "/discourse-workflow/charts.json"

    expect(response.status).to eq(403)
  end

  it "allows configured group members to query workflow chart data" do
    sign_in(allowed_user)

    get "/discourse-workflow/charts.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["selected_workflow_id"]).to eq(workflow.id)
  end

  it "allows admins to query workflow chart data" do
    sign_in(admin)

    get "/discourse-workflow/charts.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["selected_workflow_id"]).to eq(workflow.id)
  end

  it "serves the workflow charts discovery route for authorized users" do
    sign_in(admin)

    get "/workflow/charts.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("topic_list", "topics")).to be_present
  end

  it "registers /workflow/charts as a list route" do
    recognized = Rails.application.routes.recognize_path("/workflow/charts", method: :get)

    expect(recognized[:controller]).to eq("list")
    expect(recognized[:action]).to eq("workflow_charts")
  end

  it "returns full-week daily labels and per-step series for 2 weeks by default" do
    sign_in(admin)

    get "/discourse-workflow/charts.json", params: { workflow_id: workflow.id }

    payload = response.parsed_body
    labels = payload["labels"]
    series = payload["series"]
    step_series = series.index_by { |entry| entry["step_name"] }

    expect(response.status).to eq(200)
    expect(payload["weeks"]).to eq(2)
    expect(labels.length).to eq(14)
    expect(labels.first).to eq((Date.current.end_of_week(:saturday) - 13.days).iso8601)
    expect(labels.last).to eq(Date.current.end_of_week(:saturday).iso8601)
    expect(step_series.keys).to contain_exactly("Queue", "Review", "Approval", "Done")
    expect(step_series["Queue"]["color"]).to eq("112233")
    expect(step_series["Review"]["color"]).to eq("445566")
    expect(step_series["Approval"]["color"]).to eq("778899")
    expect(step_series["Done"]["color"]).to eq("2196f3")
    expect(step_series["Queue"]["data"].length).to eq(labels.length)
    expect(step_series["Review"]["data"].length).to eq(labels.length)
    expect(step_series["Approval"]["data"].length).to eq(labels.length)
    expect(step_series["Done"]["data"].length).to eq(labels.length)
  end

  it "supports up to 12 weeks and returns selected workflow metadata only" do
    sign_in(admin)

    get "/discourse-workflow/charts.json", params: { workflow_id: other_workflow.id, weeks: 12 }

    payload = response.parsed_body

    expect(response.status).to eq(200)
    expect(payload["weeks"]).to eq(12)
    expect(payload["labels"].length).to eq(84)
    expect(payload["selected_workflow_id"]).to eq(other_workflow.id)
    expect(payload["selected_workflow_name"]).to eq(other_workflow.name)
    expect(payload).not_to have_key("workflows")
  end

  it "supports a one-week horizon when requested" do
    sign_in(admin)

    get "/discourse-workflow/charts.json", params: { workflow_id: workflow.id, weeks: 1 }

    payload = response.parsed_body
    expect(response.status).to eq(200)
    expect(payload["weeks"]).to eq(1)
    expect(payload["labels"].length).to eq(7)
  end

  def create_stats_history
    end_date = Date.current.end_of_week(:saturday)
    start_date = end_date - 13.days
    days = (start_date..end_date).to_a

    counts_by_day = complex_daily_counts(days.count)

    days.each_with_index do |day, index|
      queue_count, review_count, approval_count, done_count = counts_by_day[index]

      Fabricate(
        :workflow_stat,
        cob_date: day,
        workflow: workflow,
        workflow_step: step_1,
        count: queue_count,
      )
      Fabricate(
        :workflow_stat,
        cob_date: day,
        workflow: workflow,
        workflow_step: step_2,
        count: review_count,
      )
      Fabricate(
        :workflow_stat,
        cob_date: day,
        workflow: workflow,
        workflow_step: step_3,
        count: approval_count,
      )
      Fabricate(
        :workflow_stat,
        cob_date: day,
        workflow: workflow,
        workflow_step: step_4,
        count: done_count,
      )
    end
  end

  def complex_daily_counts(day_count)
    queue = 6
    review = 0
    approval = 0
    done = 0
    delayed_not_started = 4
    delayed_starts = [0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0]

    Array.new(day_count) do |day_index|
      starts_today = [delayed_starts.fetch(day_index, 0), delayed_not_started].min
      delayed_not_started -= starts_today
      queue += starts_today

      moved_to_review = [queue, day_index.even? ? 2 : 1].min
      queue -= moved_to_review
      review += moved_to_review

      moved_to_approval = [review, day_index % 3 == 0 ? 2 : 1].min
      review -= moved_to_approval
      approval += moved_to_approval

      moved_to_done = [approval, day_index >= 2 ? 1 : 0].min
      approval -= moved_to_done
      done += moved_to_done

      if day_index % 6 == 5 && done > 0
        done -= 1
        review += 1
      end

      [queue, review, approval, done]
    end
  end
end
