Fabricator(:workflow_step_option, class_name: "DiscourseWorkflow::WorkflowStepOption") do
  workflow_option_id { Fabricate(:workflow_option).id }
  workflow_step_id { Fabricate(:workflow_step).id }
  position { sequence(:step_option_position) { |i| i } }
  target_step_id { Fabricate(:workflow_step).id }
end