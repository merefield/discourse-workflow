# frozen_string_literal: true
class CreateWorkflowOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :workflow_options do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
  end
end
