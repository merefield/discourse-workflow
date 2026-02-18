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
#  id          :bigint           not null, primary key
#  slug        :string
#  name        :string
#  description :text
#  enabled     :boolean          default(TRUE)
#  overdue_days :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
