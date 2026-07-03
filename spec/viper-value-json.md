# Viper Values — JSON Wire Format

This document specifies the **JSON wire format** for a Viper `Value` —
the runtime representation of data in the Viper type/value system. It is
the on-the-wire / on-disk encoding that producers emit and consumers
read, and the basis for the compact BSON variant.

> **What this is not.** This is **not** a [JSON
> Schema](https://json-schema.org/) document — it is a prose
> specification of the structure of conforming JSON documents. It is
> also **not** the encoding of a *type model*: that is the job of the
> companion document [`dsm-json.md`](dsm-json.md), which specifies how a
> `DSMDefinitions` is serialized. This document describes how a *value*
> of a known type is serialized.

The two documents are complementary. `dsm-json.md` defines the **types**
(concepts, structures, enumerations, …); this document defines how an
**instance** of one of those types is encoded. Decoding a value requires
the type model to already be loaded — see [Type
dependency](#type-dependency).

This document is the contract, and it is self-contained. A conformant
document is one that this spec accepts; a conformant decoder is one that
this spec describes. A producer or consumer can be implemented against
this spec alone, in any language under any license. The viper runtime
implements both sides of this format, but its source is not part of the
published contract — the spec, not any particular implementation, is the
authority.


## Conformance

- The keywords **MUST**, **SHOULD**, and **MAY** are used per RFC 2119.
- All strings are UTF-8.
- Field order in a JSON object is not significant. Producers **SHOULD**
  emit object keys in a stable order, but consumers **MUST NOT** depend
  on order.
- A value document does **not** have a fixed root JSON kind. The root
  may be any JSON value (`null`, boolean, number, string, array, or
  object) — it is whatever the value's type dictates. This is unlike a
  `DSMDefinitions` document, whose root is always an object.


## The central principle: encoding is type-driven

A value JSON document is **not self-describing**. With two exceptions
([`any`](#any) and [`variant`](#variant)), the JSON carries no type tag;
the same JSON text decodes to different values depending on the type
supplied at decode time. For example the JSON `5` decodes to an
`int32`, a `uint8`, or an `int64` according to the type the decoder is
given; the JSON `[1, 2, 3]` decodes to a `vec`, a `vector`, a `set`, or
a `tuple`.

Consequently a decoder **MUST** be given:

1. the **root `Type`** the document was produced for, and
2. a **definitions registry** able to resolve every named type
   (concept, club, enumeration, structure, primitive) referenced inside
   the document or its embedded types.

See [Type dependency](#type-dependency). An encoder, by contrast, needs
only the value: the value carries its own type at runtime.


## Operations

| Operation   | Inputs                              | Result / source                              |
| ----------- | ----------------------------------- | -------------------------------------------- |
| JSON encode | any value                           | JSON text (optionally indented).             |
| JSON decode | JSON text + root type + definitions | a value.                                     |
| BSON encode | a structure value                   | a BSON document. Root MUST be a structure.   |
| BSON decode | BSON document + structure type + definitions | a value.                            |

Encoding needs only the value (it carries its own type at runtime).
Decoding needs the **root type** and a **definitions** registry — see
[Type dependency](#type-dependency).

The BSON form encodes the *same* logical model through a binary
container ([BSON](#bson-encoding)). Its root is restricted to a
structure because a BSON document root MUST be an object.


## Value encoding

Each Viper type code maps to one JSON shape. The encoder dispatches on
the value's runtime type code; the decoder dispatches on the type code
of the supplied type.

| Type code     | JSON shape                                                              |
| ------------- | ----------------------------------------------------------------------- |
| `void`        | `null`                                                                  |
| `bool`        | JSON boolean                                                            |
| `uint8/16/32/64` | JSON number (unsigned)                                               |
| `int8/16/32/64`  | JSON number (signed integer)                                        |
| `float`       | JSON number                                                             |
| `double`      | JSON number                                                             |
| `string`      | JSON string                                                             |
| `blob`        | JSON string (Base64)                                                    |
| `uuid`        | JSON string (RFC 4122)                                                  |
| `blob_id`     | JSON string (40 hex chars)                                              |
| `commit_id`   | JSON string (40 hex chars)                                              |
| `vec`         | JSON array, flat, exactly `size` elements                               |
| `mat`         | JSON array, flat, exactly `columns × rows` elements                     |
| `tuple`       | JSON array, positional, heterogeneous                                   |
| `optional`    | the wrapped value, or `null` when empty                                 |
| `vector`      | JSON array                                                              |
| `set`         | JSON array                                                              |
| `map`         | JSON array of `[key, value]` pairs                                      |
| `xarray`      | JSON array of exactly 3 elements                                        |
| `enumeration` | JSON string `".case"`                                                   |
| `structure`   | JSON object keyed by field name                                         |
| `key`         | JSON array of exactly 2 elements                                        |
| `any`         | `null`, or object `{ "type", "value" }`                                 |
| `variant`     | object `{ "type", "value" }`                                            |

### Primitives

**Booleans** encode as JSON booleans.

**Integers** encode as JSON numbers. On decode:

- unsigned types accept any JSON integer (signed or unsigned) and are
  then **range-checked** against the target width;
- signed types require a JSON integer and are range-checked.

A value outside the target width is rejected.

**`float` and `double`** encode as JSON numbers carrying a fraction or
exponent (a whole value is written `5.0`, not `5`). On decode the JSON
node must be a JSON number: a bare integer literal such as `5` is
**accepted** and read as `5.0` (JSON has a single number type, so `5`
and `5.0` denote the same value). A non-number is rejected. `float` is
additionally range-checked to single precision.

**`string`** encodes verbatim as a JSON string.

**`blob`** encodes as a Base64 JSON string and decodes by Base64
decoding.

**`uuid`** encodes as an RFC 4122 string, lowercase, hyphenated
(36 characters).

**`blob_id` and `commit_id`** encode as a lowercase hexadecimal string
of 40 characters (a 20-byte identifier). Decoders reject a string of the
wrong length or with non-hex digits.

**`void`** encodes as `null`.

### Vec and Mat

Both encode as a **flat** JSON array of their element values, in the
container's linear element order:

- `vec` carries exactly `size` elements;
- `mat` carries exactly `columns × rows` elements.

Decoders reject an array of the wrong length. Element values are encoded
recursively per the element type.

```json
[ 1.0, 2.0, 3.0 ]
```

### Tuple

A positional, heterogeneous JSON array. The element count and each
element's type are fixed by the tuple type; decoders reject an array of
the wrong length.

```json
[ 42, "label", true ]
```

### Optional

An optional encodes **inline**: a present value is encoded as that value
directly; an empty optional encodes as `null`.

```json
"present"      // some
null           // none
```

Because `null` also encodes `void` and an empty `optional`, and because
an `optional` may wrap a nullable type, `null` is disambiguated **only**
by the supplied type. This is consistent with the type-driven principle.

### Vector and Set

Both encode as a JSON array of element values. A `set` carries no
duplicate elements; uniqueness is re-established on decode by inserting
into the set.

```json
[ 1, 2, 3 ]
```

### Map

A map encodes as a JSON array of two-element `[key, value]` arrays — not
as a JSON object — because Viper map keys may be of any type, not only
strings.

```json
[
  [ "alpha", 1 ],
  [ "beta",  2 ]
]
```

Each entry **MUST** be an array of exactly two elements. The first is
decoded against the key type, the second against the element type.

### XArray

An `xarray` encodes its internal memento as a JSON array of **exactly
three** elements:

```json
[
  [ "<uuid>", "<uuid>", ... ],          // 1. ordered live positions
  [ "<uuid>", ... ],                    // 2. deleted positions
  { "<uuid>": <element>, ... }          // 3. position -> element value
]
```

| Index | Meaning                                                                 |
| ----- | ----------------------------------------------------------------------- |
| 0     | Ordered list of live position UUIDs (defines element order).            |
| 1     | Set of deleted position UUIDs (tombstones).                             |
| 2     | Object mapping each live position UUID to its encoded element value.    |

Position UUIDs are RFC 4122 strings. Element values are encoded
recursively per the element type.

### Enumeration

An enumeration value encodes as a JSON string in the canonical form
`".case"` — a leading dot followed by the case identifier:

```json
".Red"
```

On decode the string is split on `.` and **MUST** yield exactly two
segments; the second segment is the case name and **MUST** name a case
of the target enumeration. A string that does not split into exactly two
dot-separated segments is rejected as a malformed enumeration case.

### Structure

A structure encodes as a JSON object whose keys are field names and
whose values are the encoded field values:

```json
{
  "x": 1.0,
  "y": 2.0,
  "name": "origin"
}
```

Decoding is **lenient by design**, supporting schema evolution:

- a declared field **absent** from the JSON object keeps its type
  default — its absence is not an error;
- a JSON key that does **not** correspond to a declared field is
  **ignored**.

This differs from the strict, no-unknown-keys rule of a
`DSMDefinitions` document. See [Versioning](#versioning).

### Key

A `key` encodes as a JSON array of **exactly two** elements:

```json
[ "<instance-uuid>", "<concept-runtime-id>" ]
```

| Index | Meaning                                                              |
| ----- | ------------------------------------------------------------------- |
| 0     | The keyed instance's UUID.                                          |
| 1     | The runtime id of the target concept.                              |

The concept runtime id is resolved against the definitions registry; a
runtime id that is present but **not** in the registry is rejected. An
**invalid** (all-zero) concept runtime id denotes an unassigned **null
key**, which is admissible for any element type.

Otherwise the resolved concept **MUST** conform to the key's element
type:

- **concept** — the concept must be the element concept, or a descendant
  of it;
- **club** — the concept must be a member of the club, or a descendant of
  a member;
- **`any_concept`** — any concept known to the registry is accepted.

### Any

`any` is one of the two **self-describing** shapes: it embeds the type
of its content so a decoder can reconstruct the value without external
type information for that node.

- An empty `any` encodes as `null`.
- Otherwise it encodes as an object with the content's embedded type and
  encoded value:

```json
{
  "type":  { "class_name": "primitive", "runtime_id": "...", "name": "int32" },
  "value": 42
}
```

See [Embedded type encoding](#embedded-type-encoding) for the `type`
field.

### Variant

`variant` also embeds its content type, in the same `{ "type", "value" }`
shape as `any`:

```json
{
  "type":  { "class_name": "structure", "runtime_id": "...", "name": "..." },
  "value": { ... }
}
```

On decode the embedded type **MUST** be a member of the variant's
declared type set, otherwise the document is rejected. Unlike `any`, a
`variant` value is never `null`.


## Embedded type encoding

The `type` field inside an [`any`](#any) or [`variant`](#variant) is a
serialized `Type`. This is a **distinct and more compact** encoding than
the type encoding in [`dsm-json.md`](dsm-json.md):

- it identifies named and primitive types by **`runtime_id`**, resolved
  against a definitions registry, rather than by a fully qualified
  namespace identity plus `domain`;
- it carries no `domain` discriminator and no `reference` wrapper; the
  `class_name` directly names the type family.

A `Type` is a JSON object carrying `class_name` plus shape-specific
fields. Decoders **MUST** reject a `class_name` not in this table.

| `class_name`  | Shape                                                              |
| ------------- | ------------------------------------------------------------------ |
| `primitive`   | `{ class_name, runtime_id, name }` — a primitive type.             |
| `any`         | `{ class_name, runtime_id, name }` — the `any` type.               |
| `any_concept` | `{ class_name, runtime_id, name }` — the `any_concept` type.       |
| `concept`     | `{ class_name, runtime_id, name }` — a named concept.              |
| `club`        | `{ class_name, runtime_id, name }` — a named club.                 |
| `enumeration` | `{ class_name, runtime_id, name }` — a named enumeration.          |
| `structure`   | `{ class_name, runtime_id, name }` — a named structure.            |
| `vec`         | `{ class_name, element_type, size }`                               |
| `mat`         | `{ class_name, element_type, columns, rows }`                      |
| `tuple`       | `{ class_name, types }`                                            |
| `optional`    | `{ class_name, element_type }`                                     |
| `vector`      | `{ class_name, element_type }`                                     |
| `set`         | `{ class_name, element_type }`                                     |
| `map`         | `{ class_name, key_type, element_type }`                           |
| `xarray`      | `{ class_name, element_type }`                                     |
| `variant`     | `{ class_name, types }`                                            |
| `key`         | `{ class_name, element_type }`                                     |

Notes:

- `element_type`, `key_type`, and members of `types` are **full**
  embedded types (recursively encoded), not bare references.
- For `primitive`, `concept`, `club`, `enumeration`, and `structure`,
  the type is resolved by `runtime_id` against the definitions
  registry. The `name` field is informational (for readability and
  diagnostics) and is **not** used to resolve the type.
- For `any` and `any_concept`, decoders dispatch on `class_name` alone
  and return the singleton type; `runtime_id` and `name` are present for
  symmetry and are not consulted.
- `runtime_id` is an RFC 4122 UUID string.


## Type dependency

Decoding requires a definitions registry — the loaded type model
(see [`dsm-json.md`](dsm-json.md)). The registry resolves, by
`runtime_id`:

| Embedded `class_name` | Resolved against              |
| --------------------- | ----------------------------- |
| `primitive`           | the primitive registry        |
| `concept`             | the concept registry          |
| `club`                | the club registry             |
| `enumeration`         | the enumeration registry      |
| `structure`           | the structure registry        |

A `key` value resolves its target concept the same way. A `runtime_id`
absent from the registry is a decode error. This is why decoding — in
either the JSON or the BSON form — requires a definitions registry: the
wire format references types by identity, and the identities must
already be known.


## BSON encoding

The BSON form serializes the **same logical model** through the BSON
binary container. Only the physical representation differs; every rule
in this document about shapes, type-driven decoding, and the definitions
dependency applies unchanged.

The BSON root **MUST** be an object, so the BSON form is restricted to a
**structure** value (and decoded against a structure type). It is
intended for compact binary persistence, where a JSON object root is
guaranteed.


## Validation

A conformant decoder distinguishes the following error categories.
Decoders **SHOULD** locate the failing node in the error message; the
exact context string format is implementation-defined and not part of
the wire contract.

| Code                         | When it fires                                                       |
| ---------------------------- | ------------------------------------------------------------------- |
| `expected_type`              | A node has the wrong JSON kind for the expected type or shape.      |
| `expected_member`            | A required object key is absent.                                    |
| `expected_member_type`       | A required key is present but has the wrong JSON kind.              |
| `malformed_enumeration_case` | An enumeration string does not split into exactly two `.` segments. |
| `not_a_club_member_descendant` | A `key`'s concept is neither a member of the target club nor a descendant of a member. |
| `not_a_member_of_variant`    | An embedded type is not a member of the variant's type set.         |
| `not_a_concept_descendant`   | A `key`'s concept is neither the element concept nor a descendant of it. |

Decoders additionally surface:

- **range errors** when an integer or `float` value exceeds the target
  width;
- **parse errors** for malformed `uuid`, `blob_id`, `commit_id`, or
  Base64 `blob` strings.

The structure leniency described in [Structure](#structure) is the one
deliberate exception to strict rejection: unknown keys are ignored and
missing declared fields fall back to their default.


## Versioning

The wire format is **paired with the viper release** that defines it.
There is no separate schema version number. A breaking change to the
format requires a major-version bump on viper, documented in the release
notes.

Forward compatibility for **structures** is handled by the leniency rule
([Structure](#structure)): a producer may add fields that older
consumers ignore, and a newer consumer reading older data falls back to
field defaults. Outside structures, the format relies on the type model
(definitions) being in lockstep with the data, since decoding is
type-driven.


## Minimal example

A structure value, with a nested optional and an embedded `any`:

```json
{
  "id":   "6b3d1c2e-0000-4000-8000-000000000001",
  "label": "origin",
  "note":  null,
  "extra": {
    "type":  { "class_name": "primitive", "runtime_id": "...", "name": "int32" },
    "value": 7
  }
}
```

Decoding this requires the structure's `Type` and a definitions
registry that resolves the `int32` primitive and the structure itself.


## Appendix A — Lexicon (canonical key names)

All keys are case-sensitive, ASCII, snake_case.

### Object keys

`class_name`, `runtime_id`, `name`, `type`, `value`, `element_type`,
`key_type`, `types`, `size`, `columns`, `rows`.

### Discriminator values for `class_name` (embedded Type)

`primitive`, `any`, `any_concept`, `concept`, `club`, `enumeration`,
`structure`, `vec`, `mat`, `tuple`, `optional`, `vector`, `set`, `map`,
`xarray`, `variant`, `key`.

### Encodings of note

| Domain                 | Encoding                                                  |
| ---------------------- | --------------------------------------------------------- |
| `void`, empty optional | `null`                                                    |
| `blob`                 | Base64 string                                             |
| `uuid`                 | RFC 4122 string (36 chars, lowercase, hyphenated)         |
| `blob_id`, `commit_id` | 40-char lowercase hex string (20 bytes)                   |
| `enumeration`          | `".case"` string                                          |
| `map`                  | array of `[key, value]` pairs                             |
| `xarray`               | 3-element array `[positions, deleted, elements]`          |
| `key`                  | 2-element array `[instance_uuid, concept_runtime_id]`     |
| `any`, `variant`       | `{ "type": <Type>, "value": <Value> }`                    |


## See also

- [`dsm-json.md`](dsm-json.md) — the JSON wire format for the **type
  model** (`DSMDefinitions`). Together with this document it defines the
  Viper data plane end to end: how types are described, and how values
  of those types are serialized.
