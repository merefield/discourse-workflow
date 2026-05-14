# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Workflow admin visual" do
  let(:visual_page) { PageObjects::Pages::WorkflowAdminVisual.new }

  fab!(:admin)
  fab!(:workflow) { Fabricate(:workflow, name: "Visual workflow") }
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

  it "shows a list and visual tab for workflow step editing" do
    visual_page.visit_workflow(workflow)

    expect(visual_page).to have_steps_tab("List")
    expect(visual_page).to have_steps_tab("Visual")

    visual_page.switch_to_visual

    expect(visual_page).to have_visual
    expect(visual_page).to have_no_new_arrow_option_control
    expect(visual_page).to have_step(queue_step, text: "Queue")
    expect(visual_page).to have_step_width_ratio(queue_step, 0.6)
    expect(visual_page).to have_centered_step_label(queue_step)
    expect(visual_page).to have_step_centered_in_lane_content(queue_step)
    expect(visual_page).to have_connector_handles(queue_step)
    expect(visual_page).to have_lane(done_category, text: done_category.name)
    expect(visual_page).to have_lane(unused_category, text: unused_category.name)
  end

  context "with return connectors" do
    before do
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

      visual_page.visit_workflow(workflow).switch_to_visual
    end

    it "routes visible arrows around intermediate step boxes" do
      expect(visual_page).to have_arrow_link_for_option(queue_to_done_option)
      expect(visual_page).to have_no_arrow_crossing_step_boxes
      expect(visual_page).to have_no_double_back_arrow_paths
      expect(visual_page).to have_arrow_paths_within_lane_stack
      expect(visual_page).to have_no_arrow_travelling_along_lane_borders
      expect(visual_page).to have_no_overlapping_arrow_segments
      expect(visual_page).to have_forward_arrow_from_right_edge(queue_to_done_option)
    end

    it "keeps connector option controls readable" do
      expect(visual_page).to have_no_overlapping_option_dropdowns
      expect(visual_page).to have_no_option_dropdown_over_step_boxes_for(queue_to_done_option)
    end

    it "places option controls on readable vertical route segments" do
      expect(visual_page).to have_option_on_longest_vertical_segment(queue_to_done_option)
    end
  end

  it "creates and retargets arrows by dragging between step cards" do
    visual_page.visit_workflow(workflow).switch_to_visual

    visual_page.drag_connector(queue_step, review_step)

    expect(visual_page).to have_any_option_control
    step_option =
      DiscourseWorkflow::WorkflowStepOption.find_by!(
        workflow_step_id: queue_step.id,
        target_step_id: review_step.id,
      )
    expect(step_option.target_step_id).to eq(review_step.id)
    expect(visual_page).to have_arrow_link_for_option(step_option)
    expect(visual_page).to have_only_orthogonal_arrow_paths
    expect(visual_page).to have_forward_arrow_path

    visual_page.drag_existing_connector_target(review_step, done_step)

    expect(visual_page).to have_option(step_option)
    expect(step_option.reload.target_step_id).to eq(done_step.id)
  end

  it "updates arrow option labels from the connector dropdown" do
    visual_page.visit_workflow(workflow).switch_to_visual

    expect(visual_page).to have_option(queue_to_done_option)

    visual_page.track_requests
    visual_page.select_option(queue_to_done_option, back_option)

    expect(queue_to_done_option.reload.workflow_option_id).to eq(back_option.id)
    expect(visual_page).to have_tracked_request("/workflow_steps.json")
    expect(visual_page.tracked_request_count("/workflow_options.json")).to eq(0)
  end

  it "preserves scroll position after visual workflow changes" do
    visual_page.visit_workflow(workflow).switch_to_visual
    visual_page.make_page_scrollable.scroll_window_to(500)

    scroll_y = visual_page.window_scroll_y

    visual_page.select_option(queue_to_done_option, back_option)

    expect(queue_to_done_option.reload.workflow_option_id).to eq(back_option.id)
    expect(visual_page).to have_window_scroll_y(scroll_y)
  end

  it "deletes arrows from the connector option control after confirmation" do
    visual_page.visit_workflow(workflow).switch_to_visual

    visual_page.delete_option(queue_to_done_option)

    expect(visual_page).to have_delete_connector_confirmation

    visual_page.confirm_delete_connector

    expect(DiscourseWorkflow::WorkflowStepOption.exists?(queue_to_done_option.id)).to eq(false)
    expect(visual_page).to have_no_css(
      ".workflow-visual-editor__edge-path[data-workflow-step-option-id='#{queue_to_done_option.id}']",
    )
    expect(visual_page).to have_no_css(
      ".workflow-visual-editor__option[data-workflow-step-option-id='#{queue_to_done_option.id}']",
    )
  end

  it "deletes steps and their incoming and outgoing connectors after confirmation" do
    incoming_option =
      Fabricate(
        :workflow_step_option,
        workflow_step_id: queue_step.id,
        workflow_option_id: next_option.id,
        target_step_id: review_step.id,
        position: 2,
      )
    outgoing_option =
      Fabricate(
        :workflow_step_option,
        workflow_step_id: review_step.id,
        workflow_option_id: next_option.id,
        target_step_id: done_step.id,
        position: 1,
      )

    visual_page.visit_workflow(workflow).switch_to_visual

    visual_page.delete_step(review_step)

    expect(visual_page).to have_delete_step_confirmation

    visual_page.confirm_delete_step

    expect(DiscourseWorkflow::WorkflowStep.exists?(review_step.id)).to eq(false)
    expect(DiscourseWorkflow::WorkflowStepOption.exists?(incoming_option.id)).to eq(false)
    expect(DiscourseWorkflow::WorkflowStepOption.exists?(outgoing_option.id)).to eq(false)
    expect(DiscourseWorkflow::WorkflowStepOption.exists?(queue_to_done_option.id)).to eq(true)
    expect(visual_page).to have_no_step(review_step)
    expect(visual_page).to have_no_css(
      ".workflow-visual-editor__edge-path[data-workflow-step-option-id='#{incoming_option.id}']",
    )
    expect(visual_page).to have_no_css(
      ".workflow-visual-editor__edge-path[data-workflow-step-option-id='#{outgoing_option.id}']",
    )
  end

  it "moves steps between swimlanes by dragging cards" do
    visual_page.visit_workflow(workflow).switch_to_visual

    visual_page.drag_step_to_lane_position(queue_step, done_category, 1)

    expect(visual_page).to have_step_in_lane(queue_step, done_category)
    expect(visual_page).to have_lane(review_category, text: review_category.name)
    expect(queue_step.reload.category_id).to eq(done_category.id)
  end

  it "removes stale lanes while preserving server-scoped empty sibling lanes" do
    orphan_parent_category = Fabricate(:category)
    orphan_category = Fabricate(:category, parent_category_id: orphan_parent_category.id)
    orphan_step =
      Fabricate(
        :workflow_step,
        workflow_id: workflow.id,
        category_id: orphan_category.id,
        position: 4,
        name: "Temporary lane",
      )

    visual_page.visit_workflow(workflow).switch_to_visual

    expect(visual_page).to have_lane(orphan_category, text: orphan_category.name)

    orphan_step.destroy!

    visual_page.fill_new_step_name("QA").choose_new_step_category(review_category).add_step

    expect(visual_page).to have_no_lane(orphan_category)
    expect(visual_page).to have_lane(unused_category, text: unused_category.name)
  end

  it "moves steps into explicit x-axis positions" do
    visual_page.visit_workflow(workflow).switch_to_visual

    visual_page.drag_step_to_lane_position(done_step, review_category, 1)

    expect(visual_page).to have_step_in_lane_position(done_step, review_category, 1)
    expect(done_step.reload.category_id).to eq(review_category.id)
    expect(done_step.position).to eq(1)
    expect(queue_step.reload.position).to eq(3)
  end

  it "adds a step from the visual builder" do
    visual_page.visit_workflow(workflow).switch_to_visual

    visual_page.fill_new_step_name("QA").choose_new_step_category(review_category).add_step

    step = DiscourseWorkflow::WorkflowStep.find_by!(workflow_id: workflow.id, name: "QA")
    expect(step.category_id).to eq(review_category.id)
    expect(step.position).to eq(4)
    expect(visual_page).to have_step(step, text: "QA")
  end

  it "opens the new step form from a swimlane with the category preselected" do
    visual_page.visit_workflow(workflow).switch_to_visual

    visual_page.add_step_from_lane(done_category)

    expect(visual_page).to have_new_step_editor
    expect(visual_page).to have_new_step_category(done_category)
  end
end
