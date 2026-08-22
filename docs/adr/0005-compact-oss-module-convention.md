# ADR-0005: Compact OSS module convention

Status: Accepted, subject to re-validation against current ABP 10.6 template behavior.

## Decision

BPT uses a compact Contracts + implementation convention where required to avoid classic layered project proliferation. Host is composition root; business implementations reference only other modules' Contracts.

## Revisit trigger

Revisit if the current ABP 10.6 Standard Module path provides the same compact structure in the exact toolchain used by this repository, or empirical maintenance evidence favors another layout.
