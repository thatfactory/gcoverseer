# Xcode Security Audits

Use this guide only for an explicitly requested security audit, hardening task, entitlement review, or a change that materially affects application security. Do not expand ordinary feature work into a repository-wide audit.

## Source of truth

- Use Xcode's current `audit-xcode-security-settings` skill and official Apple documentation for the detailed baseline.
- Prefer Xcode MCP project-aware tools for targets, build settings, entitlements, capabilities, privacy manifests, source searches, and file updates.
- Discover active tool names rather than hardcoding MCP server prefixes.

## Audit scope

Confirm the requested targets and configurations, then inspect only relevant areas:

- deployment and compiler security settings;
- code-signing and entitlements;
- application capabilities;
- privacy manifests and required-reason APIs;
- network security configuration;
- debug-only behavior and diagnostics;
- sensitive data storage and logging;
- unsafe interoperability boundaries.

## Changes

- Explain the concrete risk and affected target before changing a setting or entitlement.
- Prefer Xcode-aware entitlement and project-setting tools over textual project-file manipulation.
- Preserve required capabilities and configuration-specific differences.
- Make narrow changes that can be reviewed and reverted.
- Build the affected target after project-setting changes.
- Exercise relevant runtime behavior when a change affects signing, capabilities, networking, storage, or system integration.

## Report

Separate findings from changes. Record the target/configuration, evidence, severity, remediation, and verification for each changed item. Do not claim a comprehensive security guarantee from a settings audit alone.
