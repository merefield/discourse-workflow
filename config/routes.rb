Discourse::Application.routes.draw do
  mount ::DiscourseWorkflow::Engine, at: "discourse-workflow"

  scope "/admin/plugins/discourse-workflow" do
    resources :workflows,
       controller: "discourse_workflow/admin/workflows" do 
      resources :workflow_steps,
          only: %i[index edit show],
          controller: "discourse_workflow/admin/workflow_steps" do
        resources :workflow_step_options,
          only: %i[index edit show],
          controller: "discourse_workflow/admin/workflow_step_options"
          end
      end
    resources :workflow_steps,
              only: %i[create update destroy],
              path: "workflow_steps",
              controller: "discourse_workflow/admin/workflow_steps"
    resources :workflow_step_options,
              only: %i[create update destroy],
              path: "workflow_step_options",
              controller: "discourse_workflow/admin/workflow_step_options"
    resources :workflow_options,
              only: %i[index],
              path: "workflow_options",
              controller: "discourse_workflow/admin/workflow_options"
  end
end