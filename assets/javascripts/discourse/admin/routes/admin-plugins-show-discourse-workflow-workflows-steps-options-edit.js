import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepOptionsEdit extends DiscourseRoute {
  async model(params) {
    debugger;
    const allWorkflowStepOptions = await this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps-options"
    );
    const id = parseInt(params.option_id, 10);
    const workflowStepOption = allWorkflowStepOptions.findBy("id", id);
    return workflowStepOption;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);
    console.log(this.router);
    debugger;
    

    const workflowOptions = await this.store.findAll("workflow-option");
    controller.set(
      "workflowOptions",
      workflowOptions.content
    );
    debugger;
    const workflow_id =  this.router.currentRoute.parent.parent.params.workflow_id;
    const workflowSteps = await this.store.findAll("workflow-step", { workflow_id: workflow_id });
    controller.set(
      "workflowSteps",
      workflowSteps.content
    );

    debugger;
    const workflowStep = workflowSteps.filter((step) => {return step.id === model.workflow_step_id})[0];
    debugger;
    controller.set(
      "workflowStep",
      workflowStep
    );
  }
}
