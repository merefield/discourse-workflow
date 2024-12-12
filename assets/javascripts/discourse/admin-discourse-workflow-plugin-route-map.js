export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("discourse-worflows", { path: "workflow" }, function () {
      this.route("new");
      this.route("edit", { path: "/:id/edit" });
    });
  },
};