# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

DSM is a language-level contract — an ANTLR4 grammar plus two JSON wire
formats. Changes to the grammar, or to a wire format, that affect what
producers emit or what consumers must accept are tracked here.

## [Unreleased]

### Added
- `spec/dsm-governance.md` — which definitions are valid: the text form is a faithful
  projection, identifiers are ASCII and not words of the DSM, a type is not named like a
  built-in type, names are unique where they meet, documentation is UTF-8 without `"""`.
  No rule depends on a programming language: a name a target language reserves is the code
  generator's to handle.
- `spec/dsm-governance.md` lists its known limitations: a float default kept at fixed
  decimals, a negative zero in a default, a non-finite value inside a composite default.

### Changed
- `grammar/DSM.g4` follows the reference implementation's docstring: raw text, so a `"` or a
  `\` needs no escape, and the quotes after the closing `"""` end the text — a
  documentation may end with a quote (`"""say "hi""""`). The grammar this repository
  published still escaped docstrings like string literals.

## [1.2.0] - 2026-06-17

First standalone publication of the DSM language contract as MIT-licensed,
producer-neutral artefacts, decoupled from any specific runtime that emits
or consumes them.

### Added
- `grammar/DSM.g4` — ANTLR4 grammar defining the surface syntax of `.dsm`
  source files.
- `spec/dsm-json.md` — canonical JSON wire format for a parsed, validated
  `DSMDefinitions` model.
- `spec/viper-value-json.md` — companion JSON wire format for values of
  DSM-defined types.
