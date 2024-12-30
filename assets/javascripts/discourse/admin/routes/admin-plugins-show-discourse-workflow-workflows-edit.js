import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowEdit extends DiscourseRoute {
  async model(params) {
    const allWorkflows = await this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows"
    ).content;
    const id = parseInt(params.workflow_id, 10);
    // return allWorkflows.find((workflow) => workflow.id === id);
    return allWorkflows.findBy("id", id);
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set(
      "allWorkflows",
      this.modelFor("adminPlugins.show.discourse-workflow-workflows")
    );
  }
}