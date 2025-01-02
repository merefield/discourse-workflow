import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepOptions extends DiscourseRoute {
  async model(params) {
    const allWorkflowStepOptions = await this.store.findAll("workflow-step-option", { id: params.id });  // this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    return allWorkflowStepOptions.content;
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}