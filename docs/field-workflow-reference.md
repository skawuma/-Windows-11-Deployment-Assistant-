# Field workflow reference

> **Approval status:** Requirements transcribed here remain subject to Qnity
> endpoint, security, privacy, legal, and change-management confirmation.

This file is a structured transcription of the photographed Qnity/illuminet migration form supplied on July 25, 2026. It preserves the operational meaning for later requirements work; it is not an approved digital replacement for the paper form.

## Migration identification

- Name
- Original serial number
- New serial number, if replacement
- Migration type:
  - Replace
  - Rebuild with USB
  - Windows Reset

## User backup and Cloud PC attestation

The form asks the user to confirm backup status, where appropriate:

| Item | Responses visible on form |
|---|---|
| OneDrive data | Yes / No |
| Chrome bookmarks | Yes / No / Do not use Chrome |
| OneNote notebooks | Yes / No / Do not use OneNote |
| Edge favourites | Yes / No |
| PST files | “Do not have any PST files” |
| Miscellaneous files or folders outside OneDrive | Yes / No / Do not have an additional folder to back up |
| Set up and accessed Cloud PC | Yes / No / My apps are missing in Cloud PC |

The form then captures:

- user signature
- date

## Technician checklist

- OneDrive working on Qnity laptop
- Office installed
- Company Portal installed
- Outlook configured with Qnity mailbox
- OneDrive configured on Cloud PC to only show Qnity
- User shown how to launch Cloud PC
- User instructed about which services or applications only work in Cloud PC
- User shown how to use Company Portal
- Ricoh driver installed
- Teams set up with both accounts
- Names of every technician who worked on the device
- Notes

## Requirements that need clarification

Before these items become application rules or database fields, Qnity should confirm:

1. Whether “Replace,” “Rebuild with USB,” and “Windows Reset” are the exact controlled migration-type names.
2. Whether each backup response permits `Not applicable`, especially Edge favourites and PST files.
3. Whether a `No` response always blocks migration and who may approve an exception.
4. What evidence proves OneDrive data, bookmarks, OneNote notebooks, favourites, PST files, and miscellaneous folders are safely backed up.
5. Whether the Cloud PC check belongs before destructive work, after provisioning, or both.
6. Which applications must exist in Cloud PC and how “My apps are missing” is resolved.
7. The intended meaning of “OneDrive configured on Cloud PC to only show Qnity.”
8. Which two Teams account contexts are required and whether simultaneous sign-in is supported by policy.
9. Which Ricoh driver, printer queue, location mapping, and test page constitute a pass.
10. What signature mechanism, retention period, and correction workflow are approved.

## Digital-design implications

- Preserve each attestation separately; do not combine backup readiness into one Boolean.
- Store `Not checked`, `Yes/pass`, `No/fail`, `Not applicable`, and `Exception` distinctly.
- Keep technical evidence separate from user and technician attestations.
- Treat serial numbers, names, signatures, and notes as protected operational data.
- Record every lifecycle transition, technician, and timestamp for auditability.
- Never collect passwords, MFA codes, recovery keys, or access tokens in this workflow.
- Never infer wipe/reset/rebuild authorization from application or synchronization detection alone.
