#!/usr/bin/ruby1.8 -w
#
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

require 'rubygems'
require 'fileutils'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'rubygems/command_manager'
require 'appengine-tools/bundler'

module AppEngine
  module Admin
    TARGET_VERSION = '1.8'
    TARGET_ENGINE = 'jruby'
    GEM_PLATFORM = Gem::Platform.new("universal-java-1.6")

    class GemBundler

      def initialize(root)
        @root = root
        @app = Application.new(root)
      end

      def bundle(args)
        verify_gemfile
        gem_bundle(args)
      end

      private

      def app
        @app
      end

      def gems_out_of_date
        if File.exists?(app.gems_jar) and
            File.stat(app.gems_jar).mtime > File.stat(app.gemfile).mtime
          return false
        end
        return true
      end

      def gem_bundle(args)
        return unless args.include?('--update') || gems_out_of_date
        Gem.platforms = [Gem::Platform::RUBY, GEM_PLATFORM]
        Gem.configuration = Gem::ConfigFile.new(args.unshift('bundle'))
        ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : nil
        # Override RUBY_ENGINE (we bundle from MRI for JRuby)
        Object.const_set('RUBY_ENGINE', TARGET_ENGINE)
        puts "=> Bundling gems"
        begin
          Dir.chdir(@root) do
            Gem::CommandManager.instance.run(Gem.configuration.args)
          end
        rescue Gem::SystemExitException => e
          exit e.exit_code unless e.exit_code == 0
        end
        # Restore RUBY_ENGINE (limit the scope of this hack)
        Object.const_set('RUBY_ENGINE', ruby_engine) unless ruby_engine.nil?
        bundler_dir = "#{app.gems_dir}/bundler_gems"
        target_pair = "#{TARGET_ENGINE}/#{TARGET_VERSION}"
        gem_patch = "require 'bundler_gems/#{target_pair}/environment'"
        File.open("#{bundler_dir}/environment.rb",'w') {|f| f << gem_patch }
        FileUtils.rm app.gems_jar, :force => true # blow away the old jar
        # cleanup old extension jars
        if File.exists? app.bundled_jars 
          YAML.load_file(app.bundled_jars).each do |jar|
            FileUtils.rm File.join(app.webinf_lib, jar), :force => true 
          end
        end
        # cleanup stale jars
        %w(appengine-jruby-0.0.7.pre.jar appengine-jruby-0.0.7.jar
           appengine-jruby-0.0.8.pre.jar jruby-rack-0.9.6.jar).each do |j|
          FileUtils.rm File.join(app.webinf_lib, j), :force => true
        end
        jars = []
        puts "=> Packaging gems"
        gem_files = Dir["#{bundler_dir}/#{target_pair}/dirs/**/**"] +
                    Dir["#{bundler_dir}/#{target_pair}/gems/**/**"] +
                    Dir["#{bundler_dir}/#{target_pair}/environment.rb"] +
                    Dir["#{bundler_dir}/environment.rb"]
        Zip::ZipFile.open(app.gems_jar, 'w') do |jar|
          gem_files.reject {|f| f == app.gems_jar}.each do |file|
            if file[-4..-1].eql? '.jar'
              puts "=> Installing #{File.basename(file)}"
              FileUtils.cp file, app.webinf_lib
              jars << File.basename(file)
            else
              jar.add(file.sub("#{app.gems_dir}/",''), file)
            end
          end
        end
        open(app.bundled_jars, 'w') { |f| YAML.dump(jars, f) }
      end

      def verify_gemfile
        return if File.exists?(app.gemfile)
        puts "=> Generating gemfile"
        # TODO: include the latest versions from updatecheck here?
        stock_gemfile = <<EOF
# Critical default settings:
disable_system_gems
disable_rubygems
bundle_path ".gems/bundler_gems"

# List gems to bundle here:
gem 'appengine-rack'
EOF
        File.open(app.gemfile,'w') {|f| f.write(stock_gemfile) }
      end
    end
  end
end

