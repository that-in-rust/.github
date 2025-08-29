---
inclusion: manual
contextKey: "#LargeFileAnalysis"
description: "Standard Operating Procedure for analyzing large research files and creating strategic summaries using Minto Pyramid Principle"
---

# Large File Analysis & Summary Creation SOP

## Overview
This steering document defines the standard operating procedure for analyzing large research files (1000+ lines) and creating comprehensive strategic summaries using the Minto Pyramid Principle.

## Task-Specific Standard Operating Procedure

### **1. Initial Assessment**
- **File Size Check**: Use `wc -l` to determine total line count
- **Chunk Planning**: Calculate 500-line segments for manageable processing
- **Existing Summary Check**: Read current summary file to understand structure before updating

### **2. Iterative Processing Pattern**
```
For each 500-line chunk:
├── Read lines N to N+499 using readFile with start_line/end_line
├── Extract high-quality insights using Minto Pyramid Principle
├── Update summary using strReplace (not append)
└── Update progress tracker (*Lines processed: X-Y*)
```

### **3. Minto Pyramid Principle Application**
- **Most Important First**: Lead with strategic, high-impact insights
- **Evidence-Based**: Support insights with concrete market data (stars, downloads, adoption)
- **Actionable**: Focus on implementable strategies, not abstract concepts
- **Categorized**: Organize into logical domains (Technical, Strategic, Market, Community)

### **4. Summary Structure Template**
```markdown
## Strategic Framework for [Domain] Success
| Category | Key Insight | Implementation Strategy | Priority |

## Domain-Specific Opportunities  
| Domain | Opportunity | [Technology] Advantage | Market Evidence |

## Technical Implementation Priorities
| Technical Area | Specific Focus | Implementation Notes |

## Success Metrics & Validation
| Metric Type | Key Indicators | Target Benchmarks |
```

### **5. Data Extraction Criteria**

**INCLUDE:**
- Concrete market evidence (GitHub stars, download counts, user metrics)
- Specific technology opportunities where target language has clear advantages
- Actionable implementation strategies
- Community building insights
- Performance/security/safety differentiators

**EXCLUDE:**
- Generic advice not specific to target technology
- Abstract concepts without implementation paths
- Duplicate insights already captured
- Low-impact or niche observations

### **6. Update Strategy**
- **Progressive Enhancement**: Each chunk adds new insights without duplicating
- **Exact String Replacement**: Use `strReplace` with precise old/new strings
- **Progress Tracking**: Update line count at bottom: `*Lines processed: 1-X*`
- **Maintain Structure**: Keep existing table formats and organization

### **7. Quality Control Checkpoints**
- **Relevance Filter**: Only include insights directly applicable to target domain
- **Evidence Requirement**: Each opportunity must have supporting market data
- **Priority Assignment**: HIGH/MEDIUM/LOW based on market size and technology advantages
- **Implementation Focus**: Emphasize concrete next steps over theoretical benefits

### **8. Completion Criteria**
- **Full File Coverage**: Process all lines from 1 to total line count
- **Comprehensive Summary**: Cover all major domains and opportunities identified
- **Final Status**: Update to `*Complete analysis: X lines processed*`
- **Strategic Recommendations**: Include prioritized action items

### **9. Error Handling**
- **File Truncation**: If content truncated, continue with available data
- **Processing Failures**: Explain issue and try alternative approach
- **Duplicate Content**: Skip redundant insights, focus on new value

### **10. Deliverable Standards**
- **Executive Summary**: Most important insights prioritized first
- **Market-Validated**: Every recommendation backed by concrete evidence  
- **Immediately Actionable**: Clear next steps for implementation
- **Quantified Success Metrics**: Specific benchmarks for validation

## Usage Instructions

To apply this SOP to a large file analysis task:

1. **Invoke Context**: Use `#LargeFileAnalysis` in your request
2. **Specify Target**: Provide the file path and target domain/technology
3. **Define Output**: Specify the desired summary file location
4. **Set Parameters**: Mention any specific focus areas or constraints

## Example Invocation

```
#LargeFileAnalysis Please analyze research-data.md (3000+ lines) and create 
a strategic summary for Python open source opportunities in summary-output.md
```

This ensures systematic, comprehensive analysis that transforms raw research into actionable strategic intelligence for technology development decisions.