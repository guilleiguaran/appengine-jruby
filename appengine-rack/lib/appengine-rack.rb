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

require 'rack'

begin
  require 'appengine-apis/urlfetch'
  require 'appengine-apis/tempfile'
rescue Exception
end

module AppEngine
  module Rack
    # Split loading requests into 3 parts
    #
    # deferred_dispatcher = AppEngine::Rack::DeferredDispatcher.new(
    #     :require => File.expand_path('../config/environment', __FILE__),
    #     :dispatch => 'ActionController::Dispatcher')
    #
    # run deferred_dispatcher
    class DeferredDispatcher
      def initialize args
        @args = args
      end

      def call env
        if @runtime.nil?
          @runtime = true
          # 1: redirect with runtime and jruby-rack loaded
          redirect_or_error(env)
        elsif @rack_app.nil?
          require @args[:require]
          @rack_app = Object.module_eval(@args[:dispatch]).new
          # 2: redirect with framework required & dispatched
          redirect_or_error(env)
        else
          # 3: process all other requests
          @rack_app.call(env)
        end
      end

      def redirect_or_error(env)
        if env['REQUEST_METHOD'].eql?('GET')
          redir_url = env['REQUEST_URI'] +
              (env['QUERY_STRING'].eql?('') ? '?' : '&') + Time.now.to_i.to_s
          res = ::Rack::Response.new('*', 302)
          res['Location'] = redir_url
          res.finish
        else
          ::Rack::Response.new('Service Unavailable', 503).finish
        end
      end
    end

    class << self
      # Deprecated, use ENV['RACK_ENV'] instead
      def environment
        if !$servlet_context.nil? and
            $servlet_context.server_info.include? 'Development'
          'development'
        else
          'production'
        end
      end
    end
  end
end
