import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowEdit extends DiscourseRoute {
  async model(params) {
    const allWorkflows = this.modelFor(
      "adminPlugins.show.discourse-workflows"
    );
    const id = parseInt(params.id, 10);
    return allWorkflows.findBy("id", id);
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set(
      "allPersonas",
      this.modelFor("adminPlugins.show.discourse-workflows")
    );
  }
}