import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
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

  @tracked transitioningOption = null;

  workflowActionLabel = (workflowAction) => {
    return `discourse_workflow.options.${workflowAction.slug}.button_label`;
  };

  workflowActionHelperText = (workflowAction) => {
    if (!workflowAction.target_step_name) {
      return null;
    }

    return i18n("discourse_workflow.topic_banner.transition_target", {
      target_step_name: workflowAction.target_step_name,
    });
  };

  get actionsDisabled() {
    return !this.args.workflow_can_act || this.transitioningOption !== null;
  }

  @action
  actOnWorkflow(workflowAction) {
    const option = workflowAction.slug;
    if (!option) {
      return;
    }

    const message = i18n(`discourse_workflow.options.${option}.confirmation`);
    const targetSuffix = this.workflowActionHelperText(workflowAction);
    const confirmationMessage =
      targetSuffix && message ? `${message} ${targetSuffix}` : message;

    this.dialog.yesNoConfirm({
      message: confirmationMessage,
      didConfirm: () => {
        this.transitioningOption = option;
        ajax(`/discourse-workflow/act/${this.args.topic_id}`, {
          type: "POST",
          data: { option },
        })
          .then(() => {
            this.router.transitionTo("/c/" + this.args.category_id);
          })
          .catch((err) => {
            this.transitioningOption = null;
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
      {{#each @workflow_step_actions as |workflowAction|}}
        <div class="workflow-action-button">
          <DButton
            class="btn-primary"
            @action={{fn this.actOnWorkflow workflowAction}}
            @label={{this.workflowActionLabel workflowAction}}
            @disabled={{this.actionsDisabled}}
          />
          {{#if (this.workflowActionHelperText workflowAction)}}
            <div class="workflow-action-helper">{{this.workflowActionHelperText
                workflowAction
              }}</div>
          {{/if}}
        </div>
      {{/each}}
    </div>
  </template>
}
