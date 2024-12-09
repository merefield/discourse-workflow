import { ajax } from "discourse/lib/ajax";
import RestModel from "discourse/models/rest";

export default class Workflow extends RestModel {
  static async findAll() {
    const result = await ajax("discourse_workflow/workflow.json");
    return result.workflow_steps;
  }

  static async findById(id) {
    return await ajax(`discourse_workflow/workflow/${id}.json`);
  }
}