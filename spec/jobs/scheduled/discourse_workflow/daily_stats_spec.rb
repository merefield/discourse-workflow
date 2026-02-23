# frozen_string_literal: true

require_relative "../../../plugin_helper"

RSpec.describe Jobs::DiscourseWorkflow::DailyStats do
  fab!(:workflow_a) { Fabricate(:workflow, name: "Change Requests") }
  fab!(:workflow_b) { Fabricate(:workflow, name: "Incident Review") }

  fab!(:category_a1, :category)
  fab!(:category_a2, :category)
  fab!(:category_a3, :category)
  fab!(:category_a4, :category)
  fab!(:category_b1, :category)
  fab!(:category_b2, :category)
  fab!(:category_b3, :category)

  fab!(:step_a1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_a.id,
      category_id: category_a1.id,
      position: 1,
      name: "Intake",
    )
  end
  fab!(:step_a2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_a.id,
      category_id: category_a2.id,
      position: 2,
      name: "Triage",
    )
  end
  fab!(:step_a3) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_a.id,
      category_id: category_a3.id,
      position: 3,
      name: "Approval",
    )
  end
  fab!(:step_a4) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_a.id,
      category_id: category_a4.id,
      position: 4,
      name: "Done",
    )
  end
  fab!(:step_b1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_b.id,
      category_id: category_b1.id,
      position: 1,
      name: "Queue",
    )
  end
  fab!(:step_b2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_b.id,
      category_id: category_b2.id,
      position: 2,
      name: "Investigating",
    )
  end
  fab!(:step_b3) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_b.id,
      category_id: category_b3.id,
      position: 3,
      name: "Resolved",
    )
  end

  let(:job) { described_class.new }

  before do
    freeze_time Time.zone.parse("2026-02-23 10:30:00 UTC")
    SiteSetting.workflow_enabled = true

    create_states_for(workflow: workflow_a, step: step_a1, count: 3, topic_category_id: category_a1.id)
    create_states_for(workflow: workflow_a, step: step_a2, count: 2, topic_category_id: category_a1.id)
    create_states_for(workflow: workflow_a, step: step_a3, count: 1, topic_category_id: category_a1.id)
    create_states_for(workflow: workflow_a, step: step_a4, count: 4, topic_category_id: category_a1.id)

    create_states_for(workflow: workflow_b, step: step_b1, count: 2, topic_category_id: category_b1.id)
    create_states_for(workflow: workflow_b, step: step_b2, count: 1, topic_category_id: category_b1.id)
    create_states_for(workflow: workflow_b, step: step_b3, count: 2, topic_category_id: category_b1.id)

    # Unstarted topics should not be counted until they have a workflow_state.
    Fabricate(:topic, category: category_a1)
    Fabricate(:topic, category: category_b1)

    # Existing same-day stats are replaced by the scheduled run.
    Fabricate(:workflow_stat, cob_date: Date.current, workflow: workflow_a, workflow_step: step_a1, count: 99)
    # Historical days are left untouched.
    Fabricate(
      :workflow_stat,
      cob_date: 1.day.ago.to_date,
      workflow: workflow_a,
      workflow_step: step_a1,
      count: 42,
    )
  end

  it "rebuilds daily workflow stats from current workflow state using complex multi-workflow data" do
    expect { job.execute({}) }.to change { current_day_stats.count }.from(1).to(7)

    expect(stat_count_for(workflow_a, step_a1)).to eq(3)
    expect(stat_count_for(workflow_a, step_a2)).to eq(2)
    expect(stat_count_for(workflow_a, step_a3)).to eq(1)
    expect(stat_count_for(workflow_a, step_a4)).to eq(4)
    expect(stat_count_for(workflow_b, step_b1)).to eq(2)
    expect(stat_count_for(workflow_b, step_b2)).to eq(1)
    expect(stat_count_for(workflow_b, step_b3)).to eq(2)
    expect(stat_count_for(workflow_a, step_a1, cob_date: 1.day.ago.to_date)).to eq(42)

    expect { job.execute({}) }.not_to change { current_day_stats.count }
    expect(stat_count_for(workflow_a, step_a1)).to eq(3)
    expect(stat_count_for(workflow_a, step_a4)).to eq(4)
    expect(stat_count_for(workflow_b, step_b3)).to eq(2)
  end

  it "does not write stats when workflow is disabled" do
    SiteSetting.workflow_enabled = false

    expect { job.execute({}) }.not_to change { DiscourseWorkflow::WorkflowStat.count }
  end

  def current_day_stats
    DiscourseWorkflow::WorkflowStat.where(cob_date: Date.current)
  end

  def create_states_for(workflow:, step:, count:, topic_category_id:)
    count.times do
      topic = Fabricate(:topic, category_id: topic_category_id)
      Fabricate(
        :workflow_state,
        topic_id: topic.id,
        workflow_id: workflow.id,
        workflow_step_id: step.id,
      )
    end
  end

  def stat_count_for(workflow, step, cob_date: Date.current)
    DiscourseWorkflow::WorkflowStat.find_by!(
      cob_date: cob_date,
      workflow_id: workflow.id,
      workflow_step_id: step.id,
    ).count
  end
end
