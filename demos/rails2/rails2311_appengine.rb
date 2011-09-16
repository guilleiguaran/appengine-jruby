#!/usr/bin/ruby
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

require 'fileutils'
require 'open-uri'

def composite(source, fragment, index = nil, trim = nil)
  File.open(source, 'r+') do |f|
    lines = f.readlines
    lines = lines[0..trim] unless trim.nil?
    f.pos = 0
    File.open(fragment) do |z|
      section = z.readlines
      if index and index.size < lines.size
        f.print lines[0,index] + section + lines[index..-1]
      else 
        f.print lines + section
      end
    end
    f.truncate(f.pos)
  end 
  FileUtils.rm fragment
end

def download_file(path, url)
  open(url) do |r|
    FileUtils.mkpath(File.dirname(path))
    open(path,"w"){|f| f.write(r.read) }
  end
end
SET_CMD = RUBY_PLATFORM.include?('mswin32') ? 'set' : 'export'
MORE_GEMS = 'rails_appengine/active_support_vendored'
FILE_BASE = 'http://appengine-jruby.googlecode.com/hg/demos/rails2/'
MOD_FILES = %w{ app/controllers/rails/info_controller.rb public/favicon.ico
                config.ru config/boot_rb config/environment_rb
                config/initializers/gae_init_patch.rb config/database.yml
                script/console.sh script/publish.sh script/server.sh }
# Install Rails 2.3.11
FileUtils.touch 'config.ru'
gemsrc = ARGV[0].eql?('tiny_ds') ? 'Gemfile_td' : 'Gemfile'
download_file("Gemfile", "#{FILE_BASE}#{gemsrc}")
download_file("gems_2311", "#{FILE_BASE}gems_2311")
composite('Gemfile', 'gems_2311', nil, -2)
FileUtils.mkdir_p 'WEB-INF'
download_file("WEB-INF/app.yaml", "#{FILE_BASE}WEB-INF/app.yaml")
system 'appcfg.rb bundle --update .'
# Remove dups and generate Rails app
FileUtils.rm 'public/robots.txt'
# Generate rails, and skip APIs to escape the shell
system "rails _2.3.11_ ."
# Fetch configuration files
FileUtils.mkdir_p 'app/controllers/rails'
MOD_FILES.each { |path| download_file(path, "#{FILE_BASE}#{path}") }
if ARGV[0].eql? 'tiny_ds'
  download_file("config/environment_rb", "#{FILE_BASE}config/environment_td")
end
# Merge configs into boot.rb
composite('config/boot.rb', 'config/boot_rb', 108)
# Merge configs into environment.rb
composite('config/environment.rb', 'config/environment_rb', 30)
# Set permissions on scripts
%w{console server}.each {|f| FileUtils.chmod 0644, "script/#{f}" }
%w{console server publish}.each {|f| FileUtils.chmod 0744, "script/#{f}.sh" }
# install the nulldb adapter
system 'ruby script/plugin install http://svn.avdi.org/nulldb/trunk/'
puts "##"
puts "## Now type './script/server.sh'"
puts "##"
