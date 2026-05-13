import SortableColumn from "discourse/components/topic-list/header/sortable-column";

const WorkflowNameCell = <template>
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

export default WorkflowNameCell;
