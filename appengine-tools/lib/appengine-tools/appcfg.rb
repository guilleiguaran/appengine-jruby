#! /usr/bin/ruby
# Copyright:: Copyright 2009 Google Inc.
# Original Author:: Ryan Brown (mailto:ribrdb@google.com)
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
require 'appengine-tools/boot'
require 'appengine-tools/bundler'
require 'appengine-tools/update_check'
require 'yaml'

module AppEngine
  module Admin
    class JRubyAppCfg
      NO_XML_COMMANDS = %w{version}
      RUBY_COMMANDS = %w{gem bundle help run generate_app}
      COMMAND_SUMMARY = <<EOF
  run: run jruby in your application environment.
  bundle: package your application for deployment.
  The 'run' command assumes the app directory is the current directory.
EOF
      class << self
        def main(args)
          command, parsed_args = parse_args(args)
          if RUBY_COMMANDS.include? command
            send(command, *parsed_args)
            return
          end
          if command && !NO_XML_COMMANDS.include?(command)
            path = parsed_args[0]
            AppEngine::Admin.bundle_app(path)
            updater = AppEngine::Admin::UpdateCheck.new(path)
            updater.nag
          end
          puts "=> Running AppCfg"
          run_appcfg(args)
        end

        def run_appcfg(args)
          exec *(appcfg_command + args)
        end

        def generate_app(*args)
          if args and args.size > 0
            appdir = args.pop
            webinf = File.join(appdir, 'WEB-INF')
            FileUtils.mkdir_p(webinf)
            AppEngine::Admin.bundle_app(appdir)
          else
            generate_app_help
          end
        end

        def generate_app_help
          help = <<EOF
#{$0} generate_app app_dir

Generates a sample Rack application in app_dir.
The directory is created if it doesn't exist.

EOF
          puts help
        end

        def bundle(*args)
          if File.directory?(args[-1] || '')
            AppEngine::Admin.bundle_app(*args)
          else
            bundle_help
          end
        end

        def bundle_help
          help = <<EOF
#{$0} bundle [gem bundle options] app_dir

Bundles the gems listed in Gemfile and generates files necessary
to run an application as a servlet. This runs automatically for you,
but you need to run it manually to update gems if you don't specify
a version number. Pass --update to refresh bundled gems.

EOF
        end

        def gem(*args)
          gem_help
        end

        def gem_help
          help = <<EOF

Sorry, the 'appcfg.rb gem' option is deprecated.
Simply update the 'Gemfile' and run 'appcfg.rb bundle .' instead.

EOF
          puts help
        end

        def run(*args)
          AppEngine::Admin.bundle_deps('.')
          AppEngine::Development.boot_app('.', args)
        end

        def run_help
          help = <<EOF
#{$0} run [ruby args]

Starts the jruby interpreter within your application's environment.
Use `#{$0} run -S command` to run a command such as rake or irb.
Must be run from the application directory, after running bundle.

EOF
        end

        def appcfg_command
          plugin_jar = File.join(File.dirname(__FILE__), 'app_yaml.jar')
          command = %W(java -cp #{AppEngine::SDK::TOOLS_JAR})
          command << "-Dcom.google.appengine.plugin.path=#{plugin_jar}"
          command << 'com.google.appengine.tools.admin.AppCfg'
        end

        def help(command=nil)
          puts
          if command != 'help' && RUBY_COMMANDS.include?(command)
            puts send("#{command}_help")
          else
            java_args = appcfg_command << 'help'
            java_args << command if command
            print_help(%x{#{java_args.map{|x| x.inspect}.join(' ')}}, !command)
          end
        end

        def print_help(help, summary)
          help.gsub!('AppCfg', $0)
          count = 0
          help.each_line do |line|
            line.chomp!
            if summary && line.size > 0 && line.lstrip == line
              count += 1
              print COMMAND_SUMMARY if count == 3
            end
            puts line
          end
        end

        def parse_args(args)
          if RUBY_COMMANDS.include?(args[0])
            return [args[0], args[1, args.length]]
          elsif args.empty? || !(%w(-h --help) & args).empty?
            return ['help', []]
          elsif args[-3] == 'request_logs'
            command = args[-3]
            path = args[-2]
          else
            command = args[-2]
            path = args[-1]
          end
          return [command, [path]]
        end
      end
    end
  end
end
