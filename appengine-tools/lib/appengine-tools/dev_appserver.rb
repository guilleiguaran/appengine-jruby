#!/usr/bin/ruby
# Copyright:: Copyright 2009 Google Inc.
# Original Author:: John Woodell (mailto:woodie@google.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'appengine-sdk'
require 'appengine-tools/bundler'
require 'appengine-tools/update_check'

module AppEngine
  module Development
    DEV_APPSERVER = ['com.google.appengine.tools.development.DevAppServerMain']
    class JRubyDevAppserver
      class << self
        def run(args)
          path, java_args, server_args = parse_argv(ARGV)
          if path and File::directory?(path)
            AppEngine::Admin.bundle_app(path)
            updater = AppEngine::Admin::UpdateCheck.new(path)
            updater.nag if updater.can_nag?
            puts  "=> Booting DevAppServer"
            puts  "=> Press Ctrl-C to shutdown server"
          end
          start_java(path, java_args, server_args)
        end

        def parse_argv(argv)
          java_args = []
          server_args = []
          start_on_first_thread = false
          if RUBY_PLATFORM =~ /darwin/ ||
             (RUBY_PLATFORM == 'java' &&
              java.lang.System.getProperty("os.name").downcase == "mac os x")
            start_on_first_thread = true
          end
          argv.each do |arg|
            if arg =~ /^--jvm_flag=(.+)/
              java_args << $1
            elsif arg =~ /--startOnFirstThread=(true|false)/
              start_on_first_thread = ($1 == "true")
            else
              server_args << arg
            end
          end
          if start_on_first_thread
            java_args << '-XstartOnFirstThread'
          end
          return server_args[-1], java_args, server_args
        end

        def start_java(path, java_args, server_args)
          if path
            jruby_home = get_jruby_home(path)
            java_args << "-Djruby.home=#{jruby_home}" if jruby_home
            server_args[-1] = File.expand_path(path)
            Dir.chdir(path)
          end
          server_args.unshift '--disable_update_check'
          ENV.delete 'GEM_HOME'
          ENV.delete 'GEM_PATH'
          plugin_jar = File.join(File.dirname(__FILE__), 'app_yaml.jar')

          java_args << '-classpath'
          java_args << AppEngine::SDK::TOOLS_JAR
          java_args << '-Djava.util.logging.config.file=' +
              AppEngine::SDK::SDK_ROOT + '/config/sdk/logging.properties'
          java_args << "-Dcom.google.appengine.plugin.path=#{plugin_jar}"
          if defined? AppEngine::SDK::AGENT_JAR
            java_args << '-javaagent:' + AppEngine::SDK::AGENT_JAR
          end
          command = ['java'] + java_args + DEV_APPSERVER + server_args
          if ENV['VERBOSE']
            puts "exec #{command.map{|x| x.inspect}.join(' ')}"
          end
          exec(*command)
        end

        def get_jruby_home(path)
          return unless path
          Dir.chdir("#{path}/WEB-INF/lib") do
            jars = Dir.glob("appengine-jruby-*.jar").grep(
                /^appengine-jruby-\d+[.]\d+[.]\d+[.]jar$/)
            if !jars.empty?
              jar = File.expand_path(jars[0])
              return "file:/#{jar}!/META-INF/jruby.home"
            end
          end
          return nil
        end
      end
    end
  end
end
