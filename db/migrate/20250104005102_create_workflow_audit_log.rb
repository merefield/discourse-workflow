# frozen_string_literal: true
class CreateWorkflowAuditLog < ActiveRecord::Migration[7.2]
  def change
    create_table :workflow_audit_logs do |t|
      t.bigint :user_id
      t.string :username
      t.bigint :topic_id
      t.string :topic_title
      t.bigint :workflow_id
      t.string :workflow_name
      t.bigint :starting_step_id
      t.string :starting_step_name
      t.bigint :ending_step_id
      t.string :ending_step_name
      t.bigint :starting_category_id
      t.string :starting_category_name
      t.bigint :ending_category_id
      t.string :ending_category_name
      t.integer :starting_position
      t.integer :ending_position
      t.bigint :step_option_id
      t.string :step_option_name
      t.string :step_option_slug

      t.timestamps
    end
  end
end
