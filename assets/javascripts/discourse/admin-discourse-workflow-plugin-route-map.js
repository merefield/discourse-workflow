export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("discourse-workflow-workflows", { path: "workflows" }, function () {
      this.route("new");
      this.route("edit", { path: "/:id/edit" });
    });
  },
};