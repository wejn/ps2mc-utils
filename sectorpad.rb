#!/usr/bin/env ruby

RAW_SIZE = 16384 * 512
PAD_SIZE = 16384 * 528

if ARGV.size != 2
  STDERR.puts "Usage: #{File.basename($0)} <input.mcd> <output.ps2>"
  STDERR.puts
  STDERR.puts "This pads 8MB card with 512-byte sectors to 8MB card with 528-byte sectors."
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
  puts "+ Input size OK (RAW 8MB card with 512B sectors)"
when PAD_SIZE
  puts "- This is padded 8MB card (8MB card with 528B sectors), abort!"
  exit 2
else
  puts "- I don't know what the input file is, but it ain't 8MB card."
  exit 3
end

# The ECC code is adapted from ps2mc_ecc.py

def make_ecc_tables
  parity_table = (0..255).map do |a|
    a = (a ^ (a >> 1))
    a = (a ^ (a >> 2))
    a = (a ^ (a >> 4))
    a & 1
  end
  cpmasks = [0x55, 0x33, 0x0F, 0x00, 0xAA, 0xCC, 0xF0]
  column_parity_masks = Array.new(256, nil)
  0.upto(255) do |b|
    mask = 0
    cpmasks.each_with_index do |m, i|
      mask |= parity_table[b & m] << i
      column_parity_masks[b] = mask
    end
  end

  [parity_table, column_parity_masks]
end

PARITY_TABLE, COLUMN_PARITY_MASKS = make_ecc_tables

def ecc_calculate(s)
  column_parity = 0x77
  line_parity_0 = 0x7F
  line_parity_1 = 0x7F
  s.to_a.each_with_index do |c, i|
    column_parity ^= COLUMN_PARITY_MASKS[c]
    unless PARITY_TABLE[c].zero?
      line_parity_0 ^= ~i
      line_parity_1 ^= i
    end
  end
  [column_parity & 0xff, line_parity_0 & 0x7f, line_parity_1 & 0xff]
end

def ecc_calculate_page(page)
  raise "expect 512 bytes" unless page.size == 512
  b = page.bytes
  0.upto(3).each.map { |i| ecc_calculate(b[128*i, 128]) }.flatten
end


File.open(ofn, 'w', encoding: 'ascii-8bit') do |of|
  File.open(ifn, 'r', encoding: 'ascii-8bit') do |f|
    while e = f.read(512)
      # 16 = 528-512; we could do the checksum dance, but we won't
      of.write(e)
      ecc = ecc_calculate_page(e)
      ecc += Array.new(16 - ecc.size, "\x00")
      of.write(ecc.map { |c| c.chr }.join)
    end
  end
end

puts "+ Done."
exit 0
