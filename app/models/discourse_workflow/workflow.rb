# frozen_string_literal: true

module ::DiscourseWorkflow
  class Workflow < ActiveRecord::Base
    self.table_name = 'workflows'

    before_validation :generate_unique_slug

    validate :ensure_name_ascii
    validates :slug, presence: true, uniqueness: true

    has_many :workflow_steps, dependent: :destroy
    has_many :workflow_states

    scope :ordered, -> { order("lower(name) ASC") }

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

      while Workflow.exists?(slug: slug_candidate)
        slug_candidate = "#{base_slug}_#{counter}"
        counter += 1
      end

      self.slug = slug_candidate
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
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
