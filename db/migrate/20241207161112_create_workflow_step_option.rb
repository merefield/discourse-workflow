# frozen_string_literal: true
class CreateWorkflowStepOption < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_step_options do |t|
      t.references :workflow_step_id, foreign_key: true
      t.string :slug
      t.integer :target_step_id

      t.timestamps
    end
  end
end
