# Frad's .claude

A comprehensive development environment with specialized AI agents for code review, security analysis, and technical leadership.

## Quick Sync

Sync your local Claude configuration with this repository:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

## Overview

This project provides a structured approach to software development with AI-powered code review agents and established development principles. It combines SOLID architecture principles with specialized review agents to ensure high-quality, maintainable code.

## Development Principles

### Architecture Guidelines

- **SOLID Principles**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Design Patterns**: Prefer composition over inheritance, use dependency injection, apply repository pattern, implement strategy pattern
- **Code Organization**: Keep files and functions concise, maintain meaningful comments explaining "why" not "what"

### Code Quality Standards

- **Naming**: Use descriptive variable/function names, avoid abbreviations and magic numbers
- **Error Handling**: Gracefully handle all error cases with meaningful messages
- **Performance**: Avoid premature optimization, focus on algorithm complexity, use caching appropriately

### Development Practices

- **Testing**: Write tests for core functionality
- **Documentation**: Update documentation when modifying code
- **Security**: Always consider security, avoid hardcoded sensitive information
- **Package Management**: Prefer pnpm for Node.js projects
- **Git Commits**: Keep commit titles under 70 characters, use lowercase

## Specialized Review Agents

### Code Reviewer
Comprehensive code analysis for correctness, best practices, and maintainability.

**Use when**: You've completed a logical chunk of code and need thorough review before committing.

**Focus areas**:
- Correctness and logic analysis
- Best practices and standards adherence
- Readability and maintainability
- Performance and efficiency
- Testing and quality assurance
- Security considerations

### Code Simplifier
Refactoring specialist for improving readability and reducing complexity.

**Use when**: You have functional code that needs refactoring to improve readability or eliminate redundancy.

**Focus areas**:
- Identify and eliminate redundancy (DRY principle)
- Enhance readability through simplification
- Modernize syntax and idioms
- Improve code structure and organization

### Security Reviewer
Cybersecurity expert for vulnerability assessment and secure coding practices.

**Use when**: Reviewing code that handles sensitive data, authentication, or external inputs.

**Focus areas**:
- Common vulnerabilities (SQL injection, XSS, CSRF)
- Authentication and authorization
- Input validation and data handling
- Cryptography and data protection
- Error handling and information disclosure
- Dependency and configuration security

### Tech Lead Reviewer
Senior technical leadership perspective for architectural decisions and complex challenges.

**Use when**: You need guidance on significant feature implementations, system-wide changes, or complex technical problems.

**Focus areas**:
- Architectural excellence and scalability
- Technical leadership and mentorship
- Strategic alignment with project goals
- Holistic quality oversight

### UX Reviewer
User experience specialist for interface evaluation and usability assessment.

**Use when**: You need to evaluate user interfaces for usability, accessibility, and overall user experience.

**Focus areas**:
- Comprehensive usability evaluation
- Clarity and consistency assessment
- Accessibility compliance (WCAG guidelines)
- Feedback and error prevention
- User flow efficiency analysis

## Project Structure

```
.claude/
├── agents/
│   ├── code-reviewer.md
│   ├── code-simplifier.md
│   ├── security-reviewer.md
│   ├── tech-lead-reviewer.md
│   └── ux-reviewer.md
└── CLAUDE.md
```

## Usage Guidelines

1. **Agent Selection**: Choose the appropriate agent based on your current development phase
2. **Code Review**: Use code-reviewer for comprehensive analysis before committing
3. **Refactoring**: Use code-simplifier when code needs simplification or modernization
4. **Security**: Use security-reviewer for any code handling sensitive data or user input
5. **Architecture**: Use tech-lead-reviewer for significant architectural decisions
6. **UX**: Use ux-reviewer for interface evaluation before user testing

## Best Practices

- Follow SOLID principles in all code implementations
- Maintain consistent naming conventions
- Write self-documenting code with meaningful comments
- Prioritize code quality over quantity
- Consider security implications in all implementations
- Test thoroughly and maintain good test coverage
- Keep documentation updated with code changes

## Contributing

When contributing to this project:
- Follow the established development principles
- Use appropriate review agents for code quality
- Maintain consistency with existing patterns
- Update documentation as needed

## License

This project is for personal development use by Frad. 
