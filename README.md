# UN-GGIM 15th Session Document Collection & Analysis

This repository automates the collection and analysis of documents from the UN-GGIM 15th Session.

> **📁 Ready-to-Use Files**: This repository includes the complete unified PDF (`ggim15.pdf`) and AI-generated summary audio (`ggim15.m4a`) for immediate analysis. See [Copyright & Usage](#copyright--usage) for important licensing information.

## Quick Start

### Option 1: Use Pre-generated Files (Recommended)
```bash
# Download and analyze the unified PDF (7.4MB, 272 pages)
# Contains all 34 English documents from UN-GGIM 15th Session
open ggim15.pdf

# Listen to AI-generated summary (NotebookLM audio)
open ggim15.m4a
```

### Option 2: Generate Files from Scratch
1. **Scrape document URLs**: `make scrape`
2. **Validate and fetch all PDFs**: `make fetch`  
3. **Create unified PDF**: `make unified`
4. **Generate analysis reports**: `make analyze`

## Project Structure

```
ggim15/
├── scripts/           # Ruby automation scripts
│   ├── scrape_ggim15.rb      # Basic document scraper
│   ├── enhanced_scraper.rb   # Comprehensive collection
│   ├── analyze.rb            # Analysis and reporting
│   ├── create_unified_pdf.rb # PDF merging utility
│   └── analyze_unified_pdf.rb # Unified PDF analysis
├── data/             # URLs and metadata
├── docs/raw/         # Downloaded PDF documents (34 files, .gitignore'd)
├── out/              # Analysis outputs (.gitignore'd)
├── ggim15.pdf        # 📁 Unified PDF file (all 34 documents, 7.4MB)
├── ggim15.m4a        # 🎧 AI-generated summary audio (NotebookLM)
├── COPYRIGHT.md      # ⚖️ Licensing and usage information
└── Makefile          # Workflow automation
```

## Workflow Commands

Run `make help` to see all available targets:

- `make scrape` - Extract document URLs from official site
- `make validate` - Check URL accessibility
- `make fetch` - Download all PDF documents (parallel with curl)
- `make unified` - Create unified ggim15.pdf from all PDFs
- `make analyze` - Generate analysis and inventory
- `make clean` - Clean up temporary files

## Document Collection Status

**34 PDF documents** successfully collected from:
https://ggim.un.org/meetings/GGIM-committee/15th-Session/documents/

### Collection Breakdown:
- **English Summary Documents**: 15 files (Agenda 4-18)
- **Report/Add Documents**: 16 files (detailed reports)
- **Session Documents**: 3 files (comprehensive reports, informal papers)

### Unified PDF Output:
📄 **`ggim15.pdf`** (7.4MB, 272 pages)
- Complete collection of all 34 documents in logical order
- **Ready for NotebookLM upload and analysis**

## Analysis Options

### 1. Ready-to-Use Files
📄 **ggim15.pdf** (7.4MB, 272 pages)
- Complete unified document with all 34 English PDFs
- Ready for NotebookLM upload or direct reading
- Logical order: Session reports → Agenda 4-18 summaries → Detailed reports

🎧 **ggim15.m4a** (AI-generated summary, 45MB)
- NotebookLM audio summary of the complete session
- Approximately 20-30 minutes of key insights
- Great for overview before diving into detailed documents

### 2. NotebookLM Analysis
```bash
# Upload either or both files to NotebookLM:
# 1. ggim15.pdf - for text-based analysis
# 2. Use ggim15.m4a as reference for key themes
```

### 3. Command Line Analysis
```bash
make analyze
cat out/notebooklm.txt  # Structured analysis guide
```

## Analysis Outputs

- `ggim15.pdf` - 📁 **Unified PDF ready for analysis** (7.4MB, 272 pages)
- `ggim15.m4a` - 🎧 **AI-generated audio summary** (NotebookLM output)
- `out/summary.txt` - Document collection summary
- `out/inventory.json` - Structured document inventory
- `out/notebooklm.txt` - Formatted guide for NotebookLM analysis

## Copyright & Usage

⚖️ **Important**: This repository contains UN official documents and AI-generated content. Please review [COPYRIGHT.md](COPYRIGHT.md) for:
- UN document licensing and attribution requirements
- AI-generated content usage guidelines  
- Academic and research use recommendations
- Commercial use restrictions

**Summary**: Documents are UN public records suitable for research/education. AI audio is supplementary - always refer to original documents for authoritative information.

## Requirements

- Ruby 3.0+ (standard library only)
- pdfunite (from poppler-utils) for PDF merging
- curl for downloading (or optional aria2c for faster downloads)
- make for workflow automation


# ggim15: UN-GGIM 15th Session Meeting Documents workflow (with Copilot/GenAI)

UN-GGIM 15 の Meeting Documents を収集し、Google NotebookLM で分析するための最小構成リポジトリです。作業は Makefile ベースで自動化し、URL リスト (data/urls.txt) は Generative AI（例: GitHub Copilot, ChatGPT, Claude など）で生成することを想定しています。

参考イシュー:
- UNopenGIS/7 #751: “UN-GGIM 15 の Meeting Documents を Google NotebookLM で分析してみる”

対象ドキュメント:
- UN-GGIM 15th Session meeting documents
- Agenda item #3 〜 #17 の “Summary (English)” と “Report” を主対象
- 必要に応じて Background Documents も

ベース URL:
- https://ggim.un.org/meetings/GGIM-committee/15th-Session/documents/

注意:
- 当該サイトの利用規約・著作権・robots 等を尊重してください。
- ダウンロードファイルは本リポジトリには含めず、ローカルに保存（.gitignore 済み）します。

---

## 使い方（クイックスタート）

前提:
- macOS / Linux（Windows は WSL 推奨）
- make, curl が使えること
- あると便利: aria2c（高速・再開対応）

1) 初期化
- ディレクトリ作成など
  - 実行: make init

2) URL リストの生成（GenAI）
- prompts/urls.prompt.md のプロンプトを、Copilot/他の LLM に投げて、data/urls.txt を生成
  - 実行: make prompt
    - プロンプトの場所や手順を表示します
  - LLM から得た結果テキストを data/urls.txt として保存
  - フォーマット: 1 行 1 URL、空行やコメント行（先頭 #）は可

3) URL 検証
- 200〜399 の HTTP ステータスのみを有効として抽出
  - 実行: make validate
  - 出力: data/urls.valid.txt

4) ダウンロード
- 有効 URL を docs/raw/ に保存
  - 実行: make fetch

5) NotebookLM で分析
- NotebookLM を開き、docs/raw/ のファイル群をアップロード
- セクションごとの質問・要約・比較などを行い、知見を out/ 以下にメモとして残すことを推奨

---

## リポジトリ構成

- Makefile: 主タスク定義
- prompts/urls.prompt.md: URL 抽出用の LLM プロンプト雛形
- data/
  - urls.txt: GenAI で作る「一次 URL リスト」（手動で保存）
  - urls.valid.txt: 自動検証後の「有効 URL リスト」（自動生成）
- docs/
  - raw/: ダウンロードした原本（.gitignore 済み）
- out/: NotebookLM での分析ノートや派生成果物（.gitignore 済み）
- .gitignore: 大きいファイルや生成物を除外

---

## Make タスク一覧

- make help
  - タスクの一覧を表示
- make init
  - data/, docs/raw/, out/ を作成
- make prompt
  - prompts/urls.prompt.md の使い方と期待フォーマットを表示
- make validate
  - data/urls.txt を検証し data/urls.valid.txt を生成
- make fetch
  - data/urls.valid.txt の URL を docs/raw/ にダウンロード
- make clean
  - data/urls.valid.txt と docs/raw/ を削除（ダウンロードの作り直し用）

---

## urls.txt の書式

- 1 行 1 URL（http/https）
- 空行 OK
- # から始まる行はコメントとして無視

例:
```
# Agenda 3 Summary
https://example.org/agenda3_summary_en.pdf

# Agenda 3 Report
https://example.org/agenda3_report.pdf
```

---

## Copilot/GenAI の使い方ヒント

- まず make prompt を実行し、prompts/urls.prompt.md の指示を LLM に渡します
- LLM が返した一覧を、そのまま data/urls.txt に保存
- 不足・重複・誤リンクがある場合は、LLM に「不足分の追加」「重複の削除」「Summary/Report のみ抽出」などを指示して再生成
- うまく抽出できない場合は、対象ページの HTML を貼り付けたり、サイト内の構造（セクション見出し、リンクラベル）を具体的に指示すると精度が上がります

---

## NotebookLM での進め方（例）

1) ドキュメント投入
- docs/raw/ の PDF/HTML を NotebookLM にドラッグ＆ドロップ
- タイトルに「UN-GGIM 15」と明記しておくと整理しやすい

2) 質問テンプレ（例）
- 各 Agenda item（#3〜#17）の Summary と Report の要点を 5 行で
- Summary と Report の相違点と補完関係を箇条書きで
- 重要な用語・定義・アクター（機関名）を抽出
- 横断的論点（共通する課題、データ標準、実装状況、地域差）を比較

3) 成果の整理
- NotebookLM の回答を out/notes.md 等に転記
- 引用元（ファイル名・ページ）を併記し、再現可能性を確保

---

## ライセンスと注意

- ダウンロードした一次資料の著作権は原権利者に帰属します
- 公開リポジトリに PDF 等の原本は含めません（.gitignore 済み）
- 本リポジトリのスクリプト/設定は MIT ライセンスを想定

---

## See also

- https://ggim.un.org/meetings/GGIM-committee/15th-Session/documents/
- https://github.com/UNopenGIS/7/issues/751
