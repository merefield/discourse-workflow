# frozen_string_literal: true
class CreateWorkflowState < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_states do |t|
      t.references :topic, foreign_key: true
      t.references :workflow, foreign_key: true
      t.references :worflow_step, foreign_key: true

      t.timestamps
    end
  end
end
