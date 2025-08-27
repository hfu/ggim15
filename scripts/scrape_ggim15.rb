#!/usr/bin/env ruby
# Scrape UN-GGIM 15th Session documents page and extract direct links for Agenda #3-#17 Summary/Report
require 'net/http'
require 'uri'

BASE_URL = 'https://ggim.un.org/meetings/GGIM-committee/15th-Session/documents/'
TARGET_RANGE = (3..17)
OUT_PATH = ARGV[0] || 'data/urls.txt'

uri = URI(BASE_URL)
res = Net::HTTP.get_response(uri)
unless res.is_a?(Net::HTTPSuccess)
  STDERR.puts "Failed to fetch page: #{res.code} #{res.message}"
  exit 1
end
html = res.body

norm = html.gsub(/\r?\n/, "\n")

# Capture session-level informal papers and combined report
session_docs = []
norm.scan(/href=["']([^"']+Informal[^"']+\.pdf)["']/i) { |m| session_docs << m[0] }
norm.scan(/href=["']([^"']+Report-part_I_II_UN-GGIM15[^"']+\.pdf)["']/i) { |m| session_docs << m[0] }
session_docs.uniq!
session_docs.map! do |href|
  safe = href.gsub(' ', '%20')
  safe =~ /^https?:/ ? safe : URI.join(BASE_URL, safe).to_s
end

# Build mappings for agenda -> doc number
def doc_number_for_agenda(n)
  n + 1
end

def zero_pad(num)
  num < 10 ? format('%02d', num) : num.to_s
end

results = {}
TARGET_RANGE.each do |agenda|
  doc = doc_number_for_agenda(agenda)
  doc_padded = zero_pad(doc)

  # Summary English link patterns
  summary_re = /href=["']([^"']*E_C20_2025_#{doc}_[eE]\.pdf)["']/
  # Report link patterns (Add.1, Add_1, possibly multiple like Add_1 and Add_2)
  report_re = /href=["']([^"']*E_C20_2025_#{doc_padded}_(?:Add[\._]\d+)[^"']*\.pdf)["']/i

  agenda_block_re = /<div class="panel-collapse collapse" id="agendaTab#{agenda}"[\s\S]*?<\/div>\s*<\/div>/i
  block = norm[agenda_block_re]
  list = []
  if block
    # Summary (English)
    block.scan(summary_re) do |m|
      href = m[0]
  h = href.gsub(' ', '%20')
  abs = h =~ /^https?:/ ? h : URI.join(BASE_URL, h).to_s
      list << ['Summary (English)', abs]
    end
    # Reports (one or more)
    block.scan(report_re) do |m|
      href = m[0]
  h = href.gsub(' ', '%20')
  abs = h =~ /^https?:/ ? h : URI.join(BASE_URL, h).to_s
      list << ['Report', abs]
    end
  end
  results[agenda] = list
end

require 'fileutils'
FileUtils.mkdir_p(File.dirname(OUT_PATH))
File.open(OUT_PATH, 'w') do |f|
  unless session_docs.empty?
    f.puts '# Session-level documents'
    session_docs.each { |u| f.puts u }
    f.puts
  end
  TARGET_RANGE.each do |n|
    f.puts "# Agenda #{n}"
    items = results[n] || []
    # Ensure we output in desired order: Summary first, then Reports
    summary = items.select { |t, _| t =~ /Summary/i }.map { |_, u| u }
    reports = items.select { |t, _| t =~ /Report/i }.map { |_, u| u }
    summary.uniq.each { |u| f.puts "# Summary (English)\n#{u}" }
    reports.uniq.each { |u| f.puts "# Report\n#{u}" }
    f.puts
  end
end

puts "Wrote #{OUT_PATH}"
