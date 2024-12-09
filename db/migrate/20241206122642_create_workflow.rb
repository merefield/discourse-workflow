# frozen_string_literal: true
class CreateWorkflow < ActiveRecord::Migration[7.1]
  def change
    create_table :workflows do |t|
      t.string :slug
      t.text :description

      t.timestamps
    end
  end
end
