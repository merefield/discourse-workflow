import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowDiscourseWorkflowWorkflowSteps extends DiscourseRoute {
  async model(params) {
    const allWorkflowSteps = await this.store.findAll("workflow-step", { workflow_id: params.workflow_id });  // this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    // const id = parseInt(params.workflow_id, 10);
    // const workflowStep = allWorkflowSteps.findBy("id", id);
    return allWorkflowSteps.content;
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}