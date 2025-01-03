import RestAdapter from "discourse/adapters/rest";

export default class Adapter extends RestAdapter {
  jsonMode = true;

  basePath(store, type, findArgs) {
    if (findArgs) {
      if (typeof findArgs === "object") {
        if (findArgs)
        return `/admin/plugins/discourse-workflow/workflows/${findArgs.workflow_id}/`
      } else {
        return `/admin/plugins/discourse-workflow/`
      }
    } else {
      return "/admin/plugins/discourse-workflow/";
    }
  }

  pathFor(store, type, findArgs) {
    // removes underscores which are implemented in base
    let path =
      this.basePath(store, type, findArgs) +
      store.pluralize(this.apiNameFor(type));
    return this.appendQueryParams(path, findArgs);
  }

  apiNameFor() {
    return "workflow_step";
  }
}
