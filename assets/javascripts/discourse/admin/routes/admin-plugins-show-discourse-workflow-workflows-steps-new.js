import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsNew extends DiscourseRoute {
  async model(params) {
    debugger;
    // Create a new workflow step record

    const workflow = this.modelFor("adminPlugins.show.discourse-workflow-workflows-steps");

    debugger;

    const record = this.store.createRecord("workflow-step", {
      workflow_id: workflow.id,
      workflow_step_id: workflow.workflow_steps[workflow.workflow_steps.length - 1].workflow_step_id + 1,
    });

    // Attach it to the current workflow
    // const workflow = this.modelFor("adminPlugins.show.discourse-workflow-workflows");
    record.set("workflow", workflow);

    return record;
  }

  // setupController(controller, model) {
  //   super.setupController(controller, model);

  //   // Pass the parent workflow and its steps to the controller
  //   const workflow = this.modelFor("adminPlugins.show.discourse-workflow-workflows");
  //   controller.set("workflow", workflow);
  //   controller.set("allWorkflowSteps", workflow.steps || []);
  // }
}
