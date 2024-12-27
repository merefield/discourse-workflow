export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("discourse-workflow-workflows", { path: "workflows" }, function () {
      this.route("new");
      this.route("edit", { path: "/:id/edit" });
    });
    // Add routes for workflow_steps
    this.route("discourse-workflow-workflow-steps", { path: "workflow-steps" }, function () {
      this.route("new"); // New workflow step route
      this.route("edit", { path: "/:id/edit" }); // Edit workflow step route
    });
  },
};

//     this.route("discourse-workflow-workflow-steps", { path: "/:workflow_id/workflow_steps" }, function () {
//   this.route("new"); // New workflow step route
//   this.route("edit", { path: "/:workflow_step_id/edit" }); // Edit workflow step route
// });