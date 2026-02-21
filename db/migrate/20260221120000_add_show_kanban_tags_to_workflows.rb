# frozen_string_literal: true

class AddShowKanbanTagsToWorkflows < ActiveRecord::Migration[7.2]
  def change
    add_column :workflows, :show_kanban_tags, :boolean, default: true, null: false
  end
end
