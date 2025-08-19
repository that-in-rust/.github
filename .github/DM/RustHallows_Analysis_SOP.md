# Standard Operating Procedure: Large File Analysis

## Purpose
This SOP outlines the systematic process for analyzing large text files in 1000-line chunks, extracting key concepts, and building a comprehensive summary document.

## Scope
This procedure applies to the analysis of RustHallowsPrep20250815.txt (68,159 lines) and similar large files.

## Procedure

### 1. Preparation
1.1. Verify the total line count of the target file
```bash
wc -l journal202508/RustHallowsPrep20250815.txt
```

1.2. Create or update the summary document with appropriate header and structure
```bash
touch .github/DM/RustHallowsPrep20250815_summary.md
```

1.3. Create a tracking system for chunks analyzed (using todo_write tool)

### 2. Chunk Analysis (Repeat for each 1000-line chunk)
2.1. Extract the chunk to a temporary file for analysis
```bash
sed -n '[START],[END]p' journal202508/RustHallowsPrep20250815.txt > chunk[N].txt
```

2.2. Examine headings to understand structure
```bash
sed -n '[START],[END]p' journal202508/RustHallowsPrep20250815.txt | grep -E "^#|^##|^###" | head -n 10
```

2.3. Identify links and references
```bash
sed -n '[START],[END]p' journal202508/RustHallowsPrep20250815.txt | grep -E "http|www\." | head -n 10
```

2.4. Read sample content to understand themes
```bash
head -n 50 chunk[N].txt
```

### 3. Summary Creation
3.1. Create a structured section for the chunk in the summary document:
```
### Lines [START]-[END]: [Main Theme]

#### Key Ideas:
- **[Concept 1]**: [Brief explanation]
- **[Concept 2]**: [Brief explanation]
...

#### Implementation Details:
- [Detail 1]
- [Detail 2]
...

#### Key Links:
- [Link Description](URL)
...
```

3.2. Update the tracking system to mark the chunk as completed

### 4. Progress Monitoring
4.1. Regularly check the summary document line count
```bash
wc -l .github/DM/RustHallowsPrep20250815_summary.md
```

4.2. Update the conclusion section with newly discovered themes or concepts

### 5. Final Review
5.1. Ensure all chunks are analyzed or document why analysis was stopped
5.2. Review the entire summary document for consistency and completeness
5.3. Update the conclusion section with the final count of lines analyzed

## Quality Control
- Each chunk must be analyzed for headings, links, and content
- Summary sections must follow the consistent format
- Key concepts must be highlighted with proper markdown formatting
- Links must be properly formatted as markdown links
