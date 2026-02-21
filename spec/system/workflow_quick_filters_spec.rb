# frozen_string_literal: true

RSpec.describe "Workflow quick filters", type: :system do
  fab!(:workflow_discovery_page) { PageObjects::Pages::WorkflowDiscovery.new }
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:workflow) { Fabricate(:workflow, name: "Quick Filter Workflow") }
  fab!(:kanban_tag) { Fabricate(:tag, name: "kanban-tag") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:category_3, :category)
  fab!(:step_1) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_1.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_2.id, position: 2)
  end
  fab!(:step_3) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_3.id, position: 3)
  end
  fab!(:next_option) { Fabricate(:workflow_option, slug: "next", name: "Next") }
  fab!(:finish_option) { Fabricate(:workflow_option, slug: "finish", name: "Finish") }
  fab!(:step_transition) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: next_option.id,
      target_step_id: step_2.id,
    )
  end
  fab!(:step_transition_2) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_2.id,
      workflow_option_id: finish_option.id,
      target_step_id: step_3.id,
    )
  end
  fab!(:topic_1) { Fabricate(:topic_with_op, category: category_1, user: user, tags: [kanban_tag]) }
  fab!(:topic_2) { Fabricate(:topic_with_op, category: category_1, user: user) }
  fab!(:workflow_state_1) do
    Fabricate(
      :workflow_state,
      topic_id: topic_1.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )
  end
  fab!(:workflow_state_2) do
    Fabricate(
      :workflow_state,
      topic_id: topic_2.id,
      workflow_id: workflow.id,
      workflow_step_id: step_2.id,
    )
  end

  before do
    enable_current_plugin
    SiteSetting.workflow_enabled = true
    SiteSetting.tagging_enabled = true
    category_1.set_permissions(everyone: :full, staff: :full)
    category_2.set_permissions(everyone: :readonly, staff: :full)
    category_3.set_permissions(everyone: :readonly, staff: :full)
    category_1.save!
    category_2.save!
    category_3.save!
    topic_2.update_columns(category_id: category_2.id)
    workflow_state_1.update_columns(updated_at: 5.days.ago)
    sign_in(user)
  end

  it "filters workflow topics by step position via workflow query params" do
    page.visit("/workflow?workflow_step_position=2")

    expect(page).to have_content(topic_2.title)
    expect(page).to have_no_content(topic_1.title)
  end

  it "filters workflow topics by overdue days via workflow query params" do
    page.visit("/workflow?overdue_days=3")

    expect(page).to have_content(topic_1.title)
    expect(page).to have_no_content(topic_2.title)
  end

  it "filters workflow topics to categories where the user can create topics" do
    page.visit("/workflow?my_categories=1")

    expect(page).to have_content(topic_1.title)
    expect(page).to have_no_content(topic_2.title)
  end

  it "applies my categories from the quick filter controls" do
    workflow_discovery_page.visit_workflow
    expect(workflow_discovery_page).to have_quick_filters

    workflow_discovery_page.toggle_my_categories

    expect(page).to have_current_path(%r{/workflow\?.*my_categories=1}, url: true)
    expect(page).to have_content(topic_1.title)
    expect(page).to have_no_content(topic_2.title)
  end

  it "applies overdue quick filter from controls" do
    workflow_discovery_page.visit_workflow
    expect(workflow_discovery_page).to have_quick_filters

    workflow_discovery_page.toggle_overdue
    expect(page).to have_current_path(%r{/workflow\?.*overdue=1}, url: true)
    expect(page).to have_content(topic_1.title)
    expect(page).to have_no_content(topic_2.title)
  end

  it "applies step quick filter from controls" do
    workflow_discovery_page.visit_workflow
    expect(workflow_discovery_page).to have_quick_filters

    workflow_discovery_page.set_step_filter(2)
    expect(page).to have_current_path(%r{/workflow\?.*workflow_step_position=2}, url: true)
    expect(page).to have_content(topic_2.title)
    expect(page).to have_no_content(topic_1.title)
    expect(page).to have_css(".workflow-quick-filters__apply-step.btn-primary")
  end

  it "toggles step quick filter and active state on repeated apply" do
    workflow_discovery_page.visit_workflow
    expect(workflow_discovery_page).to have_quick_filters
    expect(page).to have_css(".workflow-quick-filters__apply-step.btn-default")

    workflow_discovery_page.set_step_filter(2)
    expect(page).to have_current_path(%r{/workflow\?.*workflow_step_position=2}, url: true)
    expect(page).to have_css(".workflow-quick-filters__apply-step.btn-primary")

    workflow_discovery_page.set_step_filter(2)
    expect(page).to have_current_path("/workflow", url: false)
    expect(page).to have_css(".workflow-quick-filters__apply-step.btn-default")
  end

  it "does not redirect repeatedly when saved filters contain empty values" do
    page.visit("/")
    page.execute_script(
      "localStorage.setItem('discourse_workflow_quick_filters', JSON.stringify({ my_categories: null, overdue_days: null, workflow_step_position: '' }))",
    )

    workflow_discovery_page.visit_workflow

    expect(page).to have_current_path("/workflow", url: false)
    expect(workflow_discovery_page).to have_quick_filters
  end

  it "updates filters without a full page reload" do
    workflow_discovery_page.visit_workflow
    page.execute_script("window.__workflowNoReloadMarker = 'alive'")

    workflow_discovery_page.toggle_my_categories

    expect(page).to have_current_path(%r{/workflow\?.*my_categories=1}, url: true)
    expect(page.evaluate_script("window.__workflowNoReloadMarker")).to eq("alive")
  end

  it "toggles quick filter button state and query params on repeated click" do
    workflow_discovery_page.visit_workflow

    expect(page).to have_css(".workflow-quick-filters__my-categories.btn-default")

    workflow_discovery_page.toggle_my_categories
    expect(page).to have_current_path(%r{/workflow\?.*my_categories=1}, url: true)
    expect(page).to have_css(".workflow-quick-filters__my-categories.btn-primary")

    workflow_discovery_page.toggle_my_categories
    expect(page).to have_current_path("/workflow", url: false)
    expect(page).to have_css(".workflow-quick-filters__my-categories.btn-default")
  end

  it "shows overdue state in a dedicated workflow list column" do
    workflow_discovery_page.visit_workflow

    expect(page).to have_css("th.workflow-overdue-column")
    expect(page).to have_css("tr[data-topic-id='#{topic_1.id}'] .workflow-overdue-indicator")
    expect(page).to have_no_css("tr[data-topic-id='#{topic_2.id}'] .workflow-overdue-indicator")
  end

  it "shows kanban toggle only when the current list is a single compatible workflow" do
    workflow_discovery_page.visit_workflow

    expect(workflow_discovery_page).to have_workflow_view_toggle
  end

  it "toggles between workflow list and kanban board view" do
    workflow_discovery_page.visit_workflow
    expect(page).to have_css(".topic-list")
    expect(page).to have_no_css(".workflow-kanban")

    workflow_discovery_page.toggle_workflow_view

    expect(page).to have_current_path(%r{/workflow\?.*workflow_view=kanban}, url: true)
    expect(workflow_discovery_page).to have_kanban_board
    expect(workflow_discovery_page).to have_kanban_column_for_step(1)
    expect(workflow_discovery_page).to have_kanban_column_for_step(2)
    expect(workflow_discovery_page).to have_kanban_column_for_step(3)
    expect(workflow_discovery_page).to have_kanban_card_for_topic(topic_1.id)
    expect(workflow_discovery_page).to have_kanban_card_for_topic(topic_2.id)
    expect(page).to have_no_css(".topic-list")
    expect(page).to have_css(".workflow-quick-filters__workflow-view.btn-primary")

    workflow_discovery_page.toggle_workflow_view

    expect(page).to have_current_path("/workflow", url: false)
    expect(page).to have_css(".topic-list")
    expect(page).to have_no_css(".workflow-kanban")
    expect(page).to have_css(".workflow-quick-filters__workflow-view.btn-default")
  end

  it "supports drag-drop transitions with legal and illegal column highlighting" do
    workflow_discovery_page.visit_workflow
    workflow_discovery_page.toggle_workflow_view

    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 1)
    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_2.id, 2)

    workflow_discovery_page.start_drag_on_kanban_card(topic_1.id)

    expect(workflow_discovery_page).to have_kanban_legal_drop_target_for_step(2)
    expect(workflow_discovery_page).to have_kanban_illegal_drop_target_for_step(3)

    workflow_discovery_page.end_drag_on_kanban_card(topic_1.id)
    workflow_discovery_page.drag_kanban_card_to_step(topic_1.id, 3)

    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 1)

    workflow_discovery_page.drag_kanban_card_to_step(topic_1.id, 2)

    expect(workflow_discovery_page).to have_no_kanban_card_for_topic_in_step(topic_1.id, 1)
    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 2)
  end

  it "supports keyboard arrow transitions for focused kanban cards when legal" do
    workflow_discovery_page.visit_workflow
    workflow_discovery_page.toggle_workflow_view

    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 1)

    workflow_discovery_page.move_kanban_card_with_key(topic_1.id, "ArrowRight")
    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 2)

    workflow_discovery_page.move_kanban_card_with_key(topic_1.id, "ArrowLeft")
    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 2)
  end

  it "refreshes kanban view after stale transition errors to re-sync backend state" do
    workflow_discovery_page.visit_workflow
    workflow_discovery_page.toggle_workflow_view

    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 1)

    # Simulate another actor advancing this item after the client has loaded.
    workflow_state_1.update_columns(workflow_step_id: step_2.id)

    workflow_discovery_page.drag_kanban_card_to_step(topic_1.id, 2)

    expect(page).to have_css(
      ".dialog-body",
      text:
        "Transition Failed: probably due to stale UI state - please try again after refresh - refreshing!",
    )
    find("#dialog-holder .btn-primary").click
    expect(workflow_discovery_page).to have_no_kanban_card_for_topic_in_step(topic_1.id, 1)
    expect(workflow_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 2)
  end

  it "shows kanban card tags when enabled on the workflow and hides them when disabled" do
    workflow_discovery_page.visit_workflow
    workflow_discovery_page.toggle_workflow_view

    expect(workflow_discovery_page).to have_kanban_tag_for_topic(topic_1.id, "kanban-tag")

    workflow.update!(show_kanban_tags: false)
    workflow_discovery_page.visit_workflow
    workflow_discovery_page.toggle_workflow_view

    expect(workflow_discovery_page).to have_no_kanban_tag_for_topic(topic_1.id, "kanban-tag")
  end

  it "does not show kanban toggle when the workflow list includes multiple workflows" do
    other_workflow = Fabricate(:workflow, name: "Second Workflow")
    other_step =
      Fabricate(
        :workflow_step,
        workflow_id: other_workflow.id,
        category_id: category_1.id,
        position: 1,
      )
    other_topic = Fabricate(:topic_with_op, category: category_1, user: user)
    Fabricate(
      :workflow_state,
      topic_id: other_topic.id,
      workflow_id: other_workflow.id,
      workflow_step_id: other_step.id,
    )

    workflow_discovery_page.visit_workflow

    expect(workflow_discovery_page).to have_no_workflow_view_toggle
  end
end
