import RestModel from "discourse/models/rest";

const CREATE_ATTRIBUTES = ["name", "description", "enabled"];

export default class Workflow extends RestModel {
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
