import { ajax } from "discourse/lib/ajax";
import RestModel from "discourse/models/rest";

const CREATE_ATTRIBUTES = [
  "workflow_step_id",
  "position",
  "name"
];

export default class WorkflowStepOption extends RestModel {
  // static async findAll() {
  //   const result = await ajax("discourse_workflow/workflow_step_option.json");
  //   return result.workflow_steps;
  // }

  // static async findById(id) {
  //   return await ajax(`discourse_workflow/workflow_step_option/${id}.json`);
  // }

  updateProperties() {
    let attrs = this.getProperties(CREATE_ATTRIBUTES);
    attrs.id = this.id;
    return attrs;
  }

  createProperties() {
    let attrs = this.getProperties(CREATE_ATTRIBUTES);
    return attrs;
  }

  workingCopy() {
    let attrs = this.getProperties(CREATE_ATTRIBUTES);
    const workflowStepOption = WorkflowStepOption.create(attrs);
    return workflowStepOption;
  }
}