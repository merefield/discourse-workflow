import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowNew extends DiscourseRoute {
  async model() {
    const record = this.store.createRecord("workflow");
    return record;
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set(
      "allWorkflows",
      this.modelFor("adminPlugins.show.discourse-workflows")
    );
  }
}