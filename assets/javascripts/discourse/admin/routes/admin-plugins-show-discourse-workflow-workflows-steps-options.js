import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepOptions extends DiscourseRoute {
  async model(params) {

    const workflowSteps = this.modelFor('admin.plugins.show.discourse-workflow.workflows.steps');
    const id = parseInt(params.step_id, 10);
    const workflowStep = workflowSteps.findBy("id", id);
    const workflow_id = workflowStep.workflow_id;
    const allWorkflowStepOptions = await this.store.findAll("workflow-step-option", { workflow_step_id: workflowStep.id, workflow_id: workflow_id });  // this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    return allWorkflowStepOptions.content;
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}