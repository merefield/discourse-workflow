import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsEdit extends DiscourseRoute {
  async model(params) {
    // Get all workflow steps for the current workflow
    const workflow = this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    const workflowSteps = workflow.workflow_steps || [];

    // Find the workflow step by its ID
    const id = parseInt(params.workflow_id, 10);
    return workflowSteps.findBy("id", id);
  }

  setupController(controller, model) {
    super.setupController(controller, model);

    // Pass all workflow steps and the parent workflow to the controller
    const workflow = this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    controller.set("workflow", workflow);
    controller.set("allWorkflowSteps", workflow.steps || []);
  }
}
