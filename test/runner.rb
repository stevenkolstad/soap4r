require 'test/unit/testsuite'
require 'test/unit/testcase'
require 'optparse'

$KCODE = 'UTF8'

rcsid = %w$Id: runner.rb,v 1.2 2003/09/13 10:39:42 nahi Exp $
Version = rcsid[2].scan(/\d+/).collect!(&method(:Integer)).freeze
Release = rcsid[3].freeze

class BulkTestSuite < Test::Unit::TestSuite
  def self.suite
    suite = Test::Unit::TestSuite.new
    ObjectSpace.each_object(Class) do |klass|
      suite << klass.suite if (Test::Unit::TestCase > klass)
    end
    suite
  end
end

runners_map = {
  'console' => proc do |suite|
    require 'test/unit/ui/console/testrunner'
    passed = Test::Unit::UI::Console::TestRunner.run(suite).passed?
    exit(passed ? 0 : 1)
  end,
  'gtk' => proc do |suite|
    require 'test/unit/ui/gtk/testrunner'
    Test::Unit::UI::GTK::TestRunner.run(suite)
  end,
  'fox' => proc do |suite|
    require 'test/unit/ui/fox/testrunner'
    Test::Unit::UI::Fox::TestRunner.run(suite)
  end,
}

runner = 'console'
opt = OptionParser.new
opt.program_name = $0
opt.banner << " [tests...]"
opt.on("--runner=mode", runners_map.keys, "UI mode (console, gtk,fox)") do |arg|
  runner = arg
end
begin
  argv = opt.parse(*ARGV)
rescue OptionParser::ParseError
  opt.abort($!)
end

if argv.empty?
  argv = Dir.glob(File.join(File.dirname(__FILE__), "**", "test_*.rb")).sort
end

argv.each do |tc_name|
  require tc_name
end

runners_map[runner].call(BulkTestSuite.suite)