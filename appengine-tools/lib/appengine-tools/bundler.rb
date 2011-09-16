#!/usr/bin/ruby1.8 -w
#
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

require 'appengine-rack'
require 'appengine-tools/boot'
require 'appengine-tools/gem_bundler'
require 'fileutils'
require 'yaml'

module AppEngine
  module Admin

    class Application
      attr_reader :root

      def initialize(root)
        @root = root
      end

      def path(*pieces)
        File.join(@root, *pieces)
      end

      def webinf
        path('WEB-INF')
      end

      def webinf_lib
        path('WEB-INF', 'lib')
      end

      def gems_jar
        path('WEB-INF', 'lib', 'gems.jar')
      end

      def generation_dir
        path('WEB-INF', 'appengine-generated')
      end

      def gems_dir
        path('.gems')
      end

      def gemfile
        path('Gemfile')
      end

      def config_ru
        path('config.ru')
      end

      def app_yaml
        path('WEB-INF', 'app.yaml')
      end

      def old_yaml
        path('app.yaml')
      end

      def bundled_jars
        path('WEB-INF', 'appengine-generated', 'bundled_jars.yaml')
      end

      def public_root
        @public_root ||= begin
          if File.exist?(app_yaml)
            app = YAML.load(IO.read(app_yaml))
            return path(app['public_root']) if app['public_root']
          end
          path('public')
        end
      end

      def favicon_ico
        File.join(public_root ? public_root : @root, 'favicon.ico')
      end

      def robots_txt
         File.join(public_root ? public_root : @root, 'robots.txt')
      end
    end

    class AppBundler
      EXISTING_APIS = /^appengine-api.*jar$/

      def initialize(root_path)
        @app = Application.new(root_path)
      end

      def bundle(args=[])
        bundle_deps(args)
        generate_config_ru
        generate_app_yaml
        create_public
      end

      def bundle_deps(args=[])
        confirm_appdir
        create_webinf
        bundle_gems(args)
      end

      def bundle_gems(args)
        gem_bundler = AppEngine::Admin::GemBundler.new(app.root)
        gem_bundler.bundle(args)
      end

      def app
        @app
      end

      def confirm_appdir
        if File.exists?(app.old_yaml)
          if File.exists?(app.app_yaml)
            puts ""
            puts "Warning, you have two versions of app.yaml."
            puts "We only use the version in the WEB-INF dir."
            puts ""
          else
            puts ""
            puts "Sorry, app.yaml needs to be inside the WEB-INF dir."
            puts "Don't worry, we are moving it there now."
            puts ""
            FileUtils.mv(app.old_yaml, app.app_yaml)
          end
        end
        unless File.exists?(app.app_yaml)or File.exists?(app.webinf)
          puts ""
          puts "Oops, this does not look like an application directory."
          puts "You need to create #{app.app_yaml}."
          puts ""
          puts "Run 'appcfg.rb generate_app #{app.path}'"
          puts "to generate a skeleton application."
          exit 1
        end
      end

      def create_webinf
        Dir.mkdir(app.webinf) unless File.exists?(app.webinf)
        Dir.mkdir(app.webinf_lib) unless File.exists?(app.webinf_lib)
        Dir.mkdir(app.generation_dir) unless File.exists?(app.generation_dir)
      end

      def create_public
        if app.public_root and !File.exists?(app.public_root)
          Dir.mkdir(app.public_root)
        end
        FileUtils.touch(app.favicon_ico) unless File.exists?(app.favicon_ico)
        FileUtils.touch(app.robots_txt) unless File.exists?(app.robots_txt)
      end

      def generate_config_ru
        unless File.exists?(app.config_ru)
          puts "=> Generating rackup"
          stock_rackup = "run lambda {Rack::Response.new('Hello').finish}\n"
          File.open(app.config_ru, 'w') {|f| f.write(stock_rackup) }
        end
      end

      def generate_app_yaml
        unless File.exists?(app.app_yaml)
          puts "=> Generating app.yaml"
          app_id = File.basename(File.expand_path(app.path)).
              downcase.gsub('_', '-').gsub(/[^-a-z0-9]/, '')
          stock_yaml = <<EOF
application: #{app_id}
version: 1
runtime: jruby
EOF
          File.open(app.app_yaml, 'w') {|f| f.write(stock_yaml)}
        end
      end

      private

      def find_jars(regex)
        Dir.entries(app.webinf_lib).grep(regex) rescue []
      end

      def update_jars(name, regex, jars, opt_regex=nil, opt_jars=[])
        existing = find_jars(regex)
        if existing.empty?
          message = "=> Installing #{name}"
          jars_to_install = jars + opt_jars
        else
          has_optional_jars = existing.any? {|j| j =~ opt_regex}
          expected_jars = jars
          expected_jars.concat(opt_jars) if has_optional_jars
          expected = expected_jars.map {|path| File.basename(path)}
          if existing.size != expected.size ||
              (expected & existing) != expected
            message = "=> Updating #{name}"
            jars_to_install = expected_jars
          end
        end
        if jars_to_install
          puts message
          remove_jars(existing)
          if block_given?
            yield
          else
            FileUtils.cp(jars_to_install, app.webinf_lib)
          end
        end
      end

      def remove_jars(jars)
        paths = jars.map do |jar|
          "#{app.webinf_lib}/#{jar}"
        end
        FileUtils.rm_f(paths)
      end
    end

    def self.bundle_app(*args)
      AppBundler.new(args.pop).bundle(args)
    end

    def self.bundle_deps(*args)
      AppBundler.new(args.pop).bundle(args)
    end

  end
end
