# frozen_string_literal: true

class AddOverdueDaysToWorkflowsAndSteps < ActiveRecord::Migration[7.2]
  def up
    add_column :workflows, :overdue_days, :integer
    add_column :workflow_steps, :overdue_days, :integer
  end

  def down
    remove_column :workflow_steps, :overdue_days
    remove_column :workflows, :overdue_days
  end
end
