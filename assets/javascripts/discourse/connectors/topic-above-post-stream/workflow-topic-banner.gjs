import WorkflowTopicBanner from "../../components/workflow-topic-banner";

export default <template>
  <WorkflowTopicBanner
    @workflow_step_options={{@outletArgs.model.workflow_step_options}}
    @workflow_step_actions={{@outletArgs.model.workflow_step_actions}}
    @workflow_step_position={{@outletArgs.model.workflow_step_position}}
    @workflow_step_name={{@outletArgs.model.workflow_step_name}}
    @workflow_name={{@outletArgs.model.workflow_name}}
    @workflow_can_act={{@outletArgs.model.workflow_can_act}}
    @workflow_step_entered_at={{@outletArgs.model.workflow_step_entered_at}}
    @topic_id={{@outletArgs.model.id}}
    @category_id={{@outletArgs.model.category_id}}
  />
</template>;
