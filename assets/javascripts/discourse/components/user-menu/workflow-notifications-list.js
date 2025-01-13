import UserMenuNotificationsList from "discourse/components/user-menu/notifications-list";

export default class UserMenuWorkflowNotificationsList extends UserMenuNotificationsList {
  get dismissTypes() {
    return this.filterByTypes;
  }

  get emptyStateComponent() {
    return "user-menu/workflow-notifications-list-empty-state";
  }
}
