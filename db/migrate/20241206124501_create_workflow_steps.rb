# frozen_string_literal: true

# rubocop:disable Discourse/NoAddReferenceOrAliasesActiveRecordMigration
class CreateWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_steps do |t|
      t.references :workflow, foreign_key: true
      t.references :category, foreign_key: true
      t.integer :position
      t.string :slug
      t.string :name
      t.text :description
      t.boolean :ai_enabled, default: false
      t.text :ai_prompt

      t.timestamps
    end
  end
end
