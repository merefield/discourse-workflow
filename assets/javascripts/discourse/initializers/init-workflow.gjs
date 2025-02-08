import SortableColumn from "discourse/components/topic-list/header/sortable-column";
import { withPluginApi } from "discourse/lib/plugin-api";
import WorkflowNameLink from "./../components/workflow-name-link";

const WORKFLOW_LIST_ROUTES = ["discovery.workflow"];

const workflowNameHeader = <template>
  <SortableColumn
    @sortable={{@sortable}}
    @number="false"
    @order="workflow-name"
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name="workflow-name"
  />
</template>;

const workflowNameCell = <template>
  <td class="workflow-name">
    <WorkflowNameLink
      @topic_id={{@topic.id}}
      @workflow_name={{@topic.workflow_name}}
      @label={{@topic.workflow_name}}
    />
  </td>
</template>;

const workflowStepPositionHeader = <template>
  <SortableColumn
    @sortable={{@sortable}}
    @number="true"
    @order="workflow-step-position"
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name="workflow-step-position"
  />
</template>;

const workflowStepPositionCell = <template>
  <td class="workflow-step-position">
    <WorkflowNameLink
      @topic_id={{@topic.id}}
      @workflow_name={{@topic.workflow_name}}
      @label={{@topic.workflow_step_position}}
    />
  </td>
</template>;

const workflowStepNameHeader = <template>
  <SortableColumn
    @sortable={{@sortable}}
    @number="false"
    @order="workflow-step-name"
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name="workflow-step-name"
  />
</template>;

const workflowStepNameCell = <template>
  <td class="workflow-step-name">
    <WorkflowNameLink
      @topic_id={{@topic.id}}
      @workflow_name={{@topic.workflow_name}}
      @label={{@topic.workflow_step_name}}
    />
  </td>
</template>;

export default {
  name: "discourse-workflow-initializer",

  initialize(container) {
    const router = container.lookup("service:router");

    withPluginApi("1.39.0", (api) => {
      api.addAdminPluginConfigurationNav(
        "discourse-workflow",
        [
          {
            label: "admin.discourse_workflow.workflows.title",
            route: "adminPlugins.show.discourse-workflow-workflows",
          },
        ]
      );

      api.addNavigationBarItem({
        name: "workflow",
        href: "/workflow",
      });

      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
            columns.add("workflow-name", {
              header: workflowNameHeader,
              item: workflowNameCell,
              after: "activity",
            });
          }
          return columns;
        }
      );

      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
            columns.add("workflow-step-position", {
              header: workflowStepPositionHeader,
              item: workflowStepPositionCell,
              after: "workflow-name",
            });
          }
          return columns;
        }
      );

      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
            columns.add("workflow-step-name", {
              header: workflowStepNameHeader,
              item: workflowStepNameCell,
              after: "workflow-step-position",
            });
          }
          return columns;
        }
      );

      api.addPostSmallActionIcon("workflow_transition", "right-left");
    });
  },
};
