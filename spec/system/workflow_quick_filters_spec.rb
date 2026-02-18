# frozen_string_literal: true

RSpec.describe "Workflow quick filters", type: :system do
  fab!(:workflow_discovery_page) { PageObjects::Pages::WorkflowDiscovery.new }
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:workflow) { Fabricate(:workflow, name: "Quick Filter Workflow") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_1.id,
      position: 1,
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_2.id,
      position: 2,
    )
  end
  fab!(:topic_1) { Fabricate(:topic_with_op, category: category_1, user: user) }
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
    category_1.set_permissions(everyone: :full, staff: :full)
    category_2.set_permissions(everyone: :readonly, staff: :full)
    category_1.save!
    category_2.save!
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
    expect(page).to have_current_path(
      %r{/workflow\?.*workflow_step_position=2},
      url: true,
    )
    expect(page).to have_content(topic_2.title)
    expect(page).to have_no_content(topic_1.title)
    expect(page).to have_css(".workflow-quick-filters__apply-step.btn-primary")
  end

  it "toggles step quick filter and active state on repeated apply" do
    workflow_discovery_page.visit_workflow
    expect(workflow_discovery_page).to have_quick_filters
    expect(page).to have_css(".workflow-quick-filters__apply-step.btn-default")

    workflow_discovery_page.set_step_filter(2)
    expect(page).to have_current_path(
      %r{/workflow\?.*workflow_step_position=2},
      url: true,
    )
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
    expect(
      page,
    ).to have_css("tr[data-topic-id='#{topic_1.id}'] .workflow-overdue-indicator")
    expect(
      page,
    ).to have_no_css("tr[data-topic-id='#{topic_2.id}'] .workflow-overdue-indicator")
  end
end
