import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsNew extends DiscourseRoute {
  async model() {
    // Get the parent workflow
    const workflow = this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps"
    );

    const sortedSteps = [...workflow.workflow_steps].sort(
      (a, b) => a.position - b.position
    );

    // Create a new workflow step record
    // Asign a default position to be the last existing step + 1
    const record = this.store.createRecord("workflow-step", {
      workflow_id: workflow.id,
      position:
        sortedSteps.length > 0
          ? sortedSteps[workflow.workflow_steps.length - 1].position + 1
          : 1,
    });

    // Attach it to the parent workflow to current step
    record.set("workflow", workflow);

    return record;
  }
}
