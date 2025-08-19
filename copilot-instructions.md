# Copilot Instructions for .github Repository

## Overview
This repository consolidates research and documentation related to Rust-based systems, architectures, and frameworks. The primary focus is on extracting insights, organizing research, and maintaining structured documentation.

## Big Picture Architecture
- **Major Components:**
  - `journal202504`, `journal202506`, `journal202508`: Contain research documents in various formats (e.g., `.md`, `.txt`, `.json`).
  - `journalSummary2025`: Consolidated summaries and insights derived from research documents.
  - `kiro`: Specifications and SOPs for research consolidation tools and workflows.
- **Data Flow:**
  - Research documents are processed to extract ideas and URLs.
  - Insights are consolidated into markdown tables in `journalSummary2025`.
- **Why:**
  - To create a centralized knowledge base for Rust-related research, enabling efficient access to insights and references.

## Critical Developer Workflows
- **Research Consolidation:**
  1. Process research files in chunks (e.g., 100 lines at a time).
  2. Extract ideas and URLs using tools like `grep` and `awk`.
  3. Append insights to markdown tables in `journalSummary2025`.
- **Commands:**
  - Count files: `find /path/to/research -type f | wc -l`
  - Extract URLs: `grep -oE 'https?://[^[:space:]]+' file.txt | sort | uniq`
  - Process text chunks: `head -100 file.txt > chunk.txt`

## Running Multiple Terminal Commands
- To process large datasets or perform multiple tasks efficiently, run terminal commands in parallel.
- Example:
  ```bash
  awk 'NR>60 && NR<=80' file.txt &
  tail -20 file.txt &
  wc -l file.txt &
  grep -oE 'https?://[^[:space:]]+' file.txt | wc -l &
  wait
  ```
- Use `&` to run commands in the background and `wait` to ensure all commands complete before proceeding.

## Project-Specific Conventions
- **No Source Attribution:**
  - Insights in markdown tables should not reference specific sources.
- **Table Structure:**
  - Ideas & Insights Table: `| Category | Concept/Idea | Technical Details | Performance/Business Impact | Implementation Notes |`
  - Relevant URLs Table: `| URL | Context | Related Ideas |`
- **File Naming:**
  - Use descriptive names with timestamps (e.g., `RustResearch_Consolidated_20250819.md`).

## Integration Points
- **External Dependencies:**
  - Research documents may reference external repositories or tools (e.g., GitHub links).
- **Cross-Component Communication:**
  - Insights from `journal202504`, `journal202506`, and `journal202508` feed into `journalSummary2025`.

## Key Files/Directories
- `journalSummary2025/RustResearch_Consolidated_20250819.md`: Main consolidated markdown file.
- `kiro/specs/research-consolidation-tool/`: Specifications for research consolidation workflows.
- `journal202504`, `journal202506`, `journal202508`: Source research documents.

## Examples
- **Extracting URLs:**
  ```bash
  grep -oE 'https?://[^[:space:]]+' file.txt | sort | uniq > urls.txt
  ```
- **Appending Insights:**
  Add rows to the "Ideas & Insights Table" in `RustResearch_Consolidated_20250819.md`:
  ```markdown
  | Tools & Utilities | File-splitting utility for large files | Includes a shell script (`split_large_file.sh`) and Rust implementation (`lib.rs`, `main.rs`) | Facilitates handling of large datasets by splitting them into manageable chunks | Combines scripting and Rust for flexibility and performance |
  ```

## Terminal Commands for Research Consolidation

### File Discovery
- Count total files:
  ```bash
  find /path/to/research -type f | wc -l
  ```
- Count specific file types:
  ```bash
  find /path/to/research -name "*.md" -type f | wc -l
  find /path/to/research -name "*.txt" -type f | wc -l
  find /path/to/research -name "*.json" -type f | wc -l
  find /path/to/research -name "*.pdf" -type f | wc -l
  find /path/to/research -name "*.doc*" -type f | wc -l
  ```

### File Processing
- Process files in 100-line chunks:
  ```bash
  head -100 filename
  head -200 filename | tail -100
  head -300 filename | tail -100
  ```
- Convert documents for processing:
  ```bash
  pandoc document.pdf -t plain --wrap=none | head -100
  pandoc document.docx -t plain --wrap=none | head -100
  ```

### URL Extraction
- Extract all unique URLs:
  ```bash
  grep -oE 'https?://[^[:space:]]+' filename | sort | uniq
  ```

### Progress Tracking
- Count table entries:
  ```bash
  grep "^|" journalSummary2025/RustResearch_Consolidated_*.md | wc -l
  ```
- Check remaining work:
  ```bash
  find /path/to/research -name "*.txt" | wc -l
  find /path/to/research -name "*.json" | wc -l
  find /path/to/research -name "*.pdf" | wc -l
  find /path/to/research -name "*.doc*" | wc -l
  ```

### Running Commands in Parallel
- Example:
  ```bash
  awk 'NR>60 && NR<=80' file.txt &
  tail -20 file.txt &
  wc -l file.txt &
  grep -oE 'https?://[^[:space:]]+' file.txt | wc -l &
  wait
  ```

### Quality Assurance
- Validate table formatting:
  ```bash
  cat journalSummary2025/RustResearch_Consolidated_*.md | grep "^|" | wc -l
  ```
- Check for semantic duplicates:
  ```bash
  sort -u filename > deduplicated_filename
  ```

### Pattern-Based Commands for Automation

To ensure seamless execution of commands without asking, include the following patterns:

- **Process All Files:**
  ```bash
  head * > output.txt
  tail * > output_tail.txt
  awk '{print $1}' * > first_column.txt
  ```

- **Recursive Operations:**
  ```bash
  find /path/to/research -type f -exec head -100 {} \; > all_heads.txt
  find /path/to/research -type f -exec tail -100 {} \; > all_tails.txt
  ```

- **Wildcard Matching:**
  ```bash
  grep -oE 'https?://[^[:space:]]+' * | sort | uniq > all_urls.txt
  ```

- **Parallel Execution:**
  ```bash
  for file in *; do head -100 "$file" & done; wait
  ```

### Automating Actions to Reduce Manual Approvals

To streamline workflows and reduce the need for manual approvals, consider the following approaches:

1. **Run Commands Autonomously:**
   - Use scripts to batch commands and execute them without prompts.
   - Example:
     ```bash
     for file in /path/to/research/*; do
         head -100 "$file" > "${file}_chunk1.txt" &
         tail -100 "$file" > "${file}_chunk_tail.txt" &
     done
     wait
     ```

2. **Adjust Terminal Settings:**
   - Configure your terminal or shell to suppress confirmation prompts for specific commands.
   - Example:
     ```bash
     alias rm='rm -f'  # Suppress confirmation for file deletions
     ```

3. **Use Automation Tools:**
   - Leverage tools like `cron`, `make`, or CI/CD pipelines to automate repetitive tasks.
   - Example `Makefile`:
     ```make
     process:
     	find /path/to/research -type f -exec head -100 {} \; > all_heads.txt
     ```

4. **Predefine Patterns in Scripts:**
   - Include common patterns like `head *`, `tail *`, and recursive operations in scripts.
   - Example:
     ```bash
     grep -oE 'https?://[^[:space:]]+' * | sort | uniq > all_urls.txt
     ```

5. **Document Automation in Copilot Instructions:**
   - Ensure all automation steps are documented in this file for future reference and consistency.
