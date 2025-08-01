
# frozen_string_literal: true
# rubocop:disable Discourse/NoAddReferenceOrAliasesActiveRecordMigration
class CreateWorkflowStats < ActiveRecord::Migration[7.2]
  def change
    create_table :workflow_stats do |t|
      t.datetime :cob_date
      t.references :workflow, foreign_key: true
      t.references :workflow_step, foreign_key: true
      t.integer :count

      t.timestamps
    end
  end
end
