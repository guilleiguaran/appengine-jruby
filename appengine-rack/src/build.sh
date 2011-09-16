#!/bin/sh
SDK_VER='1.4.0' # App Engine SDK gem version
JRR_VER='1.0.3' # JRuby-Rack gem version
GEM_DIR='/Library/Ruby/Gems/1.8/gems'
#DUBY_COMPLETE='/Developer/duby-complete.jar' # nightly jar

### Construct what we need to set the classpath
SDK_DIR="$GEM_DIR/appengine-sdk-$SDK_VER/appengine-java-sdk-$SDK_VER"
SERVLET="$SDK_DIR/lib/shared/servlet-api.jar"
JRUBY_RACK="$GEM_DIR/jruby-rack-$JRR_VER/lib/jruby-rack-$JRR_VER.jar"

### Generate class files from nightly jar (or installed gem)
mirahc -c $JRUBY_RACK:$SERVLET:. com/google/appengine/jruby/rack.mirah
