module GERA
  class Engine < ::Rails::Engine
    isolate_namespace GERA

    paths.add "app/workers",          eager_load: true
  end
end
