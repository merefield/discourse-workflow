import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import WorkflowButtons from "./workflow-buttons";


export default class WorkflowButtonsComponent extends Component {
  // @service dialog;

  // @action
  // actOnWorkflow(option) {
  //   console.log(`Acting on workflow with slug: ${option}`);

  //   this.dialog.yesNoConfirm({
  //     message: i18n(`discourse_workflow.options.${option}.confirmation`),
  //     didConfirm: () => {
  //       ajax(`/discourse_workflow/${this.args.topic_id}/act`, {
  //         type: "POST",
  //         data: { option },
  //       })
  //       .then(() => {
  //         this.refresh();
  //       })
  //       .catch(popupAjaxError);
  //     },
  //   });
  // }

  // workflowActionLabel = (option) => {
  //   return `discourse_workflow.options.${option}.button_label`;
  // }

  <template>
    <div class="workflow-topic-banner">
      <span class="workflow-name">{{i18n "discourse_workflow.topic_banner.intro" workflow_step_position=@workflow_step_position workflow_name=@workflow_name}}</span>
      <WorkflowButtons @workflow_step_options={{@workflow_step_options}} @topic_id={{@topic_id}} />
    </div>
  </template>
}