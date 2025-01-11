import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import WorkflowButtons from "./workflow-buttons";
import WorkflowVisualisationModal from "./workflow-visualisation-modal";

export default class WorkflowButtonsComponent extends Component {
  @service modal;

  @action
  showVisualisationModal() {
    this.modal.show(WorkflowVisualisationModal, {
      model: {
        topic_id: this.args.topic_id,
        workflow_name: this.args.workflow_name,
      },
    });
  }

  <template>
    <div class="workflow-topic-banner">
      <div class="workflow-banner-border-title">{{i18n
          "discourse_workflow.topic_banner.title"
        }}</div>
      <div class="workflow-banner-meta">
        <div class="workflow-banner-section workflow-workflow-name">
          <div class="workflow-banner-title workflow-workflow-name-title">{{i18n
              "discourse_workflow.topic_banner.workflow_title"
            }}</div>
          <div class="workflow-workflow-name-name">{{@workflow_name}}</div>
        </div>
        <div class="workflow-banner-section workflow-step-name">
          <div class="workflow-banner-title workflow-step-name-title">{{i18n
              "discourse_workflow.topic_banner.step_title"
            }}</div>
          <div class="workflow-step-name">{{i18n
              "discourse_workflow.topic_banner.step"
              workflow_step_position=@workflow_step_position
              workflow_step_name=@workflow_step_name
            }}</div>
          <div class="workflow-action-button">
            <DButton
              class="btn-primary"
              @icon="network-wired"
              @action={{this.showVisualisationModal}}
              @label="discourse_workflow.topic_banner.visualisation_button"
            />
          </div>
        </div>
        <div class="workflow-banner-section workflow-step-actions">
          {{#if @workflow_step_options}}
            <WorkflowButtons
              @workflow_step_options={{@workflow_step_options}}
              @topic_id={{@topic_id}}
              @category_id={{@category_id}}
            />
          {{/if}}
        </div>
      </div>
    </div>
  </template>
}
