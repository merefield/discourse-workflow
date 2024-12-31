export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("discourse-workflow-workflows", { path: "/workflows" }, function () {
      this.route("new");
      this.route("edit", { path: "/:workflow_id/edit" });
      this.route("steps", { path: "/:workflow_id/workflow_steps" }, function () {
        this.route("new"); // New workflow step route
        this.route("edit", { path: "/:step_id/edit" }); // Edit workflow step route
      });
    });
  },
};

//     this.route("discourse-workflow-workflow-steps", { path: "/:workflow_id/workflow_steps" }, function () {
//   this.route("new"); // New workflow step route
//   this.route("edit", { path: "/:workflow_step_id/edit" }); // Edit workflow step route
// });