# frozen_string_literal: true
# name: discourse-workflow
# about: A topic-based workflow engine for Discourse
# version: 0.3.0
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
    Notification.singleton_class.prepend(DiscourseWorkflow::NotificationExtension)
  end

  register_topic_preloader_associations({ workflow_state: %i[workflow workflow_step] }) do
    SiteSetting.workflow_enabled
  end

  Discourse::Application.routes.prepend do
    get "/workflow/charts" => "list#workflow_charts"
  end

  Discourse.top_menu_items.push(:workflow)
  Discourse.anonymous_top_menu_items.push(:workflow)
  Discourse.filters.push(:workflow)
  Discourse.anonymous_filters.push(:workflow)

  SeedFu.fixture_paths << Rails.root.join("plugins", "discourse-workflow", "db", "fixtures").to_s

  add_admin_route(
    "admin.discourse_workflow.title",
    "discourse-workflow",
    { use_new_show_route: true },
  )

  add_to_class(:category, :workflow_enabled) do
    WorkflowStep.find_by(category_id: self.id)&.step_id == 1 || false
  end

  add_to_class(:category, :workflow_slug) do
    Workflow.joins(:workflow_steps).where(workflow_steps: { category_id: self.id }).first&.slug
  end

  # prevent non-staff from changing category on a workflow topic
  PostRevisor.track_topic_field(:category_id) do |tc, category_id|
    if tc.guardian.is_staff?
      tc.record_change("category_id", tc.topic.category_id, category_id)
      tc.topic.category_id = category_id
    else
      if ::DiscourseWorkflow::WorkflowState.find_by(topic_id: tc.topic.id).present?
        # TODO get this to work and add a translation
        tc.topic.errors.add(
          :base,
          :workflow,
          message: "you can't change category on a workflow topic unless you are staff",
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

  add_to_class(:topic, :workflow_step_slug) { workflow_state&.workflow_step&.slug }

  add_to_class(:topic, :workflow_step_name) { workflow_state&.workflow_step&.name }

  add_to_class(:topic, :workflow_step_position) { workflow_state&.workflow_step&.position }

  add_to_class(:topic, :workflow_step_options) do
    step = workflow_state&.workflow_step
    return [] unless step

    step
      .workflow_step_options
      .includes(:workflow_option)
      .order(:position)
      .map { |wso| wso.workflow_option.slug }
  end

  add_to_class(:topic, :workflow_step_actions) do
    step = workflow_state&.workflow_step
    return [] unless step

    step_options = step.workflow_step_options.includes(:workflow_option).order(:position)

    target_steps =
      DiscourseWorkflow::WorkflowStep.where(
        id: step_options.map(&:target_step_id).compact.uniq,
      ).index_by(&:id)

    step_options.map do |workflow_step_option|
      option = workflow_step_option.workflow_option
      target_step = target_steps[workflow_step_option.target_step_id]

      {
        slug: option&.slug,
        option_name: option&.name,
        target_step_name: target_step&.name,
        target_step_position: target_step&.position,
      }
    end
  end

  add_to_class(:topic, :workflow_step_entered_at) { workflow_state&.updated_at }

  add_to_class(:topic, :workflow_overdue_days_threshold) do
    state = workflow_state
    return nil if state.blank?

    step_overdue_days = state.workflow_step&.overdue_days
    workflow_overdue_days = state.workflow&.overdue_days

    if !step_overdue_days.nil?
      step_overdue_days.to_i
    elsif !workflow_overdue_days.nil?
      workflow_overdue_days.to_i
    else
      SiteSetting.workflow_overdue_days_default.to_i
    end
  end

  add_to_class(:topic, :workflow_overdue) do
    threshold_days = workflow_overdue_days_threshold
    return false if threshold_days.blank? || threshold_days <= 0

    entered_at = workflow_step_entered_at
    return false if entered_at.blank?

    entered_at <= threshold_days.days.ago
  end

  add_to_class(:topic_list, :workflow_kanban_workflow) do
    return @workflow_kanban_workflow if defined?(@workflow_kanban_workflow)

    workflow_ids = topics.map { |topic| topic.workflow_state&.workflow_id }.compact.uniq

    @workflow_kanban_workflow =
      if workflow_ids.length == 1
        DiscourseWorkflow::Workflow.includes(
          workflow_steps: [
            { category: :parent_category },
            { workflow_step_options: :workflow_option },
          ],
        ).find_by(id: workflow_ids.first)
      end
  end

  add_to_class(:topic_list, :workflow_kanban_compatible) do
    workflow = workflow_kanban_workflow
    workflow.present? && workflow.kanban_compatible?
  end

  add_to_class(:topic_list, :workflow_kanban_show_tags) do
    workflow = workflow_kanban_workflow
    workflow.present? && workflow.show_kanban_tags != false
  end

  add_to_class(:topic_list, :workflow_single_workflow_id) do
    workflow_kanban_workflow&.id
  end

  add_to_class(:topic_list, :workflow_single_workflow_name) do
    workflow_kanban_workflow&.name
  end

  add_to_class(:topic_list, :workflow_kanban_steps) do
    return [] if !workflow_kanban_compatible

    workflow_kanban_workflow
      .workflow_steps
      .order(:position)
      .map do |step|
        category = step.category
        {
          id: step.id,
          position: step.position,
          name: step.name,
          category_color: category&.color || category&.parent_category&.color,
        }
      end
  end

  add_to_class(:topic_list, :workflow_kanban_transitions) do
    return [] if !workflow_kanban_compatible

    workflow = workflow_kanban_workflow
    steps = workflow.workflow_steps.to_a
    steps_by_id = steps.index_by(&:id)
    first_option_for_edge = {}

    steps.each do |step|
      step
        .workflow_step_options
        .sort_by { |option| option.position.to_i }
        .each do |step_option|
          target_step = steps_by_id[step_option.target_step_id]
          next if target_step.blank?

          option_slug = step_option.workflow_option&.slug
          next if option_slug.blank?

          edge_key = [step.position.to_i, target_step.position.to_i]
          first_option_for_edge[edge_key] ||= option_slug
        end
    end

    first_option_for_edge.map do |(from_position, to_position), option_slug|
      { from_position: from_position, to_position: to_position, option_slug: option_slug }
    end
  end

  add_to_serializer(
    :topic_view,
    :workflow_slug,
    include_condition: -> { object.topic.workflow_slug.present? },
  ) { object.topic.workflow_slug }

  add_to_serializer(
    :topic_view,
    :workflow_name,
    include_condition: -> { object.topic.workflow_name.present? },
  ) { object.topic.workflow_name }

  add_to_serializer(
    :topic_view,
    :workflow_step_slug,
    include_condition: -> { object.topic.workflow_step_slug.present? },
  ) { object.topic.workflow_step_slug }

  add_to_serializer(
    :topic_view,
    :workflow_step_name,
    include_condition: -> { object.topic.workflow_step_name.present? },
  ) { object.topic.workflow_step_name }

  add_to_serializer(
    :topic_view,
    :workflow_step_position,
    include_condition: -> { object.topic.workflow_step_position.present? },
  ) { object.topic.workflow_step_position }

  add_to_serializer(
    :topic_view,
    :workflow_step_options,
    include_condition: -> do
      @workflow_step_options ||= object.topic.workflow_step_options
      @workflow_step_options.present?
    end,
  ) do
    @workflow_step_options ||= object.topic.workflow_step_options
    @workflow_step_options
  end

  add_to_serializer(
    :topic_view,
    :workflow_step_actions,
    include_condition: -> do
      @workflow_step_actions ||= object.topic.workflow_step_actions
      @workflow_step_actions.present?
    end,
  ) { @workflow_step_actions ||= object.topic.workflow_step_actions }

  add_to_serializer(
    :topic_view,
    :workflow_can_act,
    include_condition: -> { object.topic.workflow_name.present? },
  ) do
    begin
      scope.ensure_can_create_topic_on_category!(object.topic.category_id)
      true
    rescue Discourse::InvalidAccess
      false
    end
  end

  add_to_serializer(
    :topic_view,
    :workflow_step_entered_at,
    include_condition: -> { object.topic.workflow_step_entered_at.present? },
  ) { object.topic.workflow_step_entered_at }

  add_to_serializer(
    :topic_list_item,
    :workflow_name,
    include_condition: -> { object.workflow_name.present? },
  ) { object.workflow_name }

  add_to_serializer(
    :topic_list_item,
    :workflow_step_position,
    include_condition: -> { object.workflow_step_position.present? },
  ) { object.workflow_step_position.to_i }

  add_to_serializer(
    :topic_list_item,
    :workflow_step_name,
    include_condition: -> { object.workflow_step_name.present? },
  ) { object.workflow_step_name }

  add_to_serializer(
    :topic_list_item,
    :workflow_overdue,
    include_condition: -> { object.workflow_name.present? },
  ) { object.workflow_overdue }

  add_to_serializer(
    :topic_list_item,
    :workflow_can_act,
    include_condition: -> { object.workflow_name.present? },
  ) do
    # Cache permission checks per category on the scope to avoid repeated work
    permissions_cache =
      scope.instance_variable_get(:@workflow_can_act_category_permissions) ||
        scope.instance_variable_set(:@workflow_can_act_category_permissions, {})

    category_id = object.category_id

    unless permissions_cache.key?(category_id)
      begin
        scope.ensure_can_create_topic_on_category!(category_id)
        permissions_cache[category_id] = true
      rescue Discourse::InvalidAccess
        permissions_cache[category_id] = false
      end
    end

    permissions_cache[category_id]
  end

  add_to_serializer(
    :topic_list,
    :workflow_kanban_compatible,
    include_condition: -> { object.topics.any? { |topic| topic.workflow_state.present? } },
  ) { object.workflow_kanban_compatible }

  add_to_serializer(
    :topic_list,
    :workflow_kanban_workflow_name,
    include_condition: -> { object.workflow_single_workflow_name.present? },
  ) { object.workflow_kanban_workflow.name }

  add_to_serializer(
    :topic_list,
    :workflow_single_workflow_id,
    include_condition: -> { object.topics.any? { |topic| topic.workflow_state.present? } },
  ) { object.workflow_single_workflow_id }

  add_to_serializer(
    :topic_list,
    :workflow_can_view_charts,
    include_condition: -> { object.topics.any? { |topic| topic.workflow_state.present? } },
  ) { DiscourseWorkflow::ChartsPermissions.can_view?(scope.user) }

  add_to_serializer(
    :topic_list,
    :workflow_kanban_show_tags,
    include_condition: -> { object.topics.any? { |topic| topic.workflow_state.present? } },
  ) { object.workflow_kanban_show_tags }

  add_to_serializer(
    :topic_list,
    :workflow_kanban_steps,
    include_condition: -> { object.topics.any? { |topic| topic.workflow_state.present? } },
  ) { object.workflow_kanban_steps }

  add_to_serializer(
    :topic_list,
    :workflow_kanban_transitions,
    include_condition: -> { object.topics.any? { |topic| topic.workflow_state.present? } },
  ) { object.workflow_kanban_transitions }

  on(:topic_created) do |*params|
    topic, opts = params

    if SiteSetting.workflow_enabled
      workflow_step =
        DiscourseWorkflow::WorkflowStep.joins(:workflow).find_by(
          category_id: topic.category_id,
          position: 1,
          workflows: {
            enabled: true,
          },
        )
      if workflow_step
        DiscourseWorkflow::WorkflowState.create!(
          topic_id: topic.id,
          workflow_id: workflow_step.workflow_id,
          workflow_step_id: workflow_step.id,
        )
      end
    end
  end

  on(:post_alerter_after_save_post) do |post, new_record, notified|
    next if !new_record
    DiscourseWorkflow::PostNotificationHandler.new(post, notified).handle
  end
end
