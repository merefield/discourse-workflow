# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Workflow admin overview" do
  let(:overview_page) { PageObjects::Pages::WorkflowAdminOverview.new }

  fab!(:admin)
  fab!(:workflow) { Fabricate(:workflow, name: "Overview workflow") }
  fab!(:workflow_parent_category, :category)
  fab!(:review_category) { Fabricate(:category, parent_category_id: workflow_parent_category.id) }
  fab!(:done_category) { Fabricate(:category, parent_category_id: workflow_parent_category.id) }
  fab!(:unused_category) { Fabricate(:category, parent_category_id: workflow_parent_category.id) }
  fab!(:queue_step) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: review_category.id,
      position: 1,
      name: "Queue",
    )
  end
  fab!(:review_step) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: done_category.id,
      position: 2,
      name: "Review",
    )
  end
  fab!(:done_step) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: done_category.id,
      position: 3,
      name: "Done",
    )
  end
  fab!(:next_option) { Fabricate(:workflow_option, slug: "next", name: "Next") }
  fab!(:back_option) { Fabricate(:workflow_option, slug: "back", name: "Back") }
  fab!(:queue_to_done_option) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: queue_step.id,
      workflow_option_id: next_option.id,
      target_step_id: done_step.id,
      position: 1,
    )
  end

  before { sign_in(admin) }

  it "shows a list and overview tab for workflow step editing" do
    overview_page.visit_workflow(workflow)

    expect(overview_page).to have_steps_tab("List")
    expect(overview_page).to have_steps_tab("Overview")

    overview_page.switch_to_overview

    expect(overview_page).to have_overview
    expect(overview_page).to have_no_new_arrow_option_control
    expect(overview_page).to have_step(queue_step, text: "Queue")
    expect(overview_page).to have_connector_handles(queue_step)
    expect(overview_page).to have_lane(done_category, text: done_category.name)
    expect(overview_page).to have_lane(unused_category, text: unused_category.name)
  end

  it "routes arrows around intermediate step boxes" do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: review_step.id,
      workflow_option_id: back_option.id,
      target_step_id: queue_step.id,
      position: 1,
    )
    Fabricate(
      :workflow_step_option,
      workflow_step_id: done_step.id,
      workflow_option_id: back_option.id,
      target_step_id: review_step.id,
      position: 1,
    )

    overview_page.visit_workflow(workflow).switch_to_overview

    expect(overview_page).to have_arrow_link_for_option(queue_to_done_option)
    expect(overview_page).to have_no_arrow_crossing_step_boxes
    expect(overview_page).to have_no_double_back_arrow_paths
    expect(overview_page).to have_arrow_paths_within_lane_stack
    expect(overview_page).to have_no_arrow_travelling_along_lane_borders
    expect(overview_page).to have_lane_gap_travel_penalty
    expect(overview_page).to have_no_overlapping_arrow_segments
    expect(overview_page).to have_no_overlapping_option_dropdowns
    expect(overview_page).to have_no_option_dropdown_over_step_boxes_for(queue_to_done_option)
    expect(overview_page).to have_crossing_penalty_without_forbidding_routes
    expect(overview_page).to have_arrowhead_label_penalty
    expect(overview_page).to have_connector_line_label_penalty
    expect(overview_page).to have_horizontal_connector_under_dropdown_penalty
    expect(overview_page).to have_label_penalties_restored_for_return_connectors
    expect(overview_page).to have_own_arrowhead_included_in_label_penalties
    expect(overview_page).to have_other_arrowhead_label_penalty
    expect(overview_page).to have_midpoint_label_preference
    expect(overview_page).to have_alternate_label_position_can_win
    expect(overview_page).to have_label_lane_boundary_penalty
    expect(overview_page).to have_turn_count_penalty
    expect(overview_page).to have_lower_return_route_length_penalty
    expect(overview_page).to have_lane_escape_gutter_for_connector_handles
    expect(overview_page).to have_lower_escape_route_candidate
    expect(overview_page).to have_global_side_pair_route_scoring
    expect(overview_page).to have_option_on_longest_vertical_segment(queue_to_done_option)
    expect(overview_page).to have_forward_arrow_from_right_edge(queue_to_done_option)
  end

  it "creates and retargets arrows by dragging between step cards" do
    overview_page.visit_workflow(workflow).switch_to_overview

    overview_page.drag_connector(queue_step, review_step)

    expect(overview_page).to have_any_option_control
    step_option =
      DiscourseWorkflow::WorkflowStepOption.find_by!(
        workflow_step_id: queue_step.id,
        target_step_id: review_step.id,
      )
    expect(step_option.target_step_id).to eq(review_step.id)
    expect(overview_page).to have_arrow_link_for_option(step_option)
    expect(overview_page).to have_only_orthogonal_arrow_paths
    expect(overview_page).to have_forward_arrow_path

    overview_page.drag_existing_connector_target(review_step, done_step)

    expect(overview_page).to have_option(step_option)
    expect(step_option.reload.target_step_id).to eq(done_step.id)
  end

  it "updates arrow option labels from the connector dropdown" do
    overview_page.visit_workflow(workflow).switch_to_overview

    overview_page.select_option(queue_to_done_option, back_option)

    expect(queue_to_done_option.reload.workflow_option_id).to eq(back_option.id)
  end

  it "deletes arrows from the connector option control after confirmation" do
    overview_page.visit_workflow(workflow).switch_to_overview

    overview_page.delete_option(queue_to_done_option)

    expect(overview_page).to have_delete_connector_confirmation

    overview_page.confirm_delete_connector

    expect(DiscourseWorkflow::WorkflowStepOption.exists?(queue_to_done_option.id)).to eq(false)
    expect(overview_page).to have_no_css(
      ".workflow-overview-editor__edge-path[data-workflow-step-option-id='#{queue_to_done_option.id}']",
    )
    expect(overview_page).to have_no_css(
      ".workflow-overview-editor__option[data-workflow-step-option-id='#{queue_to_done_option.id}']",
    )
  end

  it "moves steps between swimlanes by dragging cards" do
    overview_page.visit_workflow(workflow).switch_to_overview

    overview_page.drag_step_to_lane_position(queue_step, done_category, 1)

    expect(overview_page).to have_step_in_lane(queue_step, done_category)
    expect(overview_page).to have_lane(review_category, text: review_category.name)
    expect(queue_step.reload.category_id).to eq(done_category.id)
  end

  it "moves steps into explicit x-axis positions" do
    overview_page.visit_workflow(workflow).switch_to_overview

    overview_page.drag_step_to_lane_position(done_step, review_category, 1)

    expect(overview_page).to have_step_in_lane_position(done_step, review_category, 1)
    expect(done_step.reload.category_id).to eq(review_category.id)
    expect(done_step.position).to eq(1)
    expect(queue_step.reload.position).to eq(3)
  end

  it "adds a step from the overview builder" do
    overview_page.visit_workflow(workflow).switch_to_overview

    overview_page.fill_new_step_name("QA").choose_new_step_category(review_category).add_step

    step = DiscourseWorkflow::WorkflowStep.find_by!(workflow_id: workflow.id, name: "QA")
    expect(step.category_id).to eq(review_category.id)
    expect(step.position).to eq(4)
    expect(overview_page).to have_step(step, text: "QA")
  end
end
