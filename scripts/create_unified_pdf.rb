#!/usr/bin/env ruby
# 全PDFファイルを論理的順序で結合してggim15.pdfを作成

require 'pathname'
require 'shellwords'

# PDFファイルのディレクトリ
docs_dir = Pathname.new('docs/raw')
output_file = 'ggim15.pdf'

unless docs_dir.exist?
  puts "Error: docs/raw directory not found"
  exit 1
end

# PDFファイルを取得
pdf_files = docs_dir.glob('*.pdf').sort

if pdf_files.empty?
  puts "Error: No PDF files found in docs/raw/"
  exit 1
end

puts "Found #{pdf_files.size} PDF files"

# 論理的順序での並び替え
# 1. Session documents (Report, Summary, etc.)
# 2. Agenda items (3-17)
# 3. Background Documents
# 4. CRP papers

def categorize_and_sort(files)
  session_docs = []
  agenda_docs = []
  background_docs = []
  crp_docs = []
  other_docs = []
  
  files.each do |file|
    name = file.basename.to_s
    case name
    when /^Report-part_I_II/
      session_docs << file
    when /^Summary-part_I_II/
      session_docs << file
    when /^E_C20_2025_(\d+)_e\.pdf$/
      agenda_num = $1.to_i
      agenda_docs << [agenda_num, file]
    when /^E_C20_2025_(\d+)_Add_(\d+)_e\.pdf$/
      agenda_num = $1.to_i
      add_num = $2.to_i
      agenda_docs << [agenda_num + add_num * 0.1, file]
    when /Background/i
      background_docs << file
    when /CRP/i
      crp_docs << file
    else
      other_docs << file
    end
  end
  
  # Agenda documents をソート
  agenda_docs.sort_by! { |num, _| num }
  agenda_files = agenda_docs.map { |_, file| file }
  
  # 結合順序
  ordered_files = session_docs + agenda_files + background_docs + crp_docs + other_docs
  
  return ordered_files
end

# ファイルを論理的順序で並び替え
ordered_files = categorize_and_sort(pdf_files)

puts "\nPDF merge order:"
ordered_files.each_with_index do |file, index|
  puts "%2d. %s" % [index + 1, file.basename]
end

# pdfunite コマンドを構築
file_paths = ordered_files.map { |f| f.to_s.shellescape }.join(' ')
command = "pdfunite #{file_paths} #{output_file.shellescape}"

puts "\nExecuting pdfunite..."
puts "Output: #{output_file}"

# コマンド実行
system(command)

if $?.success?
  output_path = Pathname.new(output_file)
  if output_path.exist?
    size_mb = output_path.size / 1024.0 / 1024.0
    puts "\n✅ Success! Created #{output_file}"
    puts "   Size: %.1fMB" % size_mb
    puts "   Files merged: #{ordered_files.size}"
    puts "\n📤 Ready for NotebookLM upload:"
    puts "   #{output_path.expand_path}"
  else
    puts "❌ Error: Output file not created"
    exit 1
  end
else
  puts "❌ Error: pdfunite command failed"
  exit 1
end
