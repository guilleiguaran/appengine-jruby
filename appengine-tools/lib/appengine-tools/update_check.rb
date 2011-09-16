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

require 'yaml'
require 'open-uri'
begin
  require 'google-appengine'
rescue LoadError
end
require 'rubygems/version'

module AppEngine
  module Admin
    class UpdateCheck
      NAG_FILE = "~/.appcfg_rb_nag"
      MAX_NAG_FREQUENCY = 60 * 60 * 24 * 7
      DEFAULT_URL = 'http://appengine-jruby.googlecode.com/hg/updatecheck'

      def initialize(approot, url=nil, nag_file=nil)
        @url = url || DEFAULT_URL
        @approot = approot
        @nag_file = nag_file || File.expand_path(NAG_FILE)
      end

      def local_versions
        sdk_version = Gem::Version.new(AppEngine::VERSION) rescue nil
        {
          'google-appengine' => sdk_version,
          'appengine-apis' => find_gem_version('appengine-apis'),
          'dm-appengine' => find_gem_version('dm-appengine'),
        }
      end

      def find_gem_version(name)
        IO.foreach("#{@approot}/.gems/bundler_gems/environment.rb") do |line|
          if line =~ %r(/gems/#{name}-(\w+\.\w+.\w+)[/"])
            return Gem::Version.new($1)
          end
        end rescue nil
        nil
      end

      def remote_versions
        versions = YAML.load(open(@url).read)
        versions.inject({}) do |versions, (name, version)|
          versions[name] = Gem::Version.new(version)
          versions
        end
      end

      def check_for_updates
        local = local_versions
        unless local['google-appengine']
          puts '=> Skipping update check'
          return
        end
        latest = remote_versions
        local.each do |name, version|
          current = latest[name]
          if version && version < current
            prefix = if name == 'google-appengine'
              update_msg = "=> Please run sudo gem update google-appengine."
            else
              update_msg = "=> Please update your Gemfile."
            end
            puts "=> There is a new version of #{name}: #{current} " +
                "(You have #{version})"
            puts update_msg
          end
        end
      end

      def parse_nag_file
        @nag ||= if File.exist?(@nag_file)
          YAML.load_file(@nag_file)
        else
          {'opt_in' => true, 'timestamp' => 0}
        end
      end

      def write_nag_file(options)
        open(@nag_file, 'w') do |file|
          file.write(YAML.dump(options))
        end
      end

      def nag
        nag = parse_nag_file
        return if Time.now.to_i - nag['timestamp'] < MAX_NAG_FREQUENCY
        check_for_updates
        nag['timestamp'] = Time.now.to_i
        write_nag_file(nag)
      rescue OpenURI::HTTPError, Errno::ENOENT
        # check_for_updates will raise an error if we're not online
        # just ignore it, and don't update the nag timestamp.
      end

      def can_nag?
        parse_nag_file['opt_in']
      end
    end
  end
end
