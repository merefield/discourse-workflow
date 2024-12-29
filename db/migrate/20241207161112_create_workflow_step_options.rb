# frozen_string_literal: true
class CreateWorkflowStepOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_step_options do |t|
      t.integer :workflow_step_option_id
      t.references :workflow_step, foreign_key: true
      t.references :workflow_option, foreign_key: true
      t.integer :target_step_id

      t.timestamps
    end
  end
end
