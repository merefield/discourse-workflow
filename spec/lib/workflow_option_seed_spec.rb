# frozen_string_literal: true

require "yaml"
require_relative "../plugin_helper"

describe "Workflow option seed and client translation parity" do
  it "keeps every seeded option slug aligned with client option keys" do
    fixtures_path =
      File.expand_path("../../db/fixtures/001_workflow._options.rb", __dir__)
    client_locale_path =
      File.expand_path("../../config/locales/client.en.yml", __dir__)

    fixture_slugs = File.read(fixtures_path).scan(/slug:\s*'([^']+)'/).flatten
    option_keys =
      YAML
        .safe_load_file(client_locale_path)
        .dig("en", "js", "discourse_workflow", "options")
        .keys

    expect(option_keys).to include(*fixture_slugs)
    expect(fixture_slugs).to include(*option_keys)
  end
end
