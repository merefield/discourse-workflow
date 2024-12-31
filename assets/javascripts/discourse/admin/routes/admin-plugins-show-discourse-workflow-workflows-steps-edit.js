import DiscourseRoute from "discourse/routes/discourse";
import WorkflowStep from "../models/workflow-step";
import Workflow from "../models/workflow";
import { inject as service } from "@ember/service";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsEdit extends DiscourseRoute {
  async model(params) {
    const allWorkflowSteps = await this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps"
    );
    const id = parseInt(params.step_id, 10);
    const workflowStep = allWorkflowSteps.findBy("id", id);
    return workflowStep;
  }
}
