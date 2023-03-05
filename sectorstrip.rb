#!/usr/bin/env ruby

RAW_SIZE = 16384 * 512
PAD_SIZE = 16384 * 528

if ARGV.size != 2
  STDERR.puts "Usage: #{File.basename($0)} <input.ps2> <output.mcd>"
  STDERR.puts
  STDERR.puts "This strips padding from 8MB card with 528-byte sectors, writing out"
  STDERR.puts "8MB card with 512-byte sectors."
  STDERR.puts
  STDERR.puts "(which is useful for interop with Ross Ridge's \"mymc\" tool)"
  exit 1
end

ifn = ARGV[0]
ofn = ARGV[1]

s = nil
begin
  s = File.stat(ifn)
rescue Object
  STDERR.puts "Can't stat input file: #$!"
  exit 1
end

case s.size
when RAW_SIZE
  puts "- This is RAW 8MB card (8MB card with 512B sectors), abort!"
  exit 2
when PAD_SIZE
  puts "+ This is padded 8MB card, cool."
else
  puts "- I don't know what the input file is, but it ain't 8MB padded card."
  exit 3
end

File.open(ofn, 'w', encoding: 'ascii-8bit') do |of|
  File.open(ifn, 'r', encoding: 'ascii-8bit') do |f|
    while e = f.read(528)
      of.write(e[0,512])
    end
  end
end

puts "+ Done."
exit 0
