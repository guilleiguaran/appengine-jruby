import org.jruby.rack.DefaultRackApplicationFactory
import org.jruby.rack.RackApplicationFactory
import org.jruby.rack.RackInitializationException
import org.jruby.rack.RackServletContextListener
import org.jruby.rack.SharedRackApplicationFactory

class AppEngineRackApplicationFactory < DefaultRackApplicationFactory
  def initialize
  end

  def createApplicationObject(runtime)
    createRackServletWrapper(
        runtime, "eval(IO.read('config.ru'), nil, 'config.ru', 1)")
  end

  def createRackServletWrapper(runtime, rackup)
    runtime.evalScriptlet(<<-EOF)
      require 'appengine-rack/boot'
      load 'jruby/rack/boot/rack.rb'
      Rack::Handler::Servlet.new(Rack::Builder.new {( #{rackup}
      )}.to_app)
    EOF
  end
end

class LazyApplicationFactory; implements RackApplicationFactory
  def initialize
  end

  def init(context)
    @context = context
  end

  def real_factory
    throws RackInitializationException
    if @factory.nil?
      @factory = SharedRackApplicationFactory.new(
          AppEngineRackApplicationFactory.new)
      @factory.init(@context)
    end
    @factory
  end

  def newApplication
    throws RackInitializationException
    real_factory.newApplication
  end

  def getApplication
    throws RackInitializationException
    real_factory.getApplication
  end

  def finishedWithApplication(app)
    @factory.finishedWithApplication(app) unless @factory.nil?
  end

  def getErrorApplication
    real_factory.getErrorApplication rescue nil
  end

  def destroy
    @factory.destroy unless @factory.nil?
  end
end

class LazyContextListener < RackServletContextListener
  def newApplicationFactory(context)
    if context.getServerInfo.contains("Development")
      RackApplicationFactory(SharedRackApplicationFactory.new(
          RackApplicationFactory(AppEngineRackApplicationFactory.new)))
    else
      RackApplicationFactory(LazyApplicationFactory.new)
    end
  end
end

class BusyContextListener < RackServletContextListener
  def newApplicationFactory(context)
    RackApplicationFactory(SharedRackApplicationFactory.new(
        RackApplicationFactory(AppEngineRackApplicationFactory.new)))
  end
end
