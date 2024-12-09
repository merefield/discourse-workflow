# frozen_string_literal: true
class CreateWorkflowStep < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_steps do |t|
      t.references :workflow, foreign_key: true
      t.integer :step_id
      t.string :slug
      t.string :description
      t.string :type
      t.string :action_groups
      t.string :category_slug

      t.timestamps
    end
  end
end
