# frozen_string_literal: true

module ::DiscourseWorkflow
  class Workflow < ActiveRecord::Base
    self.table_name = 'workflows'

   # validates :post_id, presence: true, uniqueness: true

    # before_validation :generate_unique_slug

    validate :ensure_name_ascii
    validate :ensure_slug
    validates :slug, presence: true, uniqueness: true

    has_many :workflow_steps, dependent: :destroy

    scope :ordered, -> { order("lower(name) ASC") }
 

    def ensure_name_ascii
      return if name.blank?
      if !CGI.unescape(self.name).ascii_only?
        errors.add(:name, I18n.t("workflow.errors.name_contains_non_ascii_chars"))
      end
    end

    def duplicate_slug?
      Workflow.where(slug: self.slug).where.not(id: self.id).any?
    end

    def ensure_slug
      return if name.blank?

      self.name.strip!

      # auto slug
      self.slug = Slug.for(name, "")
      if duplicate_slug?
        errors.add(:slug, I18n.t("workflow.errors.is_already_in_use"))
        self.slug = ""
      end
    end
 
  #  def generate_unique_slug
  #    base_slug = name.to_s.parameterize(separator: '_')
  #    slug_candidate = base_slug
  #    counter = 2
 
  #    while Workflow.exists?(slug: slug_candidate)
  #      slug_candidate = "#{base_slug}_#{counter}"
  #      counter += 1
  #    end
 
  #    self.slug = slug_candidate
  #  end
  end
end