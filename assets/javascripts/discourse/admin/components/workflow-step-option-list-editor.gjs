import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DPageSubheader from "discourse/components/d-page-subheader";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { bind } from "discourse-common/utils/decorators";
import { i18n } from "discourse-i18n";
import WorkflowLinkButton from "./workflow-link-button";
import WorkflowStepOptionEditor from "./workflow-step-option-editor";

export default class WorkflowStepOptionsListEditor extends Component {
  @service store;
  @tracked currentWorkflowStepOption = this.args.currentWorkflowStepOption;
  @tracked workflowStepOptions = [];
  @tracked workflowStepOptionsPresent = false;

  get newStepOption() {
    return this.store.createRecord("workflow-step-option", {
      workflow_step_id: this.args.workflowStep.id,
    });
  }

  @bind
  loadStepOptions() {
    if (!this.args.currentWorkflowStepOption && this.args.workflowStep.id) {
      this.store
        .find("workflow-step-option", {
          workflow_id: this.args.workflowStep.workflow_id,
          workflow_step_id: this.args.workflowStep.id,
        })
        .then((options) => {
          this.workflowStepOptions = options.content;
          this.workflowStepOptionsPresent =
            options.content.length > 0 ? true : false;
        });
    }
  }

  localizedStepOptionName(stepOption) {
    return i18n(
      `admin.discourse_workflow.workflows.steps.options.actions.${stepOption.workflow_option.slug}`
    );
  }

  convertStepIdToPosition(workflowSteps, stepOption) {
    if (!workflowSteps) {
      return;
    }
    return workflowSteps.find((step) => step.id === stepOption.target_step_id)
      ?.position;
  }

  @action
  moveUp(option) {
    const options = this.workflowStepOptions;
    if (option.position > 1) {
      const filteredOptions = options.filter(
        (s) => s.position < option.position
      );
      const previousOption =
        filteredOptions.length > 1
          ? filteredOptions.reduce((prev, curr) =>
              prev.position > curr.position ? prev : curr
            )
          : filteredOptions[0] || null;
      const previousPosition = previousOption
        ? previousOption.position
        : option.position - 1;
      if (previousOption) {
        try {
          previousOption.set("position", option.position);
          previousOption.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        option.set("position", previousPosition);
        option.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.workflowStepOptions = this.workflowStepOptions.sort(
      (a, b) => a.position - b.position
    );
  }

  @action
  moveDown(option) {
    const options = this.workflowStepOptions;
    if (option.position < options.length) {
      const filteredOptions = options.filter(
        (s) => s.position > option.position
      );
      const nextOption =
        filteredOptions.length > 1
          ? filteredOptions.reduce((prev, curr) =>
              prev.position < curr.position ? prev : curr
            )
          : filteredOptions[0] || null;
      const nextPosition = nextOption
        ? nextOption.position
        : option.position + 1;
      if (nextOption) {
        try {
          nextOption.set("position", option.position);
          nextOption.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        option.set("position", nextPosition);
        option.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.workflowStepOptions = this.workflowStepOptions.sort(
      (a, b) => a.position - b.position
    );
  }

  /* eslint-disable */
  isfirstOption(option, length) {
    return option.position === 1;
  }
  /* eslint-enable */

  islastOption(option, length) {
    return option.position === length;
  }

  <template>
    <section
      class="workflow-step-list-editor__current admin-detail pull-left"
      {{didInsert this.loadStepOptions}}
    >
      {{#if this.currentWorkflowStepOption}}
        <WorkflowStepOptionEditor
          @currentWorkflowStepOption={{this.currentWorkflowStepOption}}
          @workflowStep={{@workflowStep}}
          @workflowSteps={{@workflowSteps}}
          @workflowOptions={{@workflowOptions}}
        />
      {{else}}
        <DPageSubheader
          @titleLabel={{i18n
            "admin.discourse_workflow.workflows.steps.options.title"
          }}
          @descriptionLabel={{i18n
            "admin.discourse_workflow.workflows.steps.description"
          }}
          @learnMoreUrl="https://meta.discourse.org/t/ai-bot-workflows/306099"
        />

        {{#if this.workflowStepOptionsPresent}}
          <table class="content-list workflow-step-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.options.position"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.options.name"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.options.target_position"
                  }}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each this.workflowStepOptions as |stepOption|}}
                <tr
                  data-workflow-step-option-id={{stepOption.workflow_step_option_id}}
                  class={{concatClass
                    "workflow-step-option-list__row d-admin-row__content"
                  }}
                >
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__position">
                      {{stepOption.position}}
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__name">
                      <strong>
                        {{this.localizedStepOptionName stepOption}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__target_position">
                      <strong>
                        {{this.convertStepIdToPosition
                          @workflowSteps
                          stepOption
                        }}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="workflow-step-option-list__actions">
                      {{! this may have more actions }}
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    {{#unless
                      (this.isfirstOption
                        stepOption this.workflowStepOptions.length
                      )
                    }}
                      <DButton
                        class="workflow-step-option-list-editor__up_arrow"
                        @icon="arrow-up"
                        @title="admin.discourse_workflow.workflows.options.move_up"
                        {{on "click" (fn this.moveUp stepOption)}}
                      />
                    {{/unless}}
                    {{#unless
                      (this.islastOption
                        stepOption this.workflowStepOptions.length
                      )
                    }}
                      <DButton
                        class="workflow-step-option-list-editor__down_arrow"
                        @icon="arrow-down"
                        @title="admin.discourse_workflow.workflows.options.move_down"
                        {{on "click" (fn this.moveDown stepOption)}}
                      />
                    {{/unless}}
                    <LinkTo
                      @route="adminPlugins.show.discourse-workflow-workflows.steps.options.edit"
                      @models={{array
                        @workflowStep.workflow_id
                        @workflowStep.id
                        stepOption
                      }}
                      class="btn btn-text btn-small"
                    >{{i18n "admin.discourse_workflow.workflows.edit"}}
                    </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{/if}}
        <WorkflowLinkButton
          @route="adminPlugins.show.discourse-workflow-workflows.steps.options.new"
          @label="admin.discourse_workflow.workflows.steps.options.new"
          @model={{@workflowStep}}
        />
      {{/if}}
    </section>
  </template>
}
