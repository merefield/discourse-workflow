import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { cached, tracked } from "@glimmer/tracking";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { Input } from "@ember/component";
import Textarea from "discourse/components/d-textarea";
// import CategoryChooser from "discourse/components/category-chooser";
//import CategoryChooserComponent from "select-kit/components/category-chooser";
import CategoryChooser from "select-kit/components/category-chooser";
import DButton from "discourse/components/d-button";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DPageSubheader from "discourse/components/d-page-subheader";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import i18n from "discourse-common/helpers/i18n";
import AdminConfigAreaEmptyList from "admin/components/admin-config-area-empty-list";
import I18n from "discourse-i18n";

export default class WorkflowStepEditor extends Component {
  @service router;
  @service store;
  @service dialog;
  @service toasts;
  @service siteSettings;

  @tracked isSaving = false;
  @tracked editingModel = null;
  @tracked showDelete = false;


  @action
  updateModel() {
    this.editingModel = this.args.currentWorkflowStep.workingCopy();
    this.showDelete = !this.args.currentWorkflowStep.isNew && !this.args.currentWorkflowStep.system;
  }

  @action
  updateCategory(categoryId) {
    this.editingModel.category_id = categoryId;
  }

  @action
  save() {
    const isNew = this.args.currentWorkflowStep.isNew;
    this.isSaving = true;

    const backupModel = this.args.currentWorkflowStep.workingCopy();

    this.args.currentWorkflowStep.setProperties(this.editingModel);
    try {
      this.args.currentWorkflowStep.save();
      this.isSaving = false;
    } catch (err) {
      this.args.currentWorkflowStep.setProperties(backupModel);
      popupAjaxError(err);
    }
  }

  <template>
    {{!-- <BackButton
      @route="adminPlugins.show.discourse-workflow-workflows-edit/{{this.model.id}}"
      @label="admin.discourse_workflow.workflows.back"
    /> --}}
    <form
      class="form-horizontal workflow-step-editor"
      {{didUpdate this.updateModel @currentWorkflowStep.id}}
      {{didInsert this.updateModel @currentWorkflowStep.id}}
    >
      {{!-- <div class="control-group">
        <DToggleSwitch
          class="workflow-editor__enabled"
          @state={{@model.enabled}}
          @label="admin.discourse_workflow.workflows.enabled"
          {{on "click" this.toggleEnabled}}
        />
      </div> --}}
      <div class="control-group">
        <label>{{I18n.t "admin.discourse_workflow.workflows.name"}}</label>
        <Input
          class="workflow-editor__name"
          @type="text"
          @value={{this.editingModel.name}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        <CategoryChooser
          @value={{this.editingModel.category_id}}
          @onChangeCategory={{fn (mut this.editingModel.category_id)}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t "admin.discourse_workflow.workflows.description"}}</label>
        <Textarea
          class="workflow-editor__description"
          @value={{this.editingModel.description}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        {{!-- <label>{{I18n.t "admin.discourse_workflow.workflows.steps"}}</label> --}}
        {{!-- <WorkflowStepListEditor
          class="workflow-editor__steps"
          @id={{this.model.id}}
          @disabled={{this.editingModel.system}}
          @workflowSteps={{@workflow.workflow_steps}}
          @onChange={{this.stepsChanged}}
        /> --}}
      </div>
      {{!-- {{#unless this.editingModel.system}}
        <AiPersonaToolOptions
          @persona={{this.editingModel}}
          @tools={{this.selectedToolNames}}
          @allTools={{@personas.resultSetMeta.tools}}
        />
      {{/unless}} --}}
      <div class="control-group workflow-editor__action_panel">
        <DButton
          class="btn-primary workflow-editor__save"
          @action={{this.save}}
          @disabled={{this.isSaving}}
        >{{I18n.t "admin.discourse_workflow.workflows.save"}}</DButton>
        {{#if this.showDelete}}
          <DButton
            @action={{this.delete}}
            class="btn-danger workflow-editor__delete"
          >
            {{I18n.t "admin.discourse_workflow.workflows.delete"}}
          </DButton>
        {{/if}}
      </div>
    </form>
  </template>

  }