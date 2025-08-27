SHELL := bash

BASE_URL := https://ggim.un.org/meetings/GGIM-committee/15th-Session/documents/

DATA_DIR := data
DOCS_DIR := docs/raw
OUT_DIR  := out

URLS_FILE := $(DATA_DIR)/urls.txt
VALID_URLS_FILE := $(DATA_DIR)/urls.valid.txt

.PHONY: help init prompt validate fetch clean

help: ## Show help
	@echo "Targets:"
	@awk 'BEGIN {FS":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Create directories (data, docs/raw, out)
	@mkdir -p $(DATA_DIR) $(DOCS_DIR) $(OUT_DIR)
	@echo "Initialized: $(DATA_DIR) $(DOCS_DIR) $(OUT_DIR)"

prompt: ## Show how to generate data/urls.txt with GenAI and required format
	@echo "1) Open the prompt template:"
	@echo "   - prompts/urls.prompt.md"
	@echo "2) Paste that prompt into your LLM (e.g., GitHub Copilot Chat, ChatGPT, Claude) and get the URL list."
	@echo "3) Save the result as: $(URLS_FILE)"
	@echo ""
	@echo "Format of $(URLS_FILE):"
	@echo "  - One URL per line"
	@echo "  - Empty lines OK"
	@echo "  - Lines starting with '#' are comments and ignored"
	@echo ""
	@echo "Base URL for reference:"
	@echo "  $(BASE_URL)"

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
	@echo "Cleaned: $(DOCS_DIR) and $(VALID_URLS_FILE)"
