# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

DSM is a language-level contract — an ANTLR4 grammar plus two JSON wire
formats. Changes to the grammar, or to a wire format, that affect what
producers emit or what consumers must accept are tracked here.

## [Unreleased]

_No changes yet. Bug fixes for the next 1.2.x patch release will be listed here._

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
