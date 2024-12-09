# frozen_string_literal: true
# name: discourse-workflow
# about: A topic-based workflow engine for Discourse
# version: 0.0.1
# authors: Robert Barrow
# contact_emails: development@pavilion.tech
# url: https://github.com/merefield/discourse-workflow

enabled_site_setting :workflow_enabled

module ::Locations
  PLUGIN_NAME = "discourse-workflow"
end

require_relative "lib/locations/engine"

# register_asset 'stylesheets/common/locations.scss'
# register_asset 'stylesheets/desktop/locations.scss', :desktop
# register_asset 'stylesheets/mobile/locations.scss', :mobile
# register_asset 'lib/leaflet/leaflet.css'
# register_asset 'lib/leaflet/leaflet.js'
# register_asset 'lib/leaflet/leaflet.markercluster.js'
# register_asset 'lib/leaflet/MarkerCluster.css'
# register_asset 'lib/leaflet/MarkerCluster.Default.css'

Discourse.top_menu_items.push(:workflows)
Discourse.filters.push(:workflows)

if respond_to?(:register_svg_icon)
  register_svg_icon "far-map"
end

after_initialize do

  # /lib/locations is autoloaded
  %w(
    ../app/models/location_country_default_site_setting.rb
    ../app/models/location_geocoding_language_site_setting.rb
    ../app/models/locations/user_location.rb
    ../app/models/locations/topic_location.rb
    ../app/serializers/locations/geo_location_serializer.rb
    ../app/controllers/locations/geocode_controller.rb
    ../app/controllers/locations/users_map_controller.rb
    ../lib/users_map.rb
  ).each do |path|
    load File.expand_path(path, __FILE__)
  end

  Category.register_custom_field_type('workflow_enabled', :boolean)
  Category.register_custom_field_type('workflow_slug', :string)

  add_to_class(:category, :workflow_enabled) do
    self.custom_fields['workflow_enabled'] == "true" || false
  end

  add_to_class(:category, :workflow_slug) do
    self.custom_fields['workflow_slug']
  end

  [
    "workflow_enabled",
    "workflow_slug",
  ].each do |key|
    Site.preloaded_category_custom_fields << key if Site.respond_to? :preloaded_category_custom_fields
  end

  Topic.register_custom_field_type('workflow_slug', :string)
  Topic.register_custom_field_type('workflow_name', :integer)
  Topic.register_custom_field_type('workflow_step_slug', :string)
  Topic.register_custom_field_type('workflow_step_name', :string)
  add_to_class(:topic, :workflow_slug) { self.custom_fields['workflow_slug'] }
  add_to_class(:topic, :workflow_name) { self.custom_fields['workflow_name'] }
  add_to_class(:topic, :workflow_step_slug) { self.custom_fields['workflow_step_slug'] }
  add_to_class(:topic, :workflow_step_name) { self.custom_fields['workflow_step_name'] }

  add_to_serializer(:topic_view, :workflow_slug, include_condition: -> { object.topic.workflow_slug.present? }) do
    object.topic.workflow_slug
  end

  add_to_serializer(:topic_view, :workflow_name, include_condition: -> { object.topic.workflow_name.present? }) do
    object.topic.workflow_name
  end

  add_to_serializer(:topic_view, :workflow_step_slug, include_condition: -> { object.topic.workflow_step_slug.present? }) do
    object.topic.workflow_step_slug
  end

  add_to_serializer(:topic_view, :workflow_step_name, include_condition: -> { object.topic.workflow_step_name.present? }) do
    object.topic.workflow_step_name
  end

  TopicList.preloaded_custom_fields << 'workflow_name' if TopicList.respond_to? :preloaded_custom_fields
  add_to_serializer(:topic_list_item, :workflow_name, include_condition: -> { object.workflow_name.present? }) do
    object.workflow_name
  end

  TopicList.preloaded_custom_fields << 'workflow_step_name' if TopicList.respond_to? :preloaded_custom_fields
  add_to_serializer(:topic_list_item, :workflow_step_name, include_condition: -> { object.workflow_step_name.present? }) do
    object.workflow_step_name
  end

  require_dependency 'topic_query'
  class ::TopicQuery
    def list_workflows
      # @options[:per_page] = SiteSetting.location_map_max_topics
      create_list(:workflows) do |topics|
        topics = topics.joins("INNER JOIN workflows
                               ON workflow.slug = topics.custom_fields->>'workflow_slug'")

        Locations::Map.sorted_list_filters.each do |filter|
          topics = filter[:block].call(topics, @options)
        end

        topics
      end
    end
  end

  Locations::Map.add_list_filter do |topics, options|
    if options[:category_id]
      category = Category.find(options[:category_id])
    end

    if SiteSetting.location_map_filter_closed || (options[:category_id] && category.custom_fields['location_map_filter_closed'])
      topics = topics.where(closed: false)
    end

    topics
  end

  DiscourseEvent.trigger(:locations_ready)
end
