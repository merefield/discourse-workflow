# frozen_string_literal: true

Fabricator(:workflow_stat, from: "DiscourseWorkflow::WorkflowStat") do
  cob_date { Date.current }
  count { 0 }
  workflow
  workflow_step
end
