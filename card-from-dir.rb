#!/usr/bin/env ruby

PYTHON = 'python2'

mymc = File.join(File.realpath(File.dirname(__FILE__)), 'mymc', 'mymc.py')
unless FileTest.exists?(mymc)
  STDERR.puts "- Can't find mymc.py (wanted: #{mymc.inspect}"
  exit 1
end

if ARGV.size != 2
  STDERR.puts "- Usage: #{File.basename($0)} <card.ps2> <directory>"
  exit 2
end

card = ARGV[0]
dir = ARGV[1]

unless FileTest.directory?(dir)
  STDERR.puts "- Path #{dir.inspect} isn't a directory."
  exit 3
end

puts "+ Formatting card #{card.inspect} ..."
system(PYTHON, mymc, card, 'format', '-f')
unless $?.exitstatus.zero?
  STDERR.puts "- Formatting failed, abort."
  exit 4
end

# Make the paths absolute
card = File.realpath(card)
dir = File.realpath(dir)

puts "+ Adding contents ..."
Dir.chdir(dir) do
  Dir['**/*'].each do |e|
    if FileTest.directory?(e)
      puts "> mkdir #{e.inspect}"
      system(PYTHON, mymc, card, "mkdir", e)
      unless $?.exitstatus.zero?
	STDERR.puts "- Mkdir failed, abort."
	exit 5
      end
    else
      puts "> add #{e.inspect}"
      system(PYTHON, mymc, card, "add", "-d", File.dirname(e), e)
      unless $?.exitstatus.zero?
	STDERR.puts "- Add failed, abort."
	exit 6
      end
    end
  end
end

puts "+ All done."
exit 0
