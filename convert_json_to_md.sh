#!/bin/bash

# Create the output file with a title
echo "# Rust 300 - Small, High-Impact Rust Libraries (300 LOC or less)" > journal202508/Rust30020250815_full.md

# Add executive summary
jq -r ".output.executive_summary" journal202508/Rust30020250815.json >> journal202508/Rust30020250815_full.md

# Add key opportunity areas
echo -e "
## Key Opportunity Areas
" >> journal202508/Rust30020250815_full.md
jq -r ".output.key_opportunity_areas | join(\"

\")" journal202508/Rust30020250815.json >> journal202508/Rust30020250815_full.md

# Process each section
for section in $(jq -r ".output | keys[]" journal202508/Rust30020250815.json | grep -v "executive_summary\|key_opportunity_areas"); do
  # Convert section name to title format
  title=$(echo $section | sed "s/_/ /g" | awk "{for(i=1;i<=NF;i++) {\$i=toupper(substr(\$i,1,1)) substr(\$i,2)}} 1")
  
  # Add section header
  echo -e "
## $title
" >> journal202508/Rust30020250815_full.md
  
  # Process each item in the section
  length=$(jq -r ".output.$section | length" journal202508/Rust30020250815.json)
  for i in $(seq 0 $(($length-1))); do
    # Add idea name as subheader
    jq -r ".output.$section[$i].idea_name | \"### \" + ." journal202508/Rust30020250815.json >> journal202508/Rust30020250815_full.md
    echo "" >> journal202508/Rust30020250815_full.md
    
    # Add description
    jq -r ".output.$section[$i].description" journal202508/Rust30020250815.json >> journal202508/Rust30020250815_full.md
    echo "" >> journal202508/Rust30020250815_full.md
    
    # Add PMF probability
    jq -r ".output.$section[$i].PMF_probability | \"**PMF Probability:** \" + (. | tostring) + \"%\"" journal202508/Rust30020250815.json >> journal202508/Rust30020250815_full.md
    echo "" >> journal202508/Rust30020250815_full.md
    
    # Add success testing notes
    jq -r ".output.$section[$i].success_testing_notes | \"**Success Testing:** \" + ." journal202508/Rust30020250815.json >> journal202508/Rust30020250815_full.md
    echo "" >> journal202508/Rust30020250815_full.md
    
    # Add references
    jq -r ".output.$section[$i].references_links | \"**References:** \" + ." journal202508/Rust30020250815.json >> journal202508/Rust30020250815_full.md
    echo "" >> journal202508/Rust30020250815_full.md
  done
done
