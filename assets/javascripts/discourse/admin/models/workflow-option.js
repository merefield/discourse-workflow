import { ajax } from "discourse/lib/ajax";
import RestModel from "discourse/models/rest";

// const CREATE_ATTRIBUTES = [
//   "workflow_id",
//   "position",
//   "name",
//   "category_id",
//   "description",
//   "step_type",
// ];

export default class WorkflowStep extends RestModel {
  // static async findAll() {
  //   const result = await ajax("discourse_workflow/workflow_step.json");
  //   return result.workflow_steps;
  // }
  // static async findById(id) {
  //   return await ajax(`discourse_workflow/workflow_step/${id}.json`);
  // }
  // static async findAllForWorkflow(workflowId) {
  //   const result = await ajax(`discourse_workflow/workflow/${workflowId}/workflow_step.json`);
  //   return result.workflow_steps;
  // }
  // updateProperties() {
  //   let attrs = this.getProperties(CREATE_ATTRIBUTES);
  //   attrs.id = this.id;
  //   return attrs;
  // }
  // createProperties() {
  //   let attrs = this.getProperties(CREATE_ATTRIBUTES);
  //   return attrs;
  // }
  // workingCopy() {
  //   let attrs = this.getProperties(CREATE_ATTRIBUTES);
  //   const workflowStep = WorkflowStep.create(attrs);
  //   return workflowStep;
  // }
}
