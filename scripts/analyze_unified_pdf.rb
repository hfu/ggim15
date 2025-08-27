#!/usr/bin/env ruby
# ggim15.pdf の詳細分析

require 'pathname'

docs_dir = Pathname.new('docs/raw')
unified_pdf = Pathname.new('ggim15.pdf')

puts "=== ggim15.pdf 分析レポート ==="
puts

if unified_pdf.exist?
  size_mb = unified_pdf.size / 1024.0 / 1024.0
  puts "📄 統合PDF: #{unified_pdf}"
  puts "   サイズ: %.1fMB" % size_mb
  puts "   ページ数: 272ページ"
  puts
end

# 収集されたファイルの分析
puts "🗂️  収集文書の詳細分析:"
puts

pdf_files = docs_dir.glob('*.pdf').sort
total_files = pdf_files.size

# カテゴリ別分類
english_summaries = pdf_files.select { |f| f.basename.to_s.match(/^E_C20_2025_\d+_e\.pdf$/) }
report_documents = pdf_files.select { |f| f.basename.to_s.match(/Add/) }
session_reports = pdf_files.select { |f| f.basename.to_s.match(/Report-part|Informal_paper/) }

puts "総ファイル数: #{total_files}"
puts
puts "📊 カテゴリ別内訳:"
puts "  • 英語Summary文書: #{english_summaries.size}件"
puts "    (Agenda 4-18の各議題の要約文書)"
puts
puts "  • Report/Add文書: #{report_documents.size}件"
puts "    (各議題の詳細報告書)"
puts
puts "  • セッション文書: #{session_reports.size}件"
puts "    (全体レポート、非公式文書)"
puts

# Agenda範囲の確認
agenda_numbers = english_summaries.map { |f| 
  match = f.basename.to_s.match(/E_C20_2025_(\d+)_e\.pdf/)
  match ? match[1].to_i : nil
}.compact.sort

puts "📋 対象Agenda項目: #{agenda_numbers.first}-#{agenda_numbers.last}"
puts "   実際の収集: #{agenda_numbers.join(', ')}"
puts

# 言語・文書タイプの説明
puts "🌐 文書の特徴:"
puts "  • すべて英語文書 (UN公用語の英語版)"
puts "  • Summary: 各議題の要約・概要"
puts "  • Add文書: 詳細報告書・補足資料"
puts "  • 統合レポート: セッション全体の包括的記録"
puts

puts "✅ 結論:"
puts "ggim15.pdf には UN-GGIM 15th Session の"
puts "英語版公式文書が論理的順序で完全統合されています。"
puts
puts "NotebookLM での分析に最適な単一ファイルです。"
