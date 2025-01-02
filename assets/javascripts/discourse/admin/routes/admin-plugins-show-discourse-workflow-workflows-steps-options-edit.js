import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepOptionsNew extends DiscourseRoute {
  async model(params) {
    const allWorkflowStepOptions = await this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps-options"
    );
    const id = parseInt(params.step_option_id, 10);
    const workflowStepOption = allWorkflowStepOptions.findBy("id", id);
    return workflowStepOption;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);

    const workflowOptions = await this.store.findAll("workflow-option");
    controller.set(
      "workflowOptions",
      workflowOptions.content
    );
    const workflowSteps = await this.store.findAll("workflow-step", { workflow_id: this.currentModel.workflowStep.workflow_id });
    controller.set(
      "workflowSteps",
      workflowSteps.content
    );
  }
}
