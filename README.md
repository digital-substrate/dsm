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
  `dsm-vscode`, `dsm-samples`).

## Producers and consumers

A **producer** is anything that emits a JSON document conforming to
`spec/dsm-json.md`. The reference producer is
[viper](https://digitalsubstrate.io/), which parses `.dsm` source via
this grammar and emits the JSON form directly.

A **consumer** is anything that reads a JSON document conforming to
`spec/dsm-json.md` and does something with it — typically code
generation, validation, or visualization. The reference consumer is
[kibo](https://github.com/digital-substrate/kibo), a StringTemplate-
driven code generator.

Anyone can write either side. The spec is the contract.

## Versioning

The schema is versioned alongside its reference producer. A breaking
change to either the grammar or the JSON format requires a major-
version bump on the producer, with the change documented in its
release notes. This repo tracks those changes in `CHANGELOG.md` (when
applicable) and tags releases at the same cadence.

## License

MIT — see [LICENSE](LICENSE).
