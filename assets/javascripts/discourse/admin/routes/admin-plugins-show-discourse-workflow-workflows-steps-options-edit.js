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
}
