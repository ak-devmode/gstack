---
name: review
description: "WellMed code review — security, code quality, performance, testing, and SATU SEHAT compliance checks."
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Code Review

Perform a thorough code review on the specified files or current git diff.

## Arguments
- `$ARGUMENTS` - File paths or "staged" for git staged changes, "branch" for current branch diff

## Review Checklist

### Security
- [ ] No hardcoded secrets or credentials
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection on state-changing endpoints
- [ ] Proper authentication/authorization checks
- [ ] Sensitive data not logged

### Code Quality
- [ ] Follows project naming conventions
- [ ] No code duplication (DRY)
- [ ] Functions are single-purpose (SRP)
- [ ] Error handling is comprehensive
- [ ] No unused imports or variables
- [ ] TypeScript strict mode compliance

### Performance
- [ ] N+1 query prevention
- [ ] Appropriate database indexes considered
- [ ] Large dataset pagination
- [ ] Caching opportunities identified

### Testing
- [ ] Unit tests for new functions
- [ ] Edge cases covered
- [ ] Mocks used appropriately

### SATU SEHAT Specific
- [ ] FHIR resources properly structured
- [ ] NIK validation present
- [ ] Error codes mapped correctly
- [ ] Bundle size within limits

## Output Format

Provide feedback in this structure:

### Critical Issues
Issues that must be fixed before merge.

### Suggestions
Improvements that should be considered.

### Positive Notes
Good practices observed.

### Summary
Overall assessment and approval recommendation.
