#!/usr/bin/ruby1.8 -w
#
# Copyright:: Copyright 2009 Google Inc.
# Original Author:: John Wang (mailto:jwang392@gmail.com)
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
#

module AppEngine
  # OAuth protocol provides information useful for granting permissions, and
  # retrieving information about the user who is currently logged-in.
  module OAuth
    import com.google.appengine.api.users.User
    import com.google.appengine.api.oauth.OAuthRequestException;
    import com.google.appengine.api.oauth.OAuthService;
    import com.google.appengine.api.oauth.OAuthServiceFactory;
    import com.google.appengine.api.oauth.OAuthServiceFailureException;    
    
    Service = OAuthServiceFactory.getOAuthService
    
    class << self
      
      # If the user is logged in, this method will return a User that contains
      # information about them. Note that repeated calls may not necessarily
      # return the same User object.
      def current_user
          Service.current_user
      end
      
      # Returns the oauth_consumer_key OAuth parameter from the request.
      # Throws:
      # OAuthRequestException  - If the request was not a valid OAuth request. 
      # OAuthServiceFailureException - If an unknown OAuth error occurred.
      def oauth_consumer_key
        Service.get_oauth_consumer_key
      end
      
      # Returns true if the user making this request is an admin for this
      # application, false otherwise.
      # 
      # This is a separate function, and not a member function of the User
      # class, because admin status is not persisted in the datastore. It
      # only exists for the user making this request right now.
      def admin?
        Service.is_user_admin?
      end
    end

  end
end