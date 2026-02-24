# frozen_string_literal: true

class AddUpdatedAtIndexToWorkflowStates < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  INDEX_NAME = "idx_workflow_states_updated_at"

  def up
    remove_index(:workflow_states, name: INDEX_NAME, if_exists: true, algorithm: :concurrently)
    add_index(:workflow_states, :updated_at, name: INDEX_NAME, algorithm: :concurrently)
  end

  def down
    remove_index(:workflow_states, name: INDEX_NAME, if_exists: true, algorithm: :concurrently)
  end
end
