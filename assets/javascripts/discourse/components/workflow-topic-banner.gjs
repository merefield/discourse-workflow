import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import bodyClass from "discourse/helpers/body-class";
import { i18n } from "discourse-i18n";
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

  get stepAgeLabel() {
    if (!this.args.workflow_step_entered_at) {
      return null;
    }

    const enteredAt = new Date(this.args.workflow_step_entered_at);
    const elapsedMs = Date.now() - enteredAt.getTime();
    const elapsedDays = Math.floor(elapsedMs / (1000 * 60 * 60 * 24));

    if (elapsedDays < 1) {
      return i18n("discourse_workflow.topic_banner.step_age_less_than_day");
    }

    return i18n("discourse_workflow.topic_banner.step_age_days", {
      count: elapsedDays,
    });
  }

  <template>
    {{#if @workflow_name}}
      {{bodyClass "workflow-topic"}}
      <div class="workflow-topic-banner">
        <div class="workflow-banner-border-title">{{i18n
            "discourse_workflow.topic_banner.title"
          }}</div>
        <div class="workflow-banner-meta">
          <div class="workflow-banner-section workflow-workflow-name">
            <div
              class="workflow-banner-title workflow-workflow-name-title"
            >{{i18n "discourse_workflow.topic_banner.workflow_title"}}</div>
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
            {{#if this.stepAgeLabel}}
              <div class="workflow-step-age-badge">{{this.stepAgeLabel}}</div>
            {{/if}}
          </div>
          <div class="workflow-banner-section workflow-step-actions">
            {{#if @workflow_step_actions}}
              <WorkflowButtons
                @workflow_step_actions={{@workflow_step_actions}}
                @workflow_can_act={{@workflow_can_act}}
                @topic_id={{@topic_id}}
                @category_id={{@category_id}}
              />
            {{/if}}
            {{#unless @workflow_can_act}}
              <div class="workflow-actions-blocked-reason">{{i18n
                  "discourse_workflow.topic_banner.blocked_reason_create_permission"
                }}</div>
            {{/unless}}
          </div>
          <div class="workflow-action-button">
            <DButton
              class="btn-primary"
              @icon="right-left"
              @action={{this.showVisualisationModal}}
              @label="discourse_workflow.topic_banner.visualisation_button"
            />
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
