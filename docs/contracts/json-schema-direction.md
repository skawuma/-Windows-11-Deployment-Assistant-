# Initial JSON schema direction

Status: architectural direction for durable summaries and events. Sprint 2 adds
a strict Draft 2020-12 schema for local assistant configuration at
`powershell/config/assistant.config.schema.json`; no durable runtime summary or
API event schema is frozen yet.

## Schema standard and ownership

- Use JSON Schema Draft 2020-12 for checked-in schemas.
- Store future schemas under `docs/contracts/schemas/`.
- Give every schema an absolute organization-approved `$id` once the repository
  and API domain are confirmed.
- Include a required string `schemaVersion` in every durable summary or event.
- Use semantic contract versions such as `1.0.0`; breaking changes increment the
  major version.
- Freeze the local Version 1 summary in Sprint 4.
- Finalize the device-event request and response DTOs in Sprint 6.
- The Spring Boot API owns server-side validation and authoritative workflow
  state.

## Envelope direction

A future device event is expected to contain:

```json
{
  "schemaVersion": "1.0.0",
  "eventId": "uuid",
  "eventType": "DEVICE_CHECK_COMPLETED",
  "sequenceNumber": 1,
  "occurredAt": "2026-07-26T17:30:00Z",
  "migrationId": "uuid",
  "sessionId": "uuid",
  "agent": {
    "version": "semantic-version",
    "configurationVersion": "version"
  },
  "device": {
    "deviceId": "approved-identifier",
    "assetTag": "approved-identifier",
    "serialNumber": "included-only-when-approved",
    "computerName": "approved-identifier",
    "siteCode": "approved-site-code"
  },
  "results": [],
  "nextAction": {
    "code": "CONTROLLED_CODE",
    "owner": "TECHNICIAN"
  },
  "overallStatus": "ATTENTION_REQUIRED"
}
```

This example is not a frozen contract and is not accepted by any API today.

## Type separation

Do not combine these into one result array without an explicit discriminator:

- `TECHNICAL_EVIDENCE` produced by an agent;
- `USER_ATTESTATION` made by a user;
- `TECHNICIAN_VALIDATION` made by an authenticated technician; and
- `ENTERPRISE_APPROVAL` made through an approved authority.

Each human or enterprise assertion needs its own source, actor/authority
reference, occurrence time, and correction history. Technical evidence cannot
satisfy human or enterprise gates.

## Field rules

- JSON fields use camelCase.
- Controlled values use `UPPER_SNAKE_CASE`.
- Persisted and exchanged timestamps use ISO 8601 UTC with `Z`.
- IDs must be validated against their approved formats; UUIDs are preferred for
  event, session, migration, and lease identifiers.
- `eventId` and the idempotency key must agree.
- `sequenceNumber` is a positive integer and orders events within its defined
  source scope.
- Evidence is normalized and minimal. Do not embed raw command output.
- Do not include passwords, MFA codes, tokens, authorization headers, recovery
  keys, signatures, or unrestricted free text.
- Unknown future schema major versions are rejected safely.
- Validation errors use stable field paths and safe messages.

## Result direction

Version 1 device checks use normalized statuses:

```text
Pass
Fail
Skipped
Error
```

Later workflow records need richer controlled states such as:

```text
NOT_CHECKED
PASS
FAIL
NOT_APPLICABLE
BLOCKED
EXCEPTION
```

The schema must not reduce those later states to Booleans.

## Compatibility process

1. Propose the schema change with examples and migration impact.
2. Identify whether it is additive or breaking.
3. Add schema validation and producer/consumer tests.
4. Update API/agent configuration versions and documentation.
5. Preserve immutable events under the schema version that produced them.
6. Project older supported events into current state through explicit versioned
   mapping.

No schema should claim compatibility until the relevant producer and consumer
have been tested together.
