# frozen_string_literal: true
class CreateWorkflows < ActiveRecord::Migration[7.1]
  def change
    create_table :workflows do |t|
      t.string :slug
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
