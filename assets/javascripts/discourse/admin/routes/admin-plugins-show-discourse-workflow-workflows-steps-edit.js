import DiscourseRoute from "discourse/routes/discourse";
import WorkflowStep from "../models/workflow-step";
import Workflow from "../models/workflow";
import { inject as service } from "@ember/service";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsEdit extends DiscourseRoute {
  async model(params) {
    debugger;
    const allWorkflowSteps = await this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps"
    );
    const id = parseInt(params.step_id, 10);
    const workflowStep = allWorkflowSteps.findBy("id", id);
  
    const workflowSteps = await this.store.findAll("workflow-step", { workflow_id: workflowStep.workflow_id });
    workflowStep.set("workflowSteps", workflowSteps.content);
    debugger;
    const workflow = await this.store.find("workflow", workflowStep.workflow_id);
    workflowStep.set("workflow", workflow);
    debugger;
    return workflowStep;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);
    debugger;

    const workflowSteps = await this.store.findAll("workflow-step", { workflow_id: this.currentModel.workflow_id });
    debugger;
    controller.set(
      "workflowSteps",
      workflowSteps.content
    );
  }
}
