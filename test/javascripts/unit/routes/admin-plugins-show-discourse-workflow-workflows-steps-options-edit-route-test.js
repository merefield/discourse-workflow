import { setupTest } from "ember-qunit";
import { module, test } from "qunit";

module(
  "Unit | Route | admin-plugins-show-discourse-workflow-workflows-steps-options-edit",
  function (hooks) {
    setupTest(hooks);

    test("it loads edit dependencies without requiring nested router state", async function (assert) {
      const route = this.owner.lookup(
        "route:admin-plugins-show-discourse-workflow-workflows-steps-options-edit"
      );

      let workflowStepParams;
      route.store = {
        async findAll(type, params) {
          switch (type) {
            case "workflow-option":
              return { content: [{ id: 1, name: "Start", slug: "start" }] };
            case "workflow-step":
              workflowStepParams = params;
              return {
                content: [
                  { id: 3, workflow_id: 12 },
                  { id: 4, workflow_id: 12 },
                ],
              };
            default:
              throw new Error(`unexpected type: ${type}`);
          }
        },
      };

      const controller = {
        values: {},
        set(key, value) {
          this.values[key] = value;
        },
      };
      const model = { workflow_id: 12, workflow_step_id: 4 };

      await route.setupController(controller, model);

      assert.deepEqual(workflowStepParams, { workflow_id: 12 });
      assert.strictEqual(controller.values.workflowOptions.length, 1);
      assert.strictEqual(controller.values.workflowSteps.length, 2);
      assert.strictEqual(controller.values.workflowStep.id, 4);
    });
  }
);
