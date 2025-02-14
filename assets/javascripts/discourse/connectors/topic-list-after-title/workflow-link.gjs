/* eslint-disable ember/no-empty-glimmer-component-classes */

import Component from "@glimmer/component";
import WorkflowNameLink from "../../components/workflow-name-link";
import { i18n } from "discourse-i18n";

export default class WorkflowLink extends Component {
  get label() {
    return i18n("discourse_workflow.workflow_link", {
      workflow_name: this.args.outletArgs.topic.workflow_name,
      workflow_step_name: this.args.outletArgs.topic.workflow_step_name,
    });
  }

  <template>
    {{#if @outletArgs.topic.workflow_name}}
      <span class="workflow-after-title">
        <WorkflowNameLink
          @topic_id={{@outletArgs.topic.id}}
          @workflow_name={{@outletArgs.topic.workflow_name}}
          @label={{this.label}}
          @icon={{"right-left"}}
        />
      </span>
    {{/if}}
  </template>
}
