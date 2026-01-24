# Contributing to ChainVote

Thank you for your interest in contributing to ChainVote! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct (see CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Node version, etc.)
   - Screenshots if applicable

### Suggesting Enhancements

1. Check if the enhancement has been suggested
2. Create a new issue with:
   - Clear description of the enhancement
   - Use cases and benefits
   - Possible implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write or update tests as needed
5. Ensure all tests pass (`pnpm test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to your branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Pull Request Guidelines

- Follow the existing code style
- Write clear commit messages
- Update documentation as needed
- Add tests for new features
- Ensure CI passes
- Keep PRs focused on a single concern

## Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/chainvote.git
cd chainvote

# Install dependencies
pnpm install

# Run development server
pnpm dev

# Run tests
pnpm test

# Run linter
pnpm lint
```

## Project Structure

```
chainvote/
├── apps/web/           # Next.js frontend
├── contracts/          # Smart contracts
│   ├── base/          # Solidity contracts
│   └── stacks/        # Clarity contracts
├── packages/          # Shared packages
│   ├── shared/        # UI components & types
│   ├── base-adapter/  # Base wallet integration
│   └── stacks-adapter/# Stacks wallet integration
└── tests/             # E2E tests
```

## Coding Standards

### TypeScript/JavaScript

- Use TypeScript for all new code
- Follow ESLint configuration
- Use meaningful variable names
- Add JSDoc comments for public APIs
- Prefer functional components and hooks

### Solidity

- Follow Solidity style guide
- Use latest stable version
- Add NatSpec comments
- Write comprehensive tests
- Consider gas optimization

### Clarity

- Follow Clarity best practices
- Use descriptive function names
- Add inline comments
- Write unit tests
- Handle errors explicitly

## Testing

- Write unit tests for new features
- Update existing tests when modifying code
- Ensure E2E tests pass
- Test on both Base and Stacks networks

## Documentation

- Update README.md for user-facing changes
- Add inline code comments for complex logic
- Update API documentation
- Include examples where helpful

## Commit Messages

Follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Example: `feat: add proposal voting deadline extension`

## Review Process

1. Maintainers will review your PR
2. Address any requested changes
3. Once approved, a maintainer will merge

## Questions?

Feel free to open an issue for questions or join our community discussions.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
