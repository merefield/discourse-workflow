// import { ajax } from "discourse/lib/ajax";
import RestModel from "discourse/models/rest";

const CREATE_ATTRIBUTES = [
  "name",
  "description",
  "enabled",
];

export default class Workflow extends RestModel {
  // async findAll() {
  //   const result = await ajax("discourse_workflow/workflow.json");
  //   return result.workflow_steps;
  // }

  // async findById(id) {
  //   return await ajax(`discourse_workflow/workflow/${id}.json`);
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

    const workflow = Workflow.create(attrs);
    return workflow;
  }

}