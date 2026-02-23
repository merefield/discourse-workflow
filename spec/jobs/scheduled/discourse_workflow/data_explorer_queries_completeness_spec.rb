# frozen_string_literal: true

require_relative "../../../plugin_helper"

RSpec.describe Jobs::DiscourseWorkflow::DataExplorerQueriesCompleteness do
  let(:job) { described_class.new }
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }
  let(:query_class) do
    if defined?(::DiscourseDataExplorer::Query)
      ::DiscourseDataExplorer::Query
    else
      stub_const("DiscourseDataExplorer", Module.new)
      stub_const("DiscourseDataExplorer::Query", Class.new)
      ::DiscourseDataExplorer::Query
    end
  end

  before do
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
  end

  it "skips seeding and logs a warning when the data explorer table is unavailable" do
    allow(connection).to receive(:table_exists?).with(:data_explorer_queries).and_return(false)
    allow(Rails.logger).to receive(:warn)
    allow(DB).to receive(:exec)

    job.execute({})

    expect(Rails.logger).to have_received(:warn).with(
      "Skipping DataExplorerQueriesCompleteness: doesn't look like Data Explorer plugin is properly installed",
    )
    expect(DB).not_to have_received(:exec)
  end

  it "inserts both default queries when neither query exists" do
    allow(connection).to receive(:table_exists?).with(:data_explorer_queries).and_return(true)
    allow(query_class).to receive(:exists?).with(name: "Workflow Stats (default)").and_return(false)
    allow(query_class).to receive(:exists?).with(name: "Workflow Audit Log (default)").and_return(false)
    allow(DB).to receive(:exec)

    job.execute({})

    expect(DB).to have_received(:exec).twice
  end

  it "inserts only missing default queries when one query is already present" do
    allow(connection).to receive(:table_exists?).with(:data_explorer_queries).and_return(true)
    allow(query_class).to receive(:exists?).with(name: "Workflow Stats (default)").and_return(true)
    allow(query_class).to receive(:exists?).with(name: "Workflow Audit Log (default)").and_return(false)
    allow(DB).to receive(:exec)

    job.execute({})

    expect(DB).to have_received(:exec).once
  end
end
