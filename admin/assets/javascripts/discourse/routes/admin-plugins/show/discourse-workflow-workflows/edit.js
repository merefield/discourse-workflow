import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowEdit extends DiscourseRoute {
  queryParams = {
    refresh: { refreshModel: true },
  };

  async model(params) {
    const id = parseInt(params.workflow_id, 10);
    return this.store.find("workflow", id, { reload: true });
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set(
      "allWorkflows",
      this.modelFor("adminPlugins.show.discourse-workflow-workflows")
    );
  }
}
