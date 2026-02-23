# frozen_string_literal: true

RSpec.describe "Workflow charts", type: :system do
  fab!(:workflow_discovery_page) { PageObjects::Pages::WorkflowDiscovery.new }
  fab!(:admin, :admin)
  fab!(:allowed_group, :group)

  fab!(:workflow) { Fabricate(:workflow, name: "Primary Burn Down Workflow") }
  fab!(:other_workflow) { Fabricate(:workflow, name: "Secondary Burn Down Workflow") }

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
    enable_current_plugin
    SiteSetting.workflow_enabled = true
    SiteSetting.workflow_charts_allowed_groups = allowed_group.id.to_s

    10.times do
      topic = Fabricate(:topic, category: category_1)
      Fabricate(
        :workflow_state,
        topic_id: topic.id,
        workflow_id: workflow.id,
        workflow_step_id: step_1.id,
      )
    end

    create_stats_history_for(workflow, [step_1, step_2, step_3, step_4])
    create_stats_history_for(other_workflow, [other_step], base_count: 10)

    sign_in(admin)
  end

  it "renders a burn down chart on /workflow/charts with weeks selector" do
    workflow_discovery_page.visit_workflow_charts

    expect(page).to have_current_path("/workflow/charts", url: false)
    expect(workflow_discovery_page).to have_workflow_burndown_chart
    expect(workflow_discovery_page).to have_workflow_burndown_chart_canvas
    expect(page).to have_css(
      ".workflow-burndown__workflow-name",
      text: "Workflow: #{workflow.name}",
    )
    expect(workflow_discovery_page).to have_workflow_view_option("Chart")
    expect(workflow_discovery_page).to have_workflow_chart_weeks_selector
    expect(workflow_discovery_page).to have_no_workflow_view_option("Kanban")
    expect(workflow_discovery_page).to have_workflow_chart_legend_step("Queue")
    expect(workflow_discovery_page).to have_workflow_chart_legend_step("Review")
    expect(workflow_discovery_page).to have_workflow_chart_legend_step("Approval")
    expect(workflow_discovery_page).to have_workflow_chart_legend_step("Done")
    expect(workflow_discovery_page.workflow_chart_point_count).to eq(14)
    expect(workflow_discovery_page).to have_chart_weeks_option(1)
    expect(workflow_discovery_page).to have_view_then_period_order
  end

  it "updates chart horizon when weeks filter changes up to 12 weeks" do
    workflow_discovery_page.visit_workflow_charts

    workflow_discovery_page.select_chart_weeks(12)

    expect(page).to have_current_path(%r{/workflow\?.*chart_weeks=12}, url: true)
    expect(page).to have_current_path(%r{/workflow\?.*workflow_view=chart}, url: true)
    expect(workflow_discovery_page.workflow_chart_point_count).to eq(84)
  end

  it "supports a one-week period in chart mode" do
    workflow_discovery_page.visit_workflow_charts

    workflow_discovery_page.select_chart_weeks(1)

    expect(page).to have_current_path(%r{/workflow\?.*chart_weeks=1}, url: true)
    expect(workflow_discovery_page.workflow_chart_point_count).to eq(7)
  end

  it "supports switching chart mode from workflow discovery view dropdown" do
    workflow_discovery_page.visit_workflow
    workflow_discovery_page.select_workflow_view("Chart")

    expect(page).to have_current_path(%r{/workflow\?.*workflow_view=chart}, url: true)
    expect(workflow_discovery_page).to have_workflow_burndown_chart
  end

  def create_stats_history_for(workflow_record, steps, base_count: nil)
    end_date = Date.current.end_of_week(:saturday)
    start_date = end_date - 13.days
    days = (start_date..end_date).to_a

    days.each_with_index do |day, day_index|
      if steps.length == 1
        Fabricate(
          :workflow_stat,
          cob_date: day,
          workflow: workflow_record,
          workflow_step: steps.first,
          count: base_count || 10,
        )
        next
      end

      queue_count, review_count, approval_count, done_count =
        complex_daily_counts(days.count)[day_index]

      Fabricate(
        :workflow_stat,
        cob_date: day,
        workflow: workflow_record,
        workflow_step: steps[0],
        count: queue_count,
      )
      Fabricate(
        :workflow_stat,
        cob_date: day,
        workflow: workflow_record,
        workflow_step: steps[1],
        count: review_count,
      )
      Fabricate(
        :workflow_stat,
        cob_date: day,
        workflow: workflow_record,
        workflow_step: steps[2],
        count: approval_count,
      )
      Fabricate(
        :workflow_stat,
        cob_date: day,
        workflow: workflow_record,
        workflow_step: steps[3],
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
