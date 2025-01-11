import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsEdit extends DiscourseRoute {
  async model(params) {
    const allWorkflowSteps = await this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps"
    );
    const id = parseInt(params.step_id, 10);
    const workflowStep = allWorkflowSteps.findBy("id", id);

    const workflowSteps = await this.store.findAll("workflow-step", {
      workflow_id: workflowStep.workflow_id,
    });
    workflowStep.set("workflowSteps", workflowSteps.content);
    const workflow = await this.store.find(
      "workflow",
      workflowStep.workflow_id
    );
    workflowStep.set("workflow", workflow);
    return workflowStep;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);

    const workflowSteps = await this.store.findAll("workflow-step", {
      workflow_id: this.currentModel.workflow_id,
    });
    controller.set("workflowSteps", workflowSteps.content);
  }
}
