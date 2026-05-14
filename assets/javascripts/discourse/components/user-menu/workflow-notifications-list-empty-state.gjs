import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";

export default class WorkflowNotificationsListEmptyState extends Component {
  get body() {
    return trustHTML(
      i18n("user_menu.no_workflow_notifications_body", {
        preferencesUrl: getURL("/my/preferences/notifications"),
      })
    );
  }

  <template>
    <div class="empty-state">
      <span class="empty-state-title">
        {{i18n "user_menu.no_workflow_notifications_title"}}
      </span>
      <div class="empty-state-body">
        <p>{{this.body}}</p>
      </div>
    </div>
  </template>
}
