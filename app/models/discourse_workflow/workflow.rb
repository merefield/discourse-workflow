# frozen_string_literal: true

module ::DiscourseWorkflow
  class Workflow < ActiveRecord::Base
    self.table_name = 'workflows'

    before_validation :generate_unique_slug, if: :slug_generation_required?

    validate :ensure_name_ascii
    validates :slug, presence: true, uniqueness: true
    validates :overdue_days,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true,
              }

    has_many :workflow_steps, dependent: :destroy
    has_many :workflow_states

    scope :ordered, -> { order("lower(name) ASC") }

    def kanban_compatible?
      steps = workflow_steps.includes(:workflow_step_options).to_a
      return false if steps.blank?

      positions = steps.map { |step| step.position.to_i }
      return false if positions.uniq.size != positions.size

      start_steps = steps.select { |step| step.position.to_i == 1 }
      return false unless start_steps.one?

      step_ids = steps.map(&:id)
      step_lookup = step_ids.index_with(true)
      steps_by_id = steps.index_by(&:id)
      edges = Hash.new { |hash, key| hash[key] = [] }
      edge_lookup = {}

      steps.each do |step|
        step.workflow_step_options.each do |step_option|
          target_step_id = step_option.target_step_id
          next if target_step_id.blank?
          return false if !step_lookup[target_step_id]

          from_position = step.position.to_i
          to_position = steps_by_id[target_step_id].position.to_i
          edge_key = [from_position, to_position]
          return false if edge_lookup[edge_key]

          edge_lookup[edge_key] = true
          edges[step.id] << target_step_id
        end
      end

      start_step_id = start_steps.first.id
      visited = {}
      stack = [start_step_id]

      until stack.empty?
        current_step_id = stack.pop
        next if visited[current_step_id]

        visited[current_step_id] = true
        edges[current_step_id].each { |target_step_id| stack << target_step_id }
      end

      visited.size == step_ids.size
    end

    def validation_warnings
      warnings = []

      duplicate_step_positions =
        workflow_steps
          .group(:position)
          .having("COUNT(*) > 1")
          .pluck(:position)
          .compact

      if duplicate_step_positions.present?
        warnings << {
          code: "duplicate_step_positions",
          positions: duplicate_step_positions
        }
      end

      workflow_step_ids = workflow_steps.pluck(:id)
      orphan_target_step_options =
        WorkflowStepOption
          .joins(:workflow_step)
          .where(workflow_steps: { workflow_id: id })
          .where.not(target_step_id: workflow_step_ids)

      if orphan_target_step_options.exists?
        warnings << {
          code: "orphan_target_steps",
          option_ids: orphan_target_step_options.pluck(:id)
        }
      end

      option_slugs =
        WorkflowStepOption
          .joins(:workflow_step, :workflow_option)
          .where(workflow_steps: { workflow_id: id })
          .pluck("workflow_options.slug")
          .uniq

      missing_option_labels =
        option_slugs.reject do |slug|
          I18n.exists?("js.discourse_workflow.options.#{slug}.button_label")
        end

      if missing_option_labels.present?
        warnings << {
          code: "missing_option_labels",
          slugs: missing_option_labels
        }
      end

      warnings
    end

    def ensure_name_ascii
      return if name.blank?
      if !CGI.unescape(self.name).ascii_only?
        errors.add(:name, I18n.t("workflow.errors.name_contains_non_ascii_chars"))
      end
    end

    def generate_unique_slug
      base_slug = name.to_s.parameterize(separator: '_')
      slug_candidate = base_slug
      counter = 2

      while Workflow.where(slug: slug_candidate).where.not(id: self.id).exists?
        slug_candidate = "#{base_slug}_#{counter}"
        counter += 1
      end

      self.slug = slug_candidate
    end

    def slug_generation_required?
      slug.blank? || will_save_change_to_name?
    end
  end
end

# == Schema Information
#
# Table name: workflows
#
#  id           :bigint           not null, primary key
#  description  :text
#  enabled      :boolean          default(TRUE)
#  name         :string
#  overdue_days :integer
#  show_kanban_tags :boolean        default(TRUE), not null
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
