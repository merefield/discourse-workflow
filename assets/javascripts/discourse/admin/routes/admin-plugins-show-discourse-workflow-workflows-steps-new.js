import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsNew extends DiscourseRoute {
  async model(params) {
    // Get the parent workflow
    const workflow = this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps"
    );
    // Create a new workflow step record
    const record = this.store.createRecord("workflow-step", {
      workflow_id: workflow.id,
      position:
        workflow.workflow_steps.length > 0
          ? workflow.workflow_steps[workflow.workflow_steps.length - 1]
              .position + 1
          : 1,
    });

    // Attach it to the parent workflow to current step
    record.set("workflow", workflow);

    return record;
  }
}
