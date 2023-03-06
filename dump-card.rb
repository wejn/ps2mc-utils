#!/usr/bin/env ruby

PYTHON = 'python2'

MYMC = File.join(File.realpath(File.dirname(__FILE__)), 'mymc', 'mymc.py')
unless FileTest.exists?(MYMC)
  STDERR.puts "- Can't find mymc.py (wanted: #{MYMC.inspect}"
  exit 1
end

if ARGV.size != 2
  STDERR.puts "- Usage: #{File.basename($0)} <card.ps2> <directory>"
  exit 2
end

card = ARGV[0]
dir = ARGV[1]

if FileTest.exists?(dir)
  if FileTest.directory?(dir)
    STDERR.puts "- Path #{dir.inspect} already exists."
    exit 3
  end

  STDERR.puts "- Path #{dir.inspect} isn't a directory."
  exit 4
else
  Dir.mkdir(dir)
end

unless FileTest.file?(card)
  STDERR.puts "- Path #{card.inspect} isn't a card file."
  exit 5
end

# Make the paths absolute
card = File.realpath(card)
dir = File.realpath(dir)

puts "+ Extracting contents ..."
def extract(card, target, source, indent=0)
  ok = true
  Dir.chdir(target) do
    IO.popen([PYTHON, MYMC, card, "ls", source], "r") do |io|
      io.each do |e|
	attrib, _entries, _date, _time, name = e.chomp.split(/\s+/, 5)
	next if name =~ /^\.+$/
	case attrib
	when /^.....d/
	  puts " "*indent + "> mkdir #{name}"
	  Dir.mkdir(name)
	  ok &= extract(card, File.join(target, name), File.join(source, name), indent+2)
	when /^....f/
	  puts " "*indent + "+ extract #{name}"
	  system(PYTHON, MYMC, card, "extract", "-d", source, name)
	  unless $?.exitstatus.zero?
	    puts " "*indent + "! extract failed"
	    ok = false
	  end
	else
	  STDERR.puts "! No idea what: #{attrib.inspect} #{name.inspect} in #{source} is."
	  ok = false
	end
      end
    end
  end
  ok
end

if extract(card, dir, ".", 2)
  puts "+ All done."
  exit 0
else
  puts "+ All done (with warnings/errors)."
  exit 6
end
