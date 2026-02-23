# frozen_string_literal: true

module DiscourseWorkflow
  module ChartsPermissions
    def self.can_view?(user)
      return false if user.blank?
      return true if user.admin?

      allowed_group_ids = SiteSetting.workflow_charts_allowed_groups_map
      allowed_group_ids.present? && user.in_any_groups?(allowed_group_ids)
    end
  end
end
