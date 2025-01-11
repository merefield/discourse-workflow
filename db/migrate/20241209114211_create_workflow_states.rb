# frozen_string_literal: true

# rubocop:disable Discourse/NoAddReferenceOrAliasesActiveRecordMigration
class CreateWorkflowStates < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_states do |t|
      t.references :topic, foreign_key: true
      t.references :workflow, foreign_key: true
      t.references :workflow_step, foreign_key: true

      t.timestamps
    end
  end
end
