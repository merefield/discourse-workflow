# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe DiscourseWorkflow::WorkflowState do
  it "has an updated_at index for overdue filtering queries" do
    index_columns = described_class.connection.indexes(described_class.table_name).map(&:columns)

    expect(index_columns).to include(["updated_at"])
  end
end
