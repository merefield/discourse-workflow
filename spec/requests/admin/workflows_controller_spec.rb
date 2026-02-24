# frozen_string_literal: true

require_relative "../../plugin_helper"

describe DiscourseWorkflow::Admin::WorkflowsController do
  fab!(:admin)
  fab!(:workflow) { Fabricate(:workflow, name: "Controller Workflow") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_1.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_2.id, position: 2)
  end

  before { sign_in(admin) }

  it "serializes kanban compatibility for incompatible workflows" do
    get "/admin/plugins/discourse-workflow/workflows.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body["workflows"].find { |w| w["id"] == workflow.id }
    expect(payload["kanban_compatible"]).to eq(false)
    expect(payload["show_kanban_tags"]).to eq(true)
  end

  it "serializes kanban compatibility for compatible workflows" do
    option = Fabricate(:workflow_option, slug: "next", name: "Next")
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option.id,
      target_step_id: step_2.id,
    )

    get "/admin/plugins/discourse-workflow/workflows.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body["workflows"].find { |w| w["id"] == workflow.id }
    expect(payload["kanban_compatible"]).to eq(true)
  end

  it "updates show_kanban_tags on a workflow" do
    put "/admin/plugins/discourse-workflow/workflows/#{workflow.id}.json",
        params: {
          workflow: {
            show_kanban_tags: false,
          },
        }

    expect(response.status).to eq(200)
    expect(workflow.reload.show_kanban_tags).to eq(false)
  end

  it "does not add per-workflow queries when serializing the index" do
    option = Fabricate(:workflow_option, slug: "next-query", name: "Next Query")
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option.id,
      target_step_id: step_2.id,
    )

    get "/admin/plugins/discourse-workflow/workflows.json"
    base_query_count =
      track_sql_queries do
        get "/admin/plugins/discourse-workflow/workflows.json"
        expect(response.status).to eq(200)
      end.count

    5.times do |index|
      extra_workflow = Fabricate(:workflow, name: "Controller Workflow #{index + 2}")
      category_3 = Fabricate(:category)
      category_4 = Fabricate(:category)
      extra_step_1 =
        Fabricate(
          :workflow_step,
          workflow_id: extra_workflow.id,
          category_id: category_3.id,
          position: 1,
        )
      extra_step_2 =
        Fabricate(
          :workflow_step,
          workflow_id: extra_workflow.id,
          category_id: category_4.id,
          position: 2,
        )
      Fabricate(
        :workflow_step_option,
        workflow_step_id: extra_step_1.id,
        workflow_option_id: option.id,
        target_step_id: extra_step_2.id,
      )
    end

    get "/admin/plugins/discourse-workflow/workflows.json"
    expanded_query_count =
      track_sql_queries do
        get "/admin/plugins/discourse-workflow/workflows.json"
        expect(response.status).to eq(200)
      end.count

    expect(expanded_query_count).to be <= base_query_count + 2
  end
end
