import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Textarea from "discourse/components/d-textarea";
import { cached, tracked } from "@glimmer/tracking";

export default class WorkflowButtonsComponent extends Component {
  @service dialog;
  @service router;
  @tracked comment = "";

  @action
  actOnWorkflow(option) {
    console.log(`Acting on workflow with slug: ${option}`);

    this.dialog.yesNoConfirm({
      message: i18n(`discourse_workflow.options.${option}.confirmation`),
      didConfirm: () => {
        ajax(`/discourse-workflow/act/${this.args.topic_id}`, {
          type: "POST",
          data: { option, comment: this.comment },
        })
        .then(() => {
          this.router.refresh();
        })
        .catch((err) =>
        {
          popupAjaxError(err)
        });
      },
    });
  }

  workflowActionLabel = (option) => {
    return `discourse_workflow.options.${option}.button_label`;
  }

  <template>
    <div class="workflow-action-buttons">
      {{i18n "discourse_workflow.topic_banner.actions_intro"}}
      {{#each @workflow_step_options as |option|}}

        <DButton
          class="btn-primary"
          @action={{fn this.actOnWorkflow option}}
          @label={{this.workflowActionLabel option}}
        />
      {{/each}}
      <Textarea
        class="workflow-action-comment"
        placeholder={{i18n "discourse_workflow.topic_banner.comment_placeholder"}}
        @value={{this.comment}}
      />
    </div>
  </template>
}

        // @valueChange={{action (mut this.comment)}}
