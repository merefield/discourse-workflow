import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsNew extends DiscourseRoute {
  async model(params) {
    const allWorkflowSteps = this.modelFor(
      "adminPlugins.show.discourse-workflow-steps"
    );
    const id = parseInt(params.id, 10);
    return allWorkflowSteps.findBy("id", id);
  }

  setupController(controller, model) {
    super.setupController(controller, model);

    // Pass the parent workflow and its steps to the controller
    const workflowSteps = this.modelFor("adminPlugins.show.discourse-workflow-workflow-steps");
    controller.set("workflow", workflow);
    controller.set("allWorkflowSteps", workflow.steps || []);
  }
}
