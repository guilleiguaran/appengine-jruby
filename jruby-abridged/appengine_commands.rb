require 'rbconfig'

module JRuby
  class Commands
    class << self
      def find_script(name)
        script = Config::CONFIG['bindir'] + "/#{name}"
        ruby_bin = nil
        if File.exists? script
          ruby_bin = File.open(script) {|io| (io.readline rescue "") =~ /^#!.*ruby/} rescue nil
        else
          require 'rubygems'
          Gem.source_index.each do |_, spec|
            puts "#{spec.name}: #{spec.executables.inspect}" if ENV['VERBOSE']
            if spec.executables.include?(name)
              script = File.join(spec.full_gem_path, spec.bindir, name)
              ruby_bin = true
              puts "found #{script}" if ENV['VERBOSE']
              break
            end
          end
        end rescue nil
        return script, ruby_bin
      end
      
      # Provide method aliases to scripts commonly found in ${jruby.home}/bin.
      dollar_zero, ruby_bin = Commands.find_script($0)
      if ruby_bin
        define_method File.basename(dollar_zero) do
          $0 = dollar_zero
          load dollar_zero
        end
      end

      def maybe_install_gems
        require 'rubygems'
        ARGV.delete_if do |g|
          begin
            # Want the kernel gem method here
            # Hack to make it public; RubyGems 1.3.1 made it private. TODO: less grossness.
            Object.class_eval { public :gem }
            Object.new.gem g
            puts "#{g} already installed"
            true
          rescue Gem::LoadError
            false
          end
        end
        unless ARGV.reject{|a| a =~ /^-/}.empty?
          ARGV.unshift "install"
          load Config::CONFIG['bindir'] + "/gem"
        end
        generate_bat_stubs
      end

      def generate_bat_stubs
        Dir[Config::CONFIG['bindir'] + '/*'].each do |fn|
          next unless File.file?(fn)
          next if fn =~ /.bat$/
          next if File.exist?("#{fn}.bat")
          next unless File.open(fn) {|io| (io.readline rescue "") =~ /^#!.*ruby/}
          puts "Generating #{File.basename(fn)}.bat"
          File.open("#{fn}.bat", "wb") do |f|
            f << "@echo off\n"
            f << "call \"%~dp0jruby\" -S #{File.basename(fn)} %*\n"
          end
        end
      end

      def method_missing(name, *)
        $stderr.puts "jruby: No such file, directory, or command -- #{name}"
      end
    end
  end
end

