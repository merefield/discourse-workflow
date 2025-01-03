import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepOptions extends DiscourseRoute {
  async model(params) {
    debugger;
    const workflowSteps = this.modelFor('admin.plugins.show.discourse-workflow.workflows.steps');
    
    // const workflowSteps = await this.store.find("workflow-step", { workflow_id: workflow_id  } );
    const id = parseInt(params.step_id, 10);
    const workflowStep = workflowSteps.findBy("id", id);
    const workflow_id = workflowStep.workflow_id;

    // const workflow_id = this.router.currentRoute.parent.params.workflow_id;
    debugger;
    const allWorkflowStepOptions = await this.store.findAll("workflow-step-option", { workflow_step_id: workflowStep.id, workflow_id: workflow_id });  // this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    return allWorkflowStepOptions.content;
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}