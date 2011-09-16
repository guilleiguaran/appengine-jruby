require File.dirname(__FILE__) + '/spec_helper.rb'
require 'appengine-tools/update_check'
require 'stringio'

module AppEngine
  VERSION = "3.2.1"
end

describe AppEngine::Admin::UpdateCheck do
  before :each do
    @update_check = AppEngine::Admin::UpdateCheck.new('approot', 'url', 'nag')
  end

  def versions(sdk, apis, dm)
    keys = ['google-appengine', 'appengine-apis', 'dm-appengine']
    hash = {}
    keys.zip([sdk, apis, dm]) do |key, value|
      hash[key] = value && Gem::Version.new(value)
    end
    hash
  end

  it 'should expand path' do
    File.should_receive(:expand_path).with(
        AppEngine::Admin::UpdateCheck::NAG_FILE)
    uc = AppEngine::Admin::UpdateCheck.new('/')
  end

  it 'should support local_versions' do
    expected = versions('3.2.1', '1.2.3', nil)
    @update_check.should_receive(:find_gem_version).twice.and_return(
        Gem::Version.new("1.2.3"), nil)
    @update_check.local_versions.should == expected
  end

  it 'should support remote_versions' do
    expected = versions('3.2.2', '1.2.4', '2.3.4')
    io = StringIO.new(YAML.dump(expected))
    @update_check.stub!(:open)
    @update_check.should_receive(:open).with("url").and_return(io)
    @update_check.remote_versions.should == expected
  end

  describe 'check_for_updates' do
    before :each do
      @update_check.stub!(:puts)
    end


    def expect_puts(*messages)
      length = messages.length
      @update_check.should_receive(:puts) do |arg|
        arg.should == messages.shift
      end.exactly(length).times
    end

    it 'should skip check if no sdk version' do
      @update_check.should_receive(:local_versions).and_return(
          versions(nil, nil, nil))
      expect_puts("=> Skipping update check")
      @update_check.check_for_updates
    end

    it 'should warn about old sdk' do
      @update_check.should_receive(:local_versions).and_return(
        versions('0.0.1', nil, nil))
      @update_check.should_receive(:remote_versions).and_return(
        versions('0.0.2', '0.0.2', '0.0.2'))
      expect_puts(
        "=> There is a new version of google-appengine: 0.0.2 (You have 0.0.1)",
        "=> Please run sudo gem update google-appengine."
      )
      @update_check.check_for_updates
    end

    it 'should warn about old apis' do
      @update_check.should_receive(:local_versions).and_return(
        versions('0.0.2', '0.0.2', '0.0.2'))
      @update_check.should_receive(:remote_versions).and_return(
        versions('0.0.2', '0.0.4', '0.0.2'))
      expect_puts(
        "=> There is a new version of appengine-apis: 0.0.4 (You have 0.0.2)",
        "=> Please update your Gemfile."
      )
      @update_check.check_for_updates
    end

    it 'should warn about old dm adapter' do
      @update_check.should_receive(:local_versions).and_return(
        versions('0.0.2', '0.0.2', '0.0.2'))
      @update_check.should_receive(:remote_versions).and_return(
        versions('0.0.2', '0.0.2', '0.0.3'))
      expect_puts(
        "=> There is a new version of dm-appengine: 0.0.3 (You have 0.0.2)",
        "=> Please update your Gemfile."
      )
      @update_check.check_for_updates
    end


    it 'should warn about multiple old gems' do
      @update_check.should_receive(:local_versions).and_return(
        versions('0.0.1', '0.0.3', '0.0.5'))
      @update_check.should_receive(:remote_versions).and_return(
        versions('0.0.2', '0.0.4', '0.0.5'))
      expect_puts(
        "=> There is a new version of google-appengine: 0.0.2 (You have 0.0.1)",
        "=> Please run sudo gem update google-appengine.",
        "=> There is a new version of appengine-apis: 0.0.4 (You have 0.0.3)",
        "=> Please update your Gemfile."
      )
      @update_check.check_for_updates
    end
  end

  describe 'parse_nag_file' do
    it 'should support missing file' do
      File.should_receive(:exist?).with('nag').and_return(false)
      @update_check.parse_nag_file.should == {
        'opt_in' => true,
        'timestamp' => 0
      }
    end

    it 'should parse existing file' do
      File.should_receive(:exist?).with('nag').and_return(true)
      YAML.should_receive(:load_file).with('nag').and_return("parsed_yaml")
      @update_check.parse_nag_file.should == "parsed_yaml"
    end
  end

  describe 'nag' do
    it 'should nag if old timestamp' do
      @update_check.should_receive(:parse_nag_file).and_return({
        'opt_in' => true,
        'timestamp' => Time.now.to_i - (60 * 60 * 24 * 8)
      })
      @update_check.should_receive(:check_for_updates)
      @update_check.should_receive(:write_nag_file)
      @update_check.nag
    end

    it 'should not nag if new timestamp' do
      @update_check.should_receive(:parse_nag_file).and_return({
        'opt_in' => true,
        'timestamp' => Time.now.to_i - (60 * 60 * 24 * 6)
      })
      @update_check.nag
    end
  end

  describe 'can_nag?' do
    it 'should return true of opted in' do
      @update_check.should_receive(:parse_nag_file).and_return({
        'opt_in' => true,
        'timestamp' => Time.now.to_i
      })
      @update_check.can_nag?.should == true
    end

    it 'should return false of opted out' do
      @update_check.should_receive(:parse_nag_file).and_return({
        'opt_in' => false,
        'timestamp' => Time.now.to_i
      })
      @update_check.can_nag?.should == false
    end
  end
end