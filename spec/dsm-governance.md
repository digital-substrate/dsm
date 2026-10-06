# DSM Definitions — Governance

The grammar (`grammar/DSM.g4`) says how a `.dsm` source is written; the JSON wire format
(`spec/dsm-json.md`) says how a parsed model is serialised. Neither says which models are
valid. This document does: the rules a set of definitions obeys, whatever produced it — a
`.dsm` source, a JSON document, or an API that builds definitions directly.

The rules are the DSM's own. **None of them depends on a programming language.** A name a
target language reserves — `class`, `def`, `function` — is a name like any other here; a
code generator that spells it for a target handles it there, where the conflict exists.

- The keywords **MUST**, **SHOULD**, and **MAY** are used per RFC 2119.
- Each rule names the test of the reference implementation, viper, that holds it
  (`python-tests/unit/` in `digital-substrate/viper`; the Node suite mirrors it).

## 1. The text form is a faithful projection

A set of definitions written as DSM text and read back **MUST** be the same set of
definitions. The text form is canonical: comments and the order of the source do not
survive, the definitions do — every name, type, default, documentation and identity.

Held by `test_definitions_dsm_governance_proof` (`TestOracleWitnesses`, and every
`TestConstruction*Soundness`: what can be built is either refused or survives the round
trip), and `test_dsm_builder.TestDSMBuilderDocumentationRoundTrip`.

## 2. An identifier is ASCII

An identifier — of a namespace, a type, a field, an enumeration case, an attachment, a
pool, a function or a parameter — **MUST** match `[A-Za-z][A-Za-z0-9_]*`: an ASCII letter,
then ASCII letters, digits and underscores. A leading underscore, a digit first, any other
character, and the empty name are refused.

Held by `test_definitions_dsm_governance_proof.TestConstructionNameSoundness`.

## 3. An identifier is not a word of the DSM

An identifier **MUST NOT** be a keyword of the DSM: `attachment_function_pool`, `club`,
`concept`, `enum`, `false`, `function_pool`, `membership`, `mutable`, `namespace`, `struct`,
`true`.

The name of a type — a concept, a club, an enumeration, a structure — **MUST NOT** be the
name of a type the DSM already has: `void`, `bool`, `uint8`, `uint16`, `uint32`, `uint64`,
`int8`, `int16`, `int32`, `int64`, `float`, `double`, `string`, `uuid`, `blob`, `blob_id`,
`commit_id`, `any`, `any_concept`. Written unqualified, a reference to such a type would be
read as the built-in one, breaking rule 1. A field, a namespace, a pool, a function, a
parameter, an enumeration case or an attachment **MAY** bear such a name.

Held by `test_dsm_semantic_errors.TestSemanticCheckerNames` and
`test_definitions.TestDefinitionsNames`.

## 4. Names are unique where they meet

- The concepts, clubs, enumerations and structures of a namespace share one space: two of
  them **MUST NOT** have the same name.
- A namespace's name and its UUID go together: a namespace **MAY** be declared again with
  the same name and UUID, and **MUST NOT** with the same name and another UUID, nor the same
  UUID and another name.
- The fields of a structure, the cases of an enumeration, the functions of a pool and the
  parameters of a function **MUST** have distinct names; two pools **MUST NOT** share a name.
- Attachments have a space of their own: an attachment **MAY** bear a type's name.

Held by `test_dsm_semantic_errors.TestSemanticCheckerAlreadyDefined`,
`TestSemanticCheckerNames.test_a_namespace_reopened_under_another_uuid_names_both`, and
`test_definitions_dsm_governance_proof.TestConstructionShapeSoundness`.

## 5. An attachment is its key type and its name

Within a namespace, the pair (key type, name) of an attachment **MUST** be unique: two
attachments of one name over one key type, whatever their document types, are one too many.

Held by `test_dsm_semantic_errors.TestSemanticCheckerAlreadyDefined`
(`test_checker_attachment_already_defined_*`).

Two namespaces **MAY** today each declare an attachment of the same name over the same key
type. Whether the pair must be unique across namespaces is open for the next major version.

## 6. A documentation is UTF-8 text

A documentation **MUST** be valid UTF-8 and **MUST NOT** contain `"""`, the delimiter of a
docstring. It **MAY** contain any other character, quotes and backslashes included, and
**MAY** begin or end with a quote: in DSM text the quotes after the closing `"""` end the
documentation (`"""say "hi""""` is `say "hi"`).

Held by `test_definitions_dsm_governance_proof.TestConstructionDocumentationSoundness` and
`test_dsm_builder.TestDSMBuilderParse.test_parse_docstring_with_literal_double_quotes`.

## What is not governed here

- **A name a programming language reserves.** It is the code generator's to spell, rename
  or refuse for its target; the definitions are valid in every language or in none.
- The conventions of case — PascalCase types, lowerCamel fields — are conventions, not
  rules: any identifier obeying rules 2 and 3 is valid.
