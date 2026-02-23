import SortableColumn from "discourse/components/topic-list/header/sortable-column";
import { addDiscoveryQueryParam } from "discourse/controllers/discovery/list";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import WorkflowNameLink from "./../components/workflow-name-link";

const WORKFLOW_LIST_ROUTES = ["discovery.workflow", "discovery.workflowCharts"];

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

const workflowOverdueHeader = <template>
  <th class="topic-list-data workflow-overdue-column">
    {{i18n "workflow-overdue"}}
  </th>
</template>;

const workflowOverdueCell = <template>
  <td class="workflow-overdue">
    {{#if @topic.workflow_overdue}}
      <span class="workflow-overdue-indicator">{{i18n
          "discourse_workflow.overdue_indicator"
        }}</span>
    {{/if}}
  </td>
</template>;

export default {
  name: "discourse-workflow-initializer",

  initialize(container) {
    const router = container.lookup("service:router");

    addDiscoveryQueryParam("my_categories", {
      replace: true,
      refreshModel: true,
    });
    addDiscoveryQueryParam("overdue_days", {
      replace: true,
      refreshModel: true,
    });
    addDiscoveryQueryParam("overdue", {
      replace: true,
      refreshModel: true,
    });
    addDiscoveryQueryParam("workflow_step_position", {
      replace: true,
      refreshModel: true,
    });
    addDiscoveryQueryParam("workflow_view", {
      replace: true,
      refreshModel: false,
    });
    addDiscoveryQueryParam("chart_weeks", {
      replace: true,
      refreshModel: false,
    });

    withPluginApi((api) => {
      api.addAdminPluginConfigurationNav("discourse-workflow", [
        {
          label: "admin.discourse_workflow.workflows.title",
          route: "adminPlugins.show.discourse-workflow-workflows",
        },
      ]);

      api.addNavigationBarItem({
        name: "workflow",
        href: "/workflow",
      });

      api.registerValueTransformer("topic-list-item-class", ({ value }) => {
        if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
          value.push("workflow-list");
        }
        return value;
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

      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
            columns.add("workflow-overdue", {
              header: workflowOverdueHeader,
              item: workflowOverdueCell,
              after: "workflow-step-name",
            });
          }
          return columns;
        }
      );

      api.addPostSmallActionIcon("workflow_transition", "right-left");
    });
  },
};
