import { withPluginApi } from "discourse/lib/plugin-api";
import { formatUsername } from "discourse/lib/utilities";
import getURL from "discourse-common/lib/get-url";
import { i18n } from "discourse-i18n";

export default {
  name: "workflow-user-menu",
  initialize() {
    withPluginApi("1.3.0", (api) => {
      if (api.registerNotificationTypeRenderer) {
        api.registerNotificationTypeRenderer(
          "workflow_topic_arrival",
          (NotificationItemBase) => {
            return class extends NotificationItemBase {
              icon = "right-left";
              linkTitle = i18n("notifications.titles.workflow_topic_arrival", {
                username: formatUsername(this.notification.data.username),
                topic_title: this.notification.data.topic_title,
                workflow_name: this.notification.data.workflow_name,
                workflow_step_name: this.notification.data.workflow_step_name,
              });
              description = i18n(
                "notifications.workflow_topic_arrival_description",
                {
                  username: formatUsername(this.notification.data.username),
                  topic_title: this.notification.data.topic_title,
                  workflow_name: this.notification.data.workflow_name,
                  workflow_step_name: this.notification.data.workflow_step_name,
                }
              );

              get label() {
                const data = this.notification.data;

                return i18n("notifications.workflow_topic_arrival_label", {
                  username: formatUsername(data.username),
                  topic_title: data.topic_title,
                  workflow_name: data.workflow_name,
                  workflow_step_name: data.workflow_step_name,
                });
              }

              get linkHref() {
                const data = this.notification.data;
                return getURL(`/t/${data.topic_id}`);
              }
            };
          }
        );
      }

      if (api.registerUserMenuTab) {
        api.registerUserMenuTab((UserMenuTab) => {
          return class extends UserMenuTab {
            get id() {
              return "workflow-notifications";
            }

            get panelComponent() {
              return "user-menu/workflow-notifications-list";
            }

            get icon() {
              return "right-left";
            }

            get count() {
              return this.getUnreadCountForType("workflow_topic_arrival");
            }

            get notificationTypes() {
              return ["workflow_topic_arrival"];
            }
          };
        });
      }
    });
  },
};
