import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowDiscourseWorkflowWorkflowSteps extends DiscourseRoute {
  async model() {
    const allWorkflowSteps = await this.store.findAll("workflow-step");
    return allWorkflowSteps.content;
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}