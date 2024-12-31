import DiscourseRoute from "discourse/routes/discourse";
import WorkflowStep from "../models/workflow-step";
import Workflow from "../models/workflow";
import { inject as service } from "@ember/service";

export default class AdminPluginsShowDiscourseWorkflowWorkflowStepsEdit extends DiscourseRoute {
// @service store;

  // async model(params) {
  //   debugger;
  //   // const allWorkflowSteps = this.modelFor(
  //   //   "adminPlugins.show.discourse-workflow-steps"
  //   // );
  //   const workflow = this.store.findRecord('workflow', model.workflow_id);
  //   const allWorkflowSteps = this.store.findAll('workflow-step');
  //   const id = parseInt(params.id, 10);
  //   return allWorkflowSteps.findBy("id", id);
  // }

  // beforeModel(transition) {
  //   console.log('beforeModel executed', transition);
  // }

  async model(params) {
    // debugger;
    const allWorkflowSteps = await this.modelFor(
      "adminPlugins.show.discourse-workflow-workflows-steps"
    );
    const id = parseInt(params.step_id, 10);
    const workflowStep = allWorkflowSteps.findBy("id", id);
    return workflowStep;
  }

  // afterModel(resolvedModel) {
  //   console.log('afterModel resolved', resolvedModel);
  // }

  // setupController(controller, model) {
  //   super.setupController(controller, model);
  //   debugger;
  //   // // Pass the parent workflow and its steps to the controller
  //   // // const allWorkflowSteps = this.modelFor("adminPlugins.show.discourse-workflow-workflow-steps");
  //   // // const allWorkflows = this.modelFor("adminPlugins.show.discourse-workflow-workflows");
  //   // // const workflow = allWorkflows.findBy("id", model.workflow_id);
  //   // // const workflowSteps = allWorkflowSteps.findBy("workflow_id", model.workflow_id);
  //   // // debugger;
  //   // // const workflow = this.store.find('workflow', model.workflow_id);
  //   // // const workflowSteps = this.store.find('workflow-step', { workflow_id: model.workflow_id });
  //   // //  Workflow.findBy("id", model.workflow_id);
  //   // // const workflowSteps = allWorkflowSteps.findBy("workflow_id", model.workflow_id);
  //   // controller.set('currentWorkflowStep', model);
  //   // this.store.find('workflow', model.workflow_id).then((result) => {
  //   //   debugger;
  //   //   console.log('Workflow:', result);
  //   //   controller.set('workflow', result);
  //   // });
  //   // this.store.find('workflow-step', model.id).then((result) => {
  //   //   debugger;
  //   //   console.log('currentWorkflowStep:', result);
  //   //   controller.set("currentWorkflowStep", result);
  //   //   controller.set("action", "edit");
  //   // });
  // }
}
