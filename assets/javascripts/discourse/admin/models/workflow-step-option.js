import { ajax } from "discourse/lib/ajax";
import RestModel from "discourse/models/rest";

export default class WorkflowStepOption extends RestModel {
  static async findAll() {
    const result = await ajax("discourse_workflow/workflow_step_option.json");
    return result.workflow_steps;
  }

  static async findById(id) {
    return await ajax(`discourse_workflow/workflow_step_option/${id}.json`);
  }
}