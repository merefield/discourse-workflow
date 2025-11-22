# frozen_string_literal: true
# name: discourse-workflow
# about: A topic-based workflow engine for Discourse
# version: 0.1.0
# authors: Robert Barrow
# contact_emails: robert@pavilion.tech
# url: https://github.com/merefield/discourse-workflow

gem "event_stream_parser", "1.0.0", { require: false }
gem "ruby-openai", "8.1.0", { require: false }

enabled_site_setting :workflow_enabled

register_asset "stylesheets/common/workflow_common.scss"
register_asset "stylesheets/desktop/workflow_desktop.scss", :desktop
register_asset "stylesheets/mobile/workflow_mobile.scss", :mobile

module ::DiscourseWorkflow
  PLUGIN_NAME = "discourse-workflow"
end

require_relative "lib/discourse_workflow/engine"

register_svg_icon "right-left" if respond_to?(:register_svg_icon)

after_initialize do
  reloadable_patch do
    ListController.prepend(DiscourseWorkflow::ListControllerExtension)
    TopicQuery.prepend(DiscourseWorkflow::TopicQueryExtension)
    Topic.prepend(DiscourseWorkflow::TopicExtension)
    Notification.singleton_class.prepend(
      DiscourseWorkflow::NotificationExtension
    )
  end

  register_topic_preloader_associations(
    { workflow_state: %i[workflow workflow_step] }
  ) { SiteSetting.workflow_enabled }

  Discourse.top_menu_items.push(:workflow)
  Discourse.anonymous_top_menu_items.push(:workflow)
  Discourse.filters.push(:workflow)
  Discourse.anonymous_filters.push(:workflow)

  SeedFu.fixture_paths << Rails
    .root
    .join("plugins", "discourse-workflow", "db", "fixtures")
    .to_s

  add_admin_route(
    "admin.discourse_workflow.title",
    "discourse-workflow",
    { use_new_show_route: true }
  )

  add_to_class(:category, :workflow_enabled) do
    WorkflowStep.find_by(category_id: self.id)&.step_id == 1 || false
  end

  add_to_class(:category, :workflow_slug) do
    Workflow
      .joins(:workflow_steps)
      .where(workflow_steps: { category_id: self.id })
      .first
      &.slug
  end

  # prevent non-staff from changing category on a workflow topic
  PostRevisor.track_topic_field(:category_id) do |tc, category_id|
    if tc.guardian.is_staff?
      tc.record_change("category_id", tc.topic.category_id, category_id)
      tc.topic.category_id = category_id
    else
      if ::DiscourseWorkflow::WorkflowState.find_by(
           topic_id: tc.topic.id
         ).present?
        # TODO get this to work and add a translation
        tc.topic.errors.add(
          :base,
          :workflow,
          message:
            "you can't change category on a workflow topic unless you are staff"
        )
        next
      else
        tc.record_change("category_id", tc.topic.category_id, category_id)
        tc.topic.category_id = category_id
      end
    end
  end

  add_to_class(:topic, :workflow_slug) { workflow_state&.workflow&.slug }

  add_to_class(:topic, :workflow_name) { workflow_state&.workflow&.name }

  add_to_class(:topic, :workflow_step_slug) do
    workflow_state&.workflow_step&.slug
  end

  add_to_class(:topic, :workflow_step_name) do
    workflow_state&.workflow_step&.name
  end

  add_to_class(:topic, :workflow_step_position) do
    workflow_state&.workflow_step&.position
  end

  add_to_class(:topic, :workflow_step_options) do
    step = workflow_state&.workflow_step
    return [] unless step

    step
      .workflow_step_options
      .includes(:workflow_option)
      .order(:position)
      .map { |wso| wso.workflow_option.slug }
  end

  add_to_serializer(
    :topic_view,
    :workflow_slug,
    include_condition: -> { object.topic.workflow_slug.present? }
  ) { object.topic.workflow_slug }

  add_to_serializer(
    :topic_view,
    :workflow_name,
    include_condition: -> { object.topic.workflow_name.present? }
  ) { object.topic.workflow_name }

  add_to_serializer(
    :topic_view,
    :workflow_step_slug,
    include_condition: -> { object.topic.workflow_step_slug.present? }
  ) { object.topic.workflow_step_slug }

  add_to_serializer(
    :topic_view,
    :workflow_step_name,
    include_condition: -> { object.topic.workflow_step_name.present? }
  ) { object.topic.workflow_step_name }

  add_to_serializer(
    :topic_view,
    :workflow_step_position,
    include_condition: -> { object.topic.workflow_step_position.present? }
  ) { object.topic.workflow_step_position }

  add_to_serializer(
    :topic_view,
    :workflow_step_options,
    include_condition: -> {
      @workflow_step_options ||= object.topic.workflow_step_options
      @workflow_step_options.present?
    }
  ) do
    begin
      scope.ensure_can_create_topic_on_category!(self.category_id)
      @workflow_step_options ||= object.topic.workflow_step_options
      @workflow_step_options
    rescue Discourse::InvalidAccess
      nil
    end
  end

  add_to_serializer(
    :topic_list_item,
    :workflow_name,
    include_condition: -> { object.workflow_name.present? }
  ) { object.workflow_name }

  add_to_serializer(
    :topic_list_item,
    :workflow_step_position,
    include_condition: -> { object.workflow_step_position.present? }
  ) { object.workflow_step_position.to_i }

  add_to_serializer(
    :topic_list_item,
    :workflow_step_name,
    include_condition: -> { object.workflow_step_name.present? }
  ) { object.workflow_step_name }

  on(:topic_created) do |*params|
    topic, opts = params

    if SiteSetting.workflow_enabled
      workflow_step =
        DiscourseWorkflow::WorkflowStep.find_by(
          category_id: topic.category_id,
          position: 1
        )
      if workflow_step
        DiscourseWorkflow::WorkflowState.create!(
          topic_id: topic.id,
          workflow_id: workflow_step.workflow_id,
          workflow_step_id: workflow_step.id
        )
      end
    end
  end

  on(:post_alerter_after_save_post) do |post, new_record, notified|
    next if !new_record
    DiscourseWorkflow::PostNotificationHandler.new(post, notified).handle
  end
end
