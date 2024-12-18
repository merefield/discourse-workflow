module ::DiscourseWorkflow
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseWorkflow
  end
end