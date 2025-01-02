import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepOptionsNew extends DiscourseRoute {

  async model(params) {
    // Get the parent workflow step
    const workflowStep = this.modelFor("adminPlugins.show.discourse-workflow-workflows-steps-options");
    // Create a new workflow step record
    debugger;
    const record = this.store.createRecord("workflow-step-option", {
      workflow_step_id: workflowStep.id,
      position:  workflowStep.workflow_step_options.length > 0 ? workflowStep.workflow_step_options[workflowStep.workflow_step_options.length - 1].position + 1 : 1,
    });

    // Attach it to the parent workflow to current step
    record.set("workflowStep", workflowStep);

    return record;
  }

  setupController(controller, model) {
    super.setupController(controller, model);

    const workflowOptions = this.store.findAll("workflow-option");
    controller.set(
      "workflowOptions",
      workflowOptions
    );
  }
}
