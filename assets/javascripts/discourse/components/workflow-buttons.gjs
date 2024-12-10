import Component from "@glimmer/component";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";
import DButton from "discourse/components/d-button";


export default class WorkflowButtonsComponent extends Component {
  @action
  ActOnWorkflow(option) {
    console.log(`Acting on workflow with slug: ${option}`);
  }

  workflowActionLabel  = (option) => {
    return `discourse_workflow.options.${option}`;
  }

  <template>
    {{#each @workflow_step_options as |option|}}
      <DButton
        @action={{this.ActOnWorkflow option}}
        @label={{this.workflowActionLabel option}}
        @class="btn-primary"
      />
    {{/each}}
  </template>
}
