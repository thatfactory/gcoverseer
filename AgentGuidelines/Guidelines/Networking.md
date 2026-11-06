# Networking

Use this guide for networking in ThatFactory Apple-platform applications, games, and Swift packages. These are repository requirements; official Apple documentation defines API behavior and availability.

## Apple networking APIs

- Use Apple's native networking APIs. Use Foundation's `URLSession` for HTTP and HTTPS transport, including data, upload, download, and streaming tasks.
- Use the appropriate Apple framework for other networking needs, such as Network for supported lower-level protocols or `URLSessionWebSocketTask` for WebSockets. Verify support on every deployment target; do not build an HTTP transport on sockets when `URLSession` covers the requirement.
- Preserve framework-owned networking, such as CloudKit or WebKit operations. Do not replace those APIs merely to expose their internal HTTP traffic.
- Do not add a third-party networking client, transport, wrapper, or protocol stack when Apple covers the required capability. A first-party wrapper must not conceal such a dependency. Follow the [capability-gap exception](#capability-gap-exceptions) before introducing an alternative.

## Typed HTTP with native transport

For HTTP requests and responses owned by the application or package, add Apple's `swift-http-types` package through Swift Package Manager and use its `HTTPTypes` and `HTTPTypesFoundation` products with native `URLSession` transport. `HTTPTypes` supplies HTTP values; `HTTPTypesFoundation` supplies Foundation conversion and `URLSession` conveniences. Neither product replaces the transport.

Use the following types throughout the owned HTTP boundary:

| HTTP concept | Required representation |
| --- | --- |
| Request | `HTTPRequest` |
| Response | `HTTPResponse` |
| Method | `HTTPRequest.Method`, such as `.get` or `.post` |
| Header fields and names | `HTTPFields` and `HTTPField.Name` |
| Response status | `HTTPResponse.Status`, including named values or status kinds as appropriate |

Do not maintain parallel string-based method/header models or integer status enums where these types apply. Custom protocol methods, header names, and statuses still use the extensible HTTP types; header values and encoded bodies remain protocol data. Validate response status before treating a completed transfer as application success.

Declare both products in the package or Xcode dependency graph and link them to the targets that use them. A pure HTTP-model target may depend only on `HTTPTypes`; the Foundation transport target also needs `HTTPTypesFoundation`. An import, unused dependency, or dependency declaration without actual typed request and response handling does not satisfy this policy.

Use the typed `URLSession` overloads where they support the operation. When a native API requires `URLRequest` or `HTTPURLResponse`, such as a delegate, background-task, or Foundation-only request-configuration boundary, use `HTTPTypesFoundation` conversion there and retain typed HTTP in the code that owns request construction and response handling. Document the native API reason, handle failed conversions, and preserve bodies and required transport configuration. A Foundation bridge needs no third-party exception and is not permission to retain an untyped HTTP implementation throughout the service.

The [1.8.0 release](https://github.com/apple/swift-http-types/tree/1.8.0) is the minimum baseline for this policy, for example `.package(url: "https://github.com/apple/swift-http-types.git", from: "1.8.0")`. Its manifest requires Swift tools 6.1. Select a compatible released version, verify its Swift and deployment requirements, and record the version requirement and resolution according to the [package update workflow](Packages.md). Do not silently lower consumer platform support or substitute another library to resolve an incompatibility.

### Standing dependency approval

Apple's `swift-http-types` products `HTTPTypes` and `HTTPTypesFoundation` are pre-approved for the typed HTTP and Foundation integration role above. Consumers do not need a separate owner exception for that role. Record the dependency, source, target linkage, and version policy in normal package or architecture documentation. This approval does not extend to other Apple open-source packages, third-party networking libraries, or unrelated runtime roles; the general [external dependency policy](Development.md#external-dependencies) still applies.

Do not add these products to a target that has no owned HTTP behavior merely because it uses a network-backed Apple framework or a first-party service. Non-HTTP networking and framework-owned traffic follow the native-API rule without requiring artificial HTTP wrappers. These exclusions do not exempt external SDKs or a first-party service's own networking implementation from dependency and networking policy.

## Ownership and validation

Keep transport-specific details behind the service or package boundary that owns networking. Use an injectable boundary for deterministic tests. Follow [Redux service ownership](Architecture/Redux.md#services) where applicable and the shared [testing guide](Testing/UnitTesting.md) for test structure.

- Verify typed request construction, headers and body encoding, expected success and failure statuses, transport errors, and cancellation for the changed behavior. Test conversion failures when a Foundation bridge is involved.
- Use controlled responses or local fixtures for ordinary tests; do not make normal CI depend on an external service. Run a live integration check only when needed to verify behavior fixtures cannot establish, and report its limits.
- Preserve native transport security and authentication behavior. For security-sensitive changes, follow [Xcode security audits](Xcode/Security.md) and record affected network configuration and relevant runtime evidence.
- Follow [Logging](Logging.md) for privacy-safe diagnostics owned by the networking implementation; do not expose credentials, headers containing secrets, or user content.

## Capability-gap exceptions

An alternative networking dependency is eligible only when a required capability is unavailable through Apple's APIs on the supported platforms. Convenience, familiarity, popularity, and reduced code volume are not capability gaps. Check current official Apple documentation and demonstrate the missing behavior before proposing an exception; do not assume Apple covers every possible protocol or deployment constraint.

Before changing the dependency graph, obtain explicit repository-owner approval for the specific alternative and role under the [external dependency policy](Development.md#external-dependencies). Keep a durable consumer exception identifying the requirement, Apple APIs evaluated and their concrete limitation, affected platforms and targets, dependency/source, license/security/maintenance impact, version policy, validation, approval context, and condition for revisiting the exception. An undocumented or unapproved alternative prevents audit completion.

## Adoption and audit

New or changed networking must follow this guide, including directly affected existing request paths. On adoption of this networking policy, inventory existing networking and either migrate noncompliant paths within authorized scope or record an explicit owner-approved, scoped migration deferral with rationale, affected paths, and a follow-up condition. Existing code alone is not an exception; do not silently rewrite unrelated consumers or claim full compliance while a deferral remains.

Use the [networking completion audit](../.agents/skills/agent-guidelines-audit/SKILL.md#audit-networking) to record applicability, dependency and implementation evidence, native bridges, exceptions or migration deferrals, and validation results.

## Official references

- [URLSession](https://developer.apple.com/documentation/foundation/urlsession).
- [Network](https://developer.apple.com/documentation/network).
- [Swift HTTP Types and Foundation integration](https://github.com/apple/swift-http-types/tree/1.8.0).
