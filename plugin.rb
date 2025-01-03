# frozen_string_literal: true
# name: discourse-workflow
# about: A topic-based workflow engine for Discourse
# version: 0.0.1
# authors: Robert Barrow
# contact_emails: development@pavilion.tech
# url: https://github.com/merefield/discourse-workflow

enabled_site_setting :workflow_enabled

module ::DiscourseWorkflow
  PLUGIN_NAME = "discourse-workflow"
end

require_relative "lib/discourse_workflow/engine"

# register_asset 'stylesheets/common/locations.scss'
# register_asset 'stylesheets/desktop/locations.scss', :desktop
# register_asset 'stylesheets/mobile/locations.scss', :mobile
# register_asset 'lib/leaflet/leaflet.css'
# register_asset 'lib/leaflet/leaflet.js'
# register_asset 'lib/leaflet/leaflet.markercluster.js'
# register_asset 'lib/leaflet/MarkerCluster.css'
# register_asset 'lib/leaflet/MarkerCluster.Default.css'

# Discourse.top_menu_items.push(:workflows)
# Discourse.filters.push(:workflows)

# if respond_to?(:register_svg_icon)
#   register_svg_icon "far-map"
# end

after_initialize do

  # /lib/locations is autoloaded
  %w(
    ../app/models/discourse_workflow/workflow.rb
    ../app/models/discourse_workflow/workflow_step.rb
    ../app/models/discourse_workflow/workflow_option.rb
    ../app/models/discourse_workflow/workflow_step_option.rb
    ../app/models/discourse_workflow/workflow_state.rb
    ../app/serializers/discourse_workflow/workflow_step_option_serializer.rb
    ../app/serializers/discourse_workflow/workflow_step_serializer.rb
    ../app/serializers/discourse_workflow/workflow_serializer.rb
    ../app/controllers/discourse_workflow/admin/workflows_controller.rb
    ../app/controllers/discourse_workflow/admin/workflow_steps_controller.rb
    ../app/controllers/discourse_workflow/admin/workflow_step_options_controller.rb
    ../app/controllers/discourse_workflow/workflow_action_controller.rb
    ../config/routes.rb
    ../lib/discourse_workflow/topic_extension.rb
    ../lib/discourse_workflow/not_midway_validator.rb
  ).each do |path|
    load File.expand_path(path, __FILE__)
  end

  SeedFu.fixture_paths << Rails
  .root
  .join("plugins", "discourse-workflow", "db", "fixtures")
  .to_s

  add_admin_route("admin.discourse_workflow.title", "discourse-workflow", { use_new_show_route: true })

  #    ../app/serializers/discourse_workflow/workflow_option_serializer.rb 

  reloadable_patch { Topic.prepend(DiscourseWorkflow::TopicExtension) }

  # Category.register_custom_field_type('workflow_enabled', :boolean)
  # Category.register_custom_field_type('workflow_slug', :string)

  add_to_class(:category, :workflow_enabled) do
    WorkflowStep.find_by(category_id: self.id)&.step_id == 1 || false
  end

  add_to_class(:category, :workflow_slug) do
    Workflow.joins(:workflow_steps).where(workflow_steps: { category_id: self.id }).first&.slug
  end

  

  # [
  #   "workflow_enabled",
  #   "workflow_slug",
  # ].each do |key|
  #   Site.preloaded_category_custom_fields << key if Site.respond_to? :preloaded_category_custom_fields
  # end

  # Topic.register_custom_field_type('workflow_slug', :string)
  # Topic.register_custom_field_type('workflow_name', :integer)
  # Topic.register_custom_field_type('workflow_step_slug', :string)
  # Topic.register_custom_field_type('workflow_step_name', :string)
  add_to_class(:topic, :workflow_slug) do
    DiscourseWorkflow::WorkflowState
      .joins(:workflow)
      .where(topic_id: self.id)
      .select('workflows.slug')
      .first
      &.slug
  end
  add_to_class(:topic, :workflow_name) do
    DiscourseWorkflow::WorkflowState
      .joins(:workflow)
      .where(topic_id: self.id)
      .select('workflows.name')
      .first
      &.name
  end
  add_to_class(:topic, :workflow_step_slug) do
    DiscourseWorkflow::WorkflowState
      .joins(:workflow_step)
      .where(topic_id: self.id)
      .select('workflow_steps.slug')
      .first
      &.slug
  end
  add_to_class(:topic, :workflow_step_name) do 
    DiscourseWorkflow::WorkflowState
      .joins(:workflow_step)
      .where(topic_id: self.id)
      .select('workflow_steps.name')
      .first
      &.name
  end
  add_to_class(:topic, :workflow_step_position) do 
    DiscourseWorkflow::WorkflowState
      .joins(:workflow_step)
      .where(topic_id: self.id)
      .select('workflow_steps.position')
      .first
      &.position
  end
  add_to_class(:topic, :workflow_step_options) do 
    DiscourseWorkflow::WorkflowState
      .joins(workflow_step: { workflow_step_option: :workflow_option })
      .where(topic_id: self.id)
      .select('workflow_options.slug')
      .map(&:slug)
  end

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

  add_to_serializer(:topic_view, :workflow_step_position, include_condition: -> { object.topic.workflow_step_position.present? }) do
    object.topic.workflow_step_position
  end

  add_to_serializer(:topic_view, :workflow_step_options, include_condition: -> { object.topic.workflow_step_options.present? }) do
    object.topic.workflow_step_options
  end

  DiscourseEvent.on(:topic_created) do |*params|
    topic, opts = params

    if SiteSetting.workflow_enabled
      workflow_step = DiscourseWorkflow::WorkflowStep.find_by(category_id: topic.category_id, position: 1)
      if workflow_step
        DiscourseWorkflow::WorkflowState.create!(topic_id: topic.id, workflow_id: workflow_step.workflow_id, workflow_step_id: workflow_step.id)
      end
    end
  end



  # #TopicList.preloaded_custom_fields << 'workflow_name' if TopicList.respond_to? :preloaded_custom_fields
  # add_to_serializer(:topic_list_item, :workflow_name, include_condition: -> { object.workflow_name.present? }) do
  #   object.workflow_name
  # end

  # #TopicList.preloaded_custom_fields << 'workflow_step_name' if TopicList.respond_to? :preloaded_custom_fields
  # add_to_serializer(:topic_list_item, :workflow_step_name, include_condition: -> { object.workflow_step_name.present? }) do
  #   object.workflow_step_name
  # end

  # require_dependency 'topic_query'
  # class ::TopicQuery
  #   def list_workflows
  #     # @options[:per_page] = SiteSetting.location_map_max_topics
  #     create_list(:workflows) do |topics|
  #       topics = topics.joins("INNER JOIN workflows
  #                              ON workflow.slug = topics.custom_fields->>'workflow_slug'")

  #       Locations::Map.sorted_list_filters.each do |filter|
  #         topics = filter[:block].call(topics, @options)
  #       end

  #       topics
  #     end
  #   end
  # end

  # Locations::Map.add_list_filter do |topics, options|
  #   if options[:category_id]
  #     category = Category.find(options[:category_id])
  #   end

  #   if SiteSetting.location_map_filter_closed || (options[:category_id] && category.custom_fields['location_map_filter_closed'])
  #     topics = topics.where(closed: false)
  #   end

  #   topics
  # end

end
