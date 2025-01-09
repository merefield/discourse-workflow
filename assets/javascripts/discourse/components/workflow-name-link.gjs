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
      model: { topic_id: this.args.topic_id, workflow_name: this.args.workflow_name },
    });
  };

  <template>
    <div class="workflow-action-button">
    <DButton
      class="btn-transparent"
      @action={{this.showVisualisationModal}}
    >
      {{this.args.label}}
    </DButton>
    </div>
  </template>
}