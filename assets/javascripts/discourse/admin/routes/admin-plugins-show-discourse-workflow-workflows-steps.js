import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowDiscourseWorkflowWorkflowSteps extends DiscourseRoute {
  model() {
    debugger;
    return this.store.findAll("workflow-step");
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}