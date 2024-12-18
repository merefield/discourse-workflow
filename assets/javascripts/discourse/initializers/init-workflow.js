import { PLUGIN_NAV_MODE_TOP } from "discourse/lib/admin-plugin-config-nav";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-workflow-admin-plugin-configuration-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser?.admin) {
      return;
    }

    withPluginApi("1.1.0", (api) => {
      api.addAdminPluginConfigurationNav("discourse-workflow", PLUGIN_NAV_MODE_TOP, [
        {
          label: "admin.discourse_workflow.workflows.title",
          route: "adminPlugins.show.discourse-workflow-workflows",
        },
      ]);

      // api.registerPluginHeaderActionComponent("chat", ChatAdminPluginActions);
    });
  },
};