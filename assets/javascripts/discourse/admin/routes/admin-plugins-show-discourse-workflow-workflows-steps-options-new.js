import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepOptionsNew extends DiscourseRoute {
  async model(params) {
    // Get the parent workflow step
    const workflowStep = this.modelFor("adminPlugins.show.discourse-workflow-workflows-steps");
    // Create a new workflow step record
    const record = this.store.createRecord("workflow-step-option", {
      position: workflowStep.id,
      position:  workflowStep.workflow_step_options.length > 0 ? workflowStep.workflow_step_options[workflowStep.workflow_step_options.length - 1].position + 1 : 1,
    });

    // Attach it to the parent workflow to current step
    record.set("workflowStep", workflowStep);

    return record;
  }

  setupController(controller, model) {
    super.setupController(controller, model);

    workflowOptions = this.store.findAll("workflow-option");
    controller.set(
      "workflowOptions",
      workflowOptions
    );
  }
}
