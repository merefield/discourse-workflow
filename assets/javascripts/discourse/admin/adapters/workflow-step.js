import RestAdapter from "discourse/adapters/rest";

export default class Adapter extends RestAdapter {
  jsonMode = true;

  basePath(store, type, findArgs) {
    debugger;

    if (findArgs) {
      if (typeof findArgs === "object") {
        return `/admin/plugins/discourse-workflow/workflows/${findArgs.workflow_id}/`
      } else {
        return `/admin/plugins/discourse-workflow/`
        // return `/admin/plugins/discourse-workflow/workflows/${findArgs}/`
      }
    } else {
      return "/admin/plugins/discourse-workflow/";
    }
  }

  pathFor(store, type, findArgs) {
    debugger;
    // removes underscores which are implemented in base
    let path =
      this.basePath(store, type, findArgs) +
      store.pluralize(this.apiNameFor(type));
      return path;
    // return path  this.appendQueryParams(path, findArgs);
  }

  apiNameFor() {
    // debugger;
    return "workflow_step";
  }
}