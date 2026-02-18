import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepOptionsEdit extends DiscourseRoute {
  async model(params) {
    const allWorkflowStepOptions = await this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps-options"
    );
    const id = parseInt(params.option_id, 10);
    const workflowStepOption = allWorkflowStepOptions.findBy("id", id);
    return workflowStepOption;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);

    const workflowOptions = await this.store.findAll("workflow-option");
    controller.set("workflowOptions", workflowOptions.content);

    const workflow_id = model.workflow_id;
    const workflowSteps = await this.store.findAll("workflow-step", {
      workflow_id,
    });
    const stepCollection = workflowSteps.content || workflowSteps;
    controller.set("workflowSteps", stepCollection);

    const workflowStep = stepCollection.find((step) => {
      return Number(step.id) === Number(model.workflow_step_id);
    });
    controller.set("workflowStep", workflowStep);
  }
}
