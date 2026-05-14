import DPageSubheader from "discourse/components/d-page-subheader";
import { i18n } from "discourse-i18n";
import WorkflowListEditor from "../../../../components/workflow-list-editor";

export default <template>
  <div class="discourse-workflow-workflows admin-detail">
    <DPageSubheader
      @titleLabel={{i18n "admin.discourse_workflow.workflows.title"}}
      @descriptionLabel={{i18n
        "admin.discourse_workflow.workflows.instructions"
      }}
    >
      <:actions as |actions|>
        <actions.Primary
          @label="admin.discourse_workflow.workflows.new"
          @title="admin.discourse_workflow.workflows.new"
          @route="adminPlugins.show.discourse-workflow-workflows.new"
          @routeModels="discourse-workflow"
          @icon="plus"
          class="admin-workflows-new"
        />
      </:actions>
    </DPageSubheader>

    <div class="workflows-list">
      {{#if @controller.model.content.length}}
        <WorkflowListEditor @workflows={{@controller.model.content}} />
      {{else}}
        {{i18n "admin.discourse_workflow.workflows.none"}}
      {{/if}}
    </div>
  </div>
</template>
