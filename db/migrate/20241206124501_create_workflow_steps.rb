# frozen_string_literal: true
class CreateWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_steps do |t|
      t.references :workflow, foreign_key: true
      t.references :category, foreign_key: true
      t.integer :workflow_step_id
      t.string :slug
      t.string :name
      t.string :description
      t.string :step_type

      t.timestamps
    end
  end
end
