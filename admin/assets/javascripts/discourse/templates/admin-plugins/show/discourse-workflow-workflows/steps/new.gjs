import WorkflowStepListEditor from "../../../../../components/workflow-step-list-editor";

export default <template>
  <WorkflowStepListEditor
    @currentWorkflowStep={{@controller.model}}
    @workflow={{@controller.model.workflow}}
  />
</template>
