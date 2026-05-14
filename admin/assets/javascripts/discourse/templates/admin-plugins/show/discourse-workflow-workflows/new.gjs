import WorkflowListEditor from "../../../../components/workflow-list-editor";

export default <template>
  <WorkflowListEditor
    @workflows={{@controller.allWorkflows}}
    @currentWorkflow={{@controller.model}}
  />
</template>
