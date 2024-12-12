import DiscourseRoute from "discourse/routes/discourse";
AdminPluginsShowDiscourseAiPersonasNew
export default class AdminPluginsShowDiscourseWorkflowWorkflow extends DiscourseRoute {
  model() {
    return this.store.findAll("workflow");
  }
}