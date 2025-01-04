module ::DiscourseWorkflow
  class WorkflowAuditLog < ActiveRecord::Base
    self.table_name = 'workflow_audit_logs'
  end
end