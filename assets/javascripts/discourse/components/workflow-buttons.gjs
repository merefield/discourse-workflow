import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class WorkflowButtonsComponent extends Component {
  @service dialog;
  @service router;

  workflowActionLabel = (option) => {
    return `discourse_workflow.options.${option}.button_label`;
  };

  @action
  actOnWorkflow(option) {
    this.dialog.yesNoConfirm({
      message: i18n(`discourse_workflow.options.${option}.confirmation`),
      didConfirm: () => {
        ajax(`/discourse-workflow/act/${this.args.topic_id}`, {
          type: "POST",
          data: { option },
        })
          .then(() => {
            this.router.transitionTo("/c/" + this.args.category_id);
          })
          .catch((err) => {
            popupAjaxError(err);
          });
      },
    });
  }

  <template>
    <div class="workflow-banner-title workflow-buttons-title">
      {{i18n "discourse_workflow.topic_banner.actions_intro"}}
    </div>
    <div class="workflow-action-buttons">
      {{#each @workflow_step_options as |option|}}
        <div class="workflow-action-button">
          <DButton
            class="btn-primary"
            @action={{fn this.actOnWorkflow option}}
            @label={{this.workflowActionLabel option}}
          />
        </div>
      {{/each}}
    </div>
  </template>
}
