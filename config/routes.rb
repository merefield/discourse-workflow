Discourse::Application.routes.draw do
  mount ::DiscourseWorkflow::Engine, at: "discourse-workflow"

  scope "/admin/plugins/discourse-workflow" do
    resources :workflows,
       controller: "discourse_workflow/admin/workflows" do 
      resources :workflow_steps,
          controller: "discourse_workflow/admin/workflow_steps"
      end
              #   only: %i[index create edit show update destroy],
              #   path: "workflow_steps",
              #   controller: "discourse_workflow/admin/workflow_steps"
              # end
    # resources :workflow_steps,
    #           only: %i[edit],
    #           path: "workflows/workflow_steps",
    #           controller: "discourse_workflow/admin/workflow_steps"
    # resources :workflow_step_options,
    #           only: %i[index create edit show update destroy],
    #           path: "workflow_step_options",
    #           controller: "discourse_workflow/admin/workflow_step_options"
    # resources :workflow_options,
    #           only: %i[index],
    #           path: "workflow_options",
    #           controller: "discourse_workflow/admin/workflow_options"
  end
end


# resources :workflows,
# only: %i[index create edit show update destroy],
# path: "workflows",
# controller: "discourse_workflow/admin/workflows" do
# resources :workflow_steps,
#   only: %i[index create edit show update destroy],
#   path: "workflow_steps",
#   controller: "discourse_workflow/admin/workflow_steps"
# end
  # DiscourseWorkflow::Engine.routes.draw do