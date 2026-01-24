# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of ChainVote seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please Do Not

- Open a public GitHub issue for security vulnerabilities
- Disclose the vulnerability publicly before it has been addressed

### Please Do

1. Email security details to: [your-security-email@example.com]
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- Acknowledgment of your report within 48 hours
- Regular updates on our progress
- Credit in the security advisory (if desired)

## Security Best Practices

When using ChainVote:

1. **Smart Contracts**
   - Contracts are provided as-is
   - Conduct your own security audit before mainnet deployment
   - Use testnet for initial testing
   - Consider bug bounty programs for production deployments

2. **Wallet Security**
   - Never share your private keys
   - Use hardware wallets for significant holdings
   - Verify transaction details before signing
   - Be cautious of phishing attempts

3. **Frontend Security**
   - Verify you're on the correct domain
   - Keep your browser and extensions updated
   - Review transaction details in your wallet

## Known Limitations

- Proposals cannot be edited after creation
- Votes cannot be changed once cast
- No built-in Sybil resistance
- Simple majority voting only

## Audit Status

This project has not undergone a professional security audit. Use at your own risk.

## Bug Bounty

We currently do not have a bug bounty program. This may change in the future.

## Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine affected versions
2. Audit code to find similar problems
3. Prepare fixes for all supported versions
4. Release new versions as soon as possible
5. Publish a security advisory

Thank you for helping keep ChainVote and our users safe!
