// Copyright 2010 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.package com.google.appengine.jruby;

package com.google.appengine.jruby;

import com.google.apphosting.utils.config.AppYaml;
import java.util.List;
import java.util.ArrayList;

public class JRubyYamlPlugin implements AppYaml.Plugin {
  public AppYaml process(AppYaml yaml) {
    if ("jruby".equals(yaml.getRuntime())) {
      // Add the RackFilter
      AppYaml.Handler rackHandler = new AppYaml.Handler();
      rackHandler.setUrl("/*");
      rackHandler.setFilter("org.jruby.rack.RackFilter");
      List<AppYaml.Handler> handlers = yaml.getHandlers();
      if (handlers == null) {
        handlers = new ArrayList<AppYaml.Handler>();
        yaml.setHandlers(handlers);
      }
      handlers.add(rackHandler);

      // Add the ServletContextListener
      List<String> listeners = yaml.getListeners();
      if (listeners == null) {
        listeners = new ArrayList<String>();
        yaml.setListeners(listeners);
      }
      listeners.add("com.google.appengine.jruby.BusyContextListener");
   // listeners.add("org.jruby.rack.RackServletContextListener");
      
      // Add the warmup service
      List<String> services = yaml.getInbound_services();
      if (services == null) {
        services = new ArrayList<String>();
        yaml.setInbound_services(services);
      }
      services.add("warmup");

      // Set the public root.
      if (yaml.getPublic_root() == null) {
        yaml.setPublic_root("/public");
      }
    }
    return yaml;
  }
}
