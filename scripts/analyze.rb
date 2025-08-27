#!/usr/bin/env ruby
# analyze.rb - Document analysis and management for NotebookLM preparation

require 'optparse'
require 'fileutils'
require 'json'

options = {
  docs_dir: 'docs/raw',
  out_dir: 'out',
  format: 'summary'
}

opts = OptionParser.new do |o|
  o.banner = "Usage: analyze.rb [options]"
  o.on('-d', '--docs DIR', 'Documents directory (default: docs/raw)') { |v| options[:docs_dir] = v }
  o.on('-o', '--out DIR', 'Output directory (default: out)') { |v| options[:out_dir] = v }
  o.on('-f', '--format FORMAT', 'Output format: summary, inventory, notebooklm (default: summary)') { |v| options[:format] = v }
  o.on('-h', '--help', 'Show this help') { puts o; exit 0 }
end

begin
  opts.parse!(ARGV)
rescue => e
  STDERR.puts e.message
  STDERR.puts opts
  exit 2
end

docs_dir = options[:docs_dir]
out_dir = options[:out_dir]

unless Dir.exist?(docs_dir)
  STDERR.puts "Error: Documents directory '#{docs_dir}' not found"
  exit 1
end

FileUtils.mkdir_p(out_dir)

# Scan documents
files = Dir.glob(File.join(docs_dir, '*')).select { |f| File.file?(f) }
if files.empty?
  STDERR.puts "Warning: No files found in #{docs_dir}"
  exit 0
end

# Categorize by pattern
session_docs = files.select { |f| File.basename(f) =~ /Informal|Report-part/i }
agenda_docs = files.select { |f| File.basename(f) =~ /E_C20_2025_\d+/i }

# Group agenda docs
agenda_groups = {}
agenda_docs.each do |f|
  basename = File.basename(f)
  if basename =~ /E_C20_2025_(\d+)_([eE])\.pdf/
    agenda_num = $1.to_i - 1  # Convert doc number back to agenda number
    agenda_groups[agenda_num] ||= { summary: nil, reports: [] }
    agenda_groups[agenda_num][:summary] = f
  elsif basename =~ /E_C20_2025_(\d+)_Add/i
    agenda_num = $1.to_i - 1
    agenda_groups[agenda_num] ||= { summary: nil, reports: [] }
    agenda_groups[agenda_num][:reports] << f
  end
end

case options[:format]
when 'summary'
  puts "UN-GGIM 15th Session Documents Analysis"
  puts "=" * 50
  puts
  puts "Session-level documents: #{session_docs.size}"
  session_docs.each { |f| puts "  - #{File.basename(f)}" }
  puts
  puts "Agenda items: #{agenda_groups.keys.size}"
  agenda_groups.keys.sort.each do |agenda|
    puts "  Agenda #{agenda}:"
    puts "    Summary: #{agenda_groups[agenda][:summary] ? 'Yes' : 'No'}"
    puts "    Reports: #{agenda_groups[agenda][:reports].size}"
  end
  puts
  puts "Total files: #{files.size}"
  puts "Total size: #{files.sum { |f| File.size(f) } / 1024.0 / 1024.0}MB"

when 'inventory'
  inventory = {
    generated_at: Time.now.iso8601,
    total_files: files.size,
    total_size_mb: files.sum { |f| File.size(f) } / 1024.0 / 1024.0,
    session_documents: session_docs.map { |f| { name: File.basename(f), size_kb: File.size(f) / 1024.0 } },
    agenda_items: agenda_groups.transform_values do |group|
      {
        summary: group[:summary] ? File.basename(group[:summary]) : nil,
        reports: group[:reports].map { |f| File.basename(f) }
      }
    end
  }
  
  out_file = File.join(out_dir, 'inventory.json')
  File.write(out_file, JSON.pretty_generate(inventory))
  puts "Wrote inventory to #{out_file}"

when 'notebooklm'
  guide_file = File.join(out_dir, 'notebooklm_guide.md')
  File.open(guide_file, 'w') do |f|
    f.puts "# UN-GGIM 15th Session - NotebookLM Analysis Guide"
    f.puts
    f.puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    f.puts
    f.puts "## 1. Upload Strategy"
    f.puts
    f.puts "Upload all #{files.size} PDF files from `docs/raw/` to NotebookLM:"
    f.puts
    f.puts "### Session Documents (#{session_docs.size} files)"
    session_docs.each { |file| f.puts "- #{File.basename(file)}" }
    f.puts
    f.puts "### Agenda Items (#{agenda_groups.keys.size} items)"
    agenda_groups.keys.sort.each do |agenda|
      f.puts "#### Agenda #{agenda}"
      if agenda_groups[agenda][:summary]
        f.puts "- Summary: #{File.basename(agenda_groups[agenda][:summary])}"
      end
      agenda_groups[agenda][:reports].each do |report|
        f.puts "- Report: #{File.basename(report)}"
      end
      f.puts
    end
    
    f.puts "## 2. Analysis Questions"
    f.puts
    f.puts "### Cross-cutting Analysis"
    f.puts "- 各 Agenda item（#3〜#17）の Summary と Report の要点を 5 行で要約してください"
    f.puts "- Summary と Report の相違点と補完関係を議題ごとに整理してください"
    f.puts "- 重要な用語・定義・アクター（機関名）を抽出してください"
    f.puts "- 横断的論点（共通する課題、データ標準、実装状況、地域差）を比較してください"
    f.puts
    f.puts "### Specific Focus Areas"
    f.puts "- 地理空間情報管理における新興技術（AI、クラウド等）への言及を整理してください"
    f.puts "- 国際連携・地域委員会の役割分担について分析してください"
    f.puts "- データ標準化とベストプラクティスの共有に関する提言をまとめてください"
    f.puts
    f.puts "## 3. Output Organization"
    f.puts
    f.puts "分析結果は以下に整理してください："
    f.puts "- `out/executive_summary.md` - 全体要約"
    f.puts "- `out/agenda_analysis/` - 議題別詳細分析"
    f.puts "- `out/cross_cutting_themes.md` - 横断的テーマ"
    f.puts "- `out/recommendations.md` - 提言・次期アクション"
  end
  
  puts "Wrote NotebookLM guide to #{guide_file}"
  puts "Next steps:"
  puts "1. Upload all files from docs/raw/ to NotebookLM"
  puts "2. Follow the analysis questions in #{guide_file}"
  puts "3. Save results in out/ directory as suggested"

else
  STDERR.puts "Unknown format: #{options[:format]}"
  exit 1
end
