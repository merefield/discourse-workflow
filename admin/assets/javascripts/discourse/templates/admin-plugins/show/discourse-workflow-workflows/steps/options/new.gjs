import WorkflowStepOptionListEditor from "../../../../../../components/workflow-step-option-list-editor";

export default <template>
  <WorkflowStepOptionListEditor
    @currentWorkflowStepOption={{@controller.model}}
    @workflowStep={{@controller.model.workflowStep}}
    @workflowSteps={{@controller.workflowSteps}}
    @workflowOptions={{@controller.workflowOptions}}
  />
</template>
