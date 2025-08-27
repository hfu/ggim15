SHELL := bash

BASE_URL := https://ggim.un.org/meetings/GGIM-committee/15th-Session/documents/

DATA_DIR := data
DOCS_DIR := docs/raw
OUT_DIR  := out

URLS_FILE := $(DATA_DIR)/urls.txt
VALID_URLS_FILE := $(DATA_DIR)/urls.valid.txt

.PHONY: help init scrape validate fetch analyze clean

help: ## Show all available targets and their descriptions
	@echo "UN-GGIM 15th Session Documents Workflow"
	@echo "======================================="
	@echo "Targets:"
	@awk 'BEGIN {FS":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Create directories (data, docs/raw, out)
	@mkdir -p $(DATA_DIR) $(DOCS_DIR) $(OUT_DIR)
	@echo "Initialized: $(DATA_DIR) $(DOCS_DIR) $(OUT_DIR)"

prompt: ## Show how to use the automated scraper (preferred) or manual URL generation
	@echo "RECOMMENDED: Use automated scraping:"
	@echo "  make scrape"
	@echo ""
	@echo "Alternative: Manual LLM workflow:"
	@echo "1) Use prompts/urls.prompt.md with your LLM"
	@echo "2) Save LLM output as: $(URLS_FILE)"
	@echo "3) Run: make validate"

scrape: ## Generate $(URLS_FILE) by scraping the official documents page (Ruby)
	@echo "Scraping $(BASE_URL) ..."
	@ruby scripts/scrape_ggim15.rb $(URLS_FILE)
	@echo "OK: wrote $(URLS_FILE)"

analyze: ## Analyze downloaded documents and prepare NotebookLM guide
	@ruby scripts/analyze.rb --format summary
	@echo ""
	@ruby scripts/analyze.rb --format inventory
	@ruby scripts/analyze.rb --format notebooklm
	@echo "Analysis complete. See out/ directory for guides."

ingest: ## [DEPRECATED] Use 'make scrape' instead for automated URL collection
	@echo "This target is deprecated. Use 'make scrape' for automated collection."
	@echo "For manual workflow, use 'make prompt' for instructions."

validate: $(URLS_FILE) ## Validate URLs (HTTP 2xx/3xx) and save to data/urls.valid.txt
	@test -f $(URLS_FILE) || (echo "Error: $(URLS_FILE) not found. Run 'make prompt' and create it with your LLM." && exit 1)
	@echo "Validating URLs in $(URLS_FILE) ..."
	@awk 'BEGIN {ok=0} {g=$$0; gsub(/^ +| +$$/,"",g); if (g=="" || g ~ /^#/) next; print g}' $(URLS_FILE) \
	| while read -r u; do \
	    code=$$(curl -sIL "$$u" -o /dev/null -w "%{http_code}"); \
	    if [[ "$$code" =~ ^(2|3)[0-9][0-9]$$ ]]; then \
	      echo "$$u"; \
	    else \
	      echo "WARN: $$code $$u" >&2; \
	    fi; \
	  done > $(VALID_URLS_FILE).tmp
	@mv $(VALID_URLS_FILE).tmp $(VALID_URLS_FILE)
	@echo "OK: Wrote $(VALID_URLS_FILE)"

fetch: $(VALID_URLS_FILE) ## Download documents into docs/raw/ (uses aria2c if available, otherwise curl)
	@test -f $(VALID_URLS_FILE) || (echo "Error: $(VALID_URLS_FILE) not found. Run 'make validate' first." && exit 1)
	@echo "Downloading into $(DOCS_DIR) ..."
	@if command -v aria2c >/dev/null 2>&1; then \
	  echo "Using aria2c ..."; \
	  aria2c -i $(VALID_URLS_FILE) -d $(DOCS_DIR) -c --auto-file-renaming=true --allow-overwrite=false; \
	else \
	  echo "aria2c not found. Falling back to curl (parallel x4) ..."; \
	  cat $(VALID_URLS_FILE) \
	    | xargs -P4 -n1 -I{} bash -c 'cd "$(DOCS_DIR)" && curl -L -O -J "{}"'; \
	fi
	@echo "Done."

clean: ## Remove downloaded docs and validated URL list
	@rm -rf $(DOCS_DIR)/*
	@rm -f $(VALID_URLS_FILE)
	@rm -f ggim15.pdf
	@echo "Cleaned: $(DOCS_DIR) and $(VALID_URLS_FILE)"

analyze: ## Analyze downloaded documents and prepare NotebookLM guide
	@ruby scripts/analyze.rb --format summary
	@echo ""
	@ruby scripts/analyze.rb --format inventory
	@ruby scripts/analyze.rb --format notebooklm
	@echo "Analysis complete. See out/ directory for guides."

unified: ggim15.pdf ## Create unified ggim15.pdf from all PDFs

ggim15.pdf: $(DOCS_DIR)/*.pdf
	ruby scripts/create_unified_pdf.rb
