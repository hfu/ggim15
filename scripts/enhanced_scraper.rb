#!/usr/bin/env ruby
# enhanced_scraper.rb - Enhanced document collector including Background Documents and CRP papers

require 'net/http'
require 'uri'

BASE_URL = 'https://ggim.un.org/meetings/GGIM-committee/15th-Session/documents/'
OUT_PATH = ARGV[0] || 'data/urls_complete.txt'

uri = URI(BASE_URL)
res = Net::HTTP.get_response(uri)
unless res.is_a?(Net::HTTPSuccess)
  STDERR.puts "Failed to fetch page: #{res.code} #{res.message}"
  exit 1
end
html = res.body

norm = html.gsub(/\r?\n/, "\n")

# All document categories
documents = {}

# Session-level documents
session_docs = []
norm.scan(/href=["']([^"']+(?:Informal|Report-part)[^"']+\.pdf)["']/i) { |m| session_docs << m[0] }

# Agenda documents (existing logic)
TARGET_RANGE = (3..17)
agenda_docs = {}
TARGET_RANGE.each do |agenda|
  doc = agenda + 1
  doc_padded = doc < 10 ? format('%02d', doc) : doc.to_s
  
  agenda_block_re = /<div class="panel-collapse collapse" id="agendaTab#{agenda}"[\s\S]*?<\/div>\s*<\/div>/i
  block = norm[agenda_block_re]
  
  list = []
  if block
    # Summary English
    block.scan(/href=["']([^"']*E_C20_2025_#{doc}_[eE]\.pdf)["']/i) do |m|
      list << ['Summary (English)', m[0]]
    end
    # Reports
    block.scan(/href=["']([^"']*E_C20_2025_#{doc_padded}_(?:Add[\._]\d+)[^"']*\.pdf)["']/i) do |m|
      list << ['Report', m[0]]
    end
    # Background documents
    block.scan(/href=["']([^"']+\.pdf)["'][^>]*>\s*[^<]*(?:Background|background)[^<]*</) do |m|
      unless m[0] =~ /E_C20_2025/  # Exclude main documents
        list << ['Background Document', m[0]]
      end
    end
    # Introductory statements
    block.scan(/href=["']([^"']+\.pdf)["'][^>]*>\s*[^<]*(?:Introductory|introductory)[^<]*</) do |m|
      list << ['Introductory Statement', m[0]]
    end
  end
  agenda_docs[agenda] = list if list.any?
end

# Additional documents (CRP, INF, etc.)
additional_docs = []
norm.scan(/href=["']([^"']+(?:CRP|INF|L\.)[^"']*\.pdf)["']/i) { |m| additional_docs << m[0] }

# Normalize URLs
def normalize_url(href)
  safe = href.gsub(' ', '%20')
  safe =~ /^https?:/ ? safe : URI.join(BASE_URL, safe).to_s
end

session_docs.map! { |href| normalize_url(href) }
additional_docs.map! { |href| normalize_url(href) }
agenda_docs.each do |agenda, list|
  list.map! { |type, href| [type, normalize_url(href)] }
end

# Write comprehensive output
require 'fileutils'
FileUtils.mkdir_p(File.dirname(OUT_PATH))
File.open(OUT_PATH, 'w') do |f|
  f.puts "# UN-GGIM 15th Session - Comprehensive Document Collection"
  f.puts "# Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  f.puts
  
  unless session_docs.empty?
    f.puts "# Session-level documents"
    session_docs.uniq.each { |u| f.puts u }
    f.puts
  end
  
  unless additional_docs.empty?
    f.puts "# Additional documents (CRP, INF, List)"
    additional_docs.uniq.each { |u| f.puts u }
    f.puts
  end
  
  agenda_docs.keys.sort.each do |agenda|
    f.puts "# Agenda #{agenda}"
    items = agenda_docs[agenda] || []
    
    # Group by type
    summaries = items.select { |t, _| t =~ /Summary/i }.map { |_, u| u }
    reports = items.select { |t, _| t =~ /Report/i }.map { |_, u| u }
    backgrounds = items.select { |t, _| t =~ /Background/i }.map { |_, u| u }
    intros = items.select { |t, _| t =~ /Introductory/i }.map { |_, u| u }
    
    summaries.uniq.each { |u| f.puts "# Summary (English)\n#{u}" }
    reports.uniq.each { |u| f.puts "# Report\n#{u}" }
    backgrounds.uniq.each { |u| f.puts "# Background Document\n#{u}" }
    intros.uniq.each { |u| f.puts "# Introductory Statement\n#{u}" }
    f.puts
  end
end

puts "Wrote comprehensive collection to #{OUT_PATH}"

# Count documents
total_docs = session_docs.size + additional_docs.size + agenda_docs.values.flatten.size
puts "Total documents found: #{total_docs}"
puts "Session documents: #{session_docs.size}"
puts "Additional documents: #{additional_docs.size}"
puts "Agenda-related documents: #{agenda_docs.values.flatten.size}"
