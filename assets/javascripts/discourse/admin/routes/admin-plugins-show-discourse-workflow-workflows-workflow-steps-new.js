import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsNew extends DiscourseRoute {
  async model() {
    // Create a new workflow step record
    const record = this.store.createRecord("workflow-step");

    // Attach it to the current workflow
    const workflow = this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    record.set("workflow", workflow);

    return record;
  }

  setupController(controller, model) {
    super.setupController(controller, model);

    // Pass the parent workflow and its steps to the controller
    const workflow = this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    controller.set("workflow", workflow);
    controller.set("allWorkflowSteps", workflow.steps || []);
  }
}
