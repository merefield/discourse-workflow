import { setupTest } from "ember-qunit";
import { module, test } from "qunit";

module(
  "Unit | Route | admin-plugins-show-discourse-workflow-workflows-steps-options",
  function (hooks) {
    setupTest(hooks);

    test("it resolves workflow steps from the expected parent route model", async function (assert) {
      const route = this.owner.lookup(
        "route:admin-plugins-show-discourse-workflow-workflows-steps-options"
      );

      const workflowSteps = [
        { id: 1, workflow_id: 42 },
        { id: 2, workflow_id: 42 },
      ];
      workflowSteps.findBy = (key, value) =>
        workflowSteps.find((step) => step[key] === value);

      route.modelFor = (routeName) => {
        assert.strictEqual(
          routeName,
          "adminPlugins.show.discourse-workflow-workflows-steps",
          "uses the canonical parent route key"
        );
        return workflowSteps;
      };

      route.store = {
        async findAll(type, params) {
          assert.strictEqual(type, "workflow-step-option");
          assert.deepEqual(params, { workflow_step_id: 2, workflow_id: 42 });
          return { content: [{ id: 99 }] };
        },
      };

      const result = await route.model({ step_id: "2" });
      assert.deepEqual(result, [{ id: 99 }]);
    });
  }
);
