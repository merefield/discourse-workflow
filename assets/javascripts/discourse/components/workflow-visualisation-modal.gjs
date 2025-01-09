import Component from "@ember/component";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";
import WorkflowVisualisation from "./workflow-visualisation";

export default class WorkflowVisualisationModalComponent extends Component {
  get title() {
    return i18n("discourse_workflow.topic_banner.visualisation_title", { workflow_name: this.model.workflow_name });
  }

  <template>
    <DModal
      @title={{this.title}}
      @closeModal={{@closeModal}}
      class="workflow-visualisation-modal"
    >
      <WorkflowVisualisation @model={{@model}}/>
    </DModal>
  </template>
};
