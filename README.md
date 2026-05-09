# DSM — the language layer

DSM (Domain Substrate Model) is a small declarative language for
describing a typed domain model: concepts, clubs, structures,
enumerations, attachments, and the function pools that act on them.

This repo is the **language-level contract**. It contains:

- **`grammar/DSM.g4`** — the ANTLR4 grammar that defines the surface
  syntax of `.dsm` source files. 107 lines, self-contained.
- **`spec/dsm-json.md`** — the canonical JSON wire format for a
  `DSMDefinitions` (the parsed, validated model that downstream tools
  consume). Producer-neutral specification.

Together, `.g4` + `.dsm-json` describe DSM end to end: how to parse a
`.dsm` source, and what the parsed model looks like once serialized
for tools that don't want to depend on a particular parser
implementation.

## Documentation

Full documentation: https://docs.digitalsubstrate.io/dsm/

Part of the [DevKit ecosystem](https://docs.digitalsubstrate.io/).

## Why this repo exists

Until now, the DSM language was defined implicitly by the encoder/
decoder source of the canonical runtime. That made the language
portable in principle but legible only by reading runtime code.
Publishing the grammar and the JSON wire format as standalone,
MIT-licensed artefacts:

- separates **the language** from any specific runtime that emits or
  consumes it;
- lets third-party tools (editors, validators, code generators,
  alternative runtimes) implement against a stable, public contract;
- joins the existing open-DSM family of repos (`dsm-jetbrains`,
  `dsm-vscode`, `dsm-samples`, `kibo`).

## Producers, consumers, and editors

A **producer** emits a JSON document conforming to
`spec/dsm-json.md`. It typically parses `.dsm` source against
`grammar/DSM.g4` and serializes the resulting model.

A **consumer** reads a JSON document and does something with it —
code generation, validation, visualization, …
[kibo](https://github.com/digital-substrate/kibo) is one such
consumer: a StringTemplate-driven code generator that implements
this spec in Java.

An **editor** is both at once: it reads DSM, mutates it
interactively, and writes it back. Web tooling for editing DSM
models has historically been a real consumer of this format, and the
JSON shape is intentionally round-trip stable so this stays viable.

Any of the three roles can be reimplemented in any language under
any license against this spec alone. The spec — not any particular
implementation — is the authority.

## Versioning

The schema is versioned alongside its reference producer. A breaking
change to either the grammar or the JSON format requires a major-
version bump on the producer, with the change documented in its
release notes. This repo tracks those changes in `CHANGELOG.md` (when
applicable) and tags releases at the same cadence.

## License

MIT — see [LICENSE](LICENSE).
