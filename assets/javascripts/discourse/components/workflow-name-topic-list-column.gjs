import WorkflowNameLink from "./workflow-name-link";

const WorkflowNameTopicListColumn = <template>
  <td class="workflow-name">
    <WorkflowNameLink
      @topic_id={{@topic.id}}
      @workflow_name={{@topic.workflow_name}}
      @label={{@topic.workflow_name}}
    />
  </td>
</template>;

export default WorkflowNameTopicListColumn;
