export default {
  resource: "discovery",

  map() {
    this.route("workflowCharts", { path: "/workflow/charts" });
  },
};
