# frozen_string_literal: true

class AddUniqueDailyBucketIndexToWorkflowStats < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  INDEX_NAME = "idx_workflow_stats_daily_workflow_step_unique"

  def up
    remove_index(:workflow_stats, name: INDEX_NAME, if_exists: true, algorithm: :concurrently)

    add_index(
      :workflow_stats,
      %i[cob_date workflow_id workflow_step_id],
      unique: true,
      name: INDEX_NAME,
      algorithm: :concurrently,
    )
  end

  def down
    remove_index(:workflow_stats, name: INDEX_NAME, if_exists: true, algorithm: :concurrently)
  end
end
