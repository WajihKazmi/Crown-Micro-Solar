# Energy Diagram Documentation

## 📚 Documentation Index

This folder contains comprehensive documentation for the Energy Diagram video system in the Crown Micro Solar app.

### 📖 Available Documents

| Document | Description | Best For |
|----------|-------------|----------|
| **[Implementation Summary](ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md)** | Overview of the entire implementation | Project managers, new developers |
| **[Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md)** | Detailed explanation of all 6 cases | Understanding the logic, troubleshooting |
| **[Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md)** | Cheat sheet and quick lookup | Daily development, quick answers |
| **[Testing Checklist](ENERGY_DIAGRAM_TESTING_CHECKLIST.md)** | Step-by-step testing procedures | QA testers, validation |

---

## 🚀 Quick Start Guide

### I want to understand the system
👉 Start with: **[Implementation Summary](ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md)**

### I need to know when each video plays
👉 Check: **[Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md)** - Case table at top

### I'm debugging an issue
👉 Use: **[Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md)** - Troubleshooting section

### I need to test the implementation
👉 Follow: **[Testing Checklist](ENERGY_DIAGRAM_TESTING_CHECKLIST.md)**

### I need to modify the code
1. Read **[Implementation Summary](ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md)** - Technical Details
2. Review **[Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md)** - Case Priority and Logic
3. Edit `lib/view/home/device_detail_screen.dart`
4. Test with **[Testing Checklist](ENERGY_DIAGRAM_TESTING_CHECKLIST.md)**

---

## 📋 Document Summaries

### 1. ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md
**Length:** Comprehensive (5-10 min read)

**Contains:**
- ✅ What was implemented
- ✅ All 6 video cases explained
- ✅ Technical details and data flow
- ✅ Code changes made
- ✅ Legacy code references
- ✅ Testing strategy
- ✅ Maintenance guidelines

**Use when:** You need a complete overview of the system

---

### 2. ENERGY_DIAGRAM_VIDEO_CASES.md
**Length:** Detailed (15-20 min read)

**Contains:**
- ✅ Detailed explanation of each case
- ✅ Real-world meanings and scenarios
- ✅ Status value interpretation guide
- ✅ Power thresholds explained
- ✅ Case priority and logic flow
- ✅ Technical implementation details
- ✅ Testing scenarios for each case
- ✅ Troubleshooting guide
- ✅ Future improvements suggestions

**Use when:** You need deep understanding or are debugging

---

### 3. ENERGY_DIAGRAM_QUICK_REF.md
**Length:** Quick (2-3 min scan)

**Contains:**
- ✅ 6-case summary table
- ✅ Status value cheat sheet
- ✅ Power threshold reference
- ✅ Case selection priority
- ✅ Real-world scenario examples
- ✅ Common issues and solutions
- ✅ Code locations
- ✅ Testing tips

**Use when:** You need quick answers or a refresher

---

### 4. ENERGY_DIAGRAM_TESTING_CHECKLIST.md
**Length:** Comprehensive (workflow document)

**Contains:**
- ✅ Pre-testing setup checklist
- ✅ Test procedures for each of 6 cases
- ✅ Edge case testing scenarios
- ✅ Real-world progression tests
- ✅ Data validation checks
- ✅ Regression testing guide
- ✅ Test summary template
- ✅ Debugging tips

**Use when:** Testing or validating the implementation

---

## 🎯 Common Tasks

### Task: Understand Case 6 (Grid Export)
1. **Quick Answer:** [Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md) - Table row 6
2. **Detailed Info:** [Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md) - Case 6 section
3. **How to Test:** [Testing Checklist](ENERGY_DIAGRAM_TESTING_CHECKLIST.md) - Case 6 test

### Task: Debug Wrong Video Showing
1. **Check conditions:** [Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md) - Troubleshooting
2. **Review logic:** [Implementation Summary](ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md) - Decision Logic
3. **Verify thresholds:** [Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md) - Power Thresholds

### Task: Add a New Case
1. **Review existing:** [Implementation Summary](ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md) - Video Cases
2. **Plan priority:** [Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md) - Case Priority
3. **Update code:** `lib/view/home/device_detail_screen.dart`
4. **Update docs:** All 4 documentation files
5. **Test thoroughly:** [Testing Checklist](ENERGY_DIAGRAM_TESTING_CHECKLIST.md)

### Task: Adjust Thresholds
1. **See current values:** [Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md) - Power Thresholds
2. **Understand impact:** [Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md) - Power Thresholds section
3. **Edit code:** `_selectVideoAsset()` in `device_detail_screen.dart`
4. **Retest all cases:** [Testing Checklist](ENERGY_DIAGRAM_TESTING_CHECKLIST.md)

---

## 💡 Key Concepts

### The 6 Video Cases (Quick Summary)
1. **Case 1:** Grid + Solar + Battery → Home (all sources)
2. **Case 2:** Everything dead/offline (standby)
3. **Case 3:** Grid + Battery → Home (no solar)
4. **Case 4:** Battery only → Home (island mode)
5. **Case 5:** Solar + Battery → Home (no grid)
6. **Case 6:** Solar → Battery + Grid export + Home (selling)

### Status Value Meanings
- **Positive (> 0):** Energy flowing OUT
- **Negative (< 0):** Energy flowing IN
- **Zero (= 0):** Inactive

### Power Thresholds
- Solar: 50W | Battery: 20W | Grid: 50W | Load: 20W

---

## 🔍 Search Guide

### Looking for...

**"Why is Case X playing?"**
→ [Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md) - Case X section

**"How do I test Case Y?"**
→ [Testing Checklist](ENERGY_DIAGRAM_TESTING_CHECKLIST.md) - Case Y test procedure

**"What does status value -1 mean?"**
→ [Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md) - Status Value Quick Reference

**"Where is the code?"**
→ [Implementation Summary](ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md) - Code Changes

**"How do I debug?"**
→ [Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md) - Troubleshooting

**"What's the priority order?"**
→ [Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md) - Case Selection Priority

**"Real-world examples?"**
→ [Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md) - Real-World Scenarios

**"Future improvements?"**
→ [Implementation Summary](ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md) - Maintenance section

---

## 📝 Document Maintenance

When updating the energy diagram logic:

1. ✅ Update the code in `lib/view/home/device_detail_screen.dart`
2. ✅ Update [Implementation Summary](ENERGY_DIAGRAM_IMPLEMENTATION_SUMMARY.md)
3. ✅ Update [Video Cases Guide](ENERGY_DIAGRAM_VIDEO_CASES.md) if case logic changes
4. ✅ Update [Quick Reference](ENERGY_DIAGRAM_QUICK_REF.md) tables and values
5. ✅ Update [Testing Checklist](ENERGY_DIAGRAM_TESTING_CHECKLIST.md) if tests change
6. ✅ Update this README if new documents are added

---

## 🤝 Contributing

If you find issues or have suggestions:
1. Document the issue clearly
2. Reference which case(s) are affected
3. Provide test conditions that reproduce the issue
4. Update relevant documentation with fixes

---

## 📞 Support

For questions about:
- **Implementation details** → See Implementation Summary
- **How cases work** → See Video Cases Guide  
- **Quick answers** → See Quick Reference
- **Testing procedures** → See Testing Checklist

---

**Last Updated:** October 18, 2025  
**Version:** 1.0  
**Project:** Crown Micro Solar - Flutter Application
