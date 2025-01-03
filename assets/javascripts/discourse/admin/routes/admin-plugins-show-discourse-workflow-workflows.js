import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowDiscourseWorkflowWorkflow extends DiscourseRoute {
  async model(params) {
    debugger;
    return this.store.findAll("workflow");
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}