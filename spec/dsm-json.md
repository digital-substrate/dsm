# DSM JSON Schema

This document specifies the JSON encoding of a `DSMDefinitions` — the
data model that describes a Domain Substrate Model (concepts, clubs,
enumerations, structures, attachments, function pools, and the type
system that binds them together). It is the contract between viper
(the canonical producer) and any consumer that wants to read DSM data
without going through the binary `.dsmb` format: kibo, third-party code
generators, schema validators, dashboards, etc.

This document is the contract. A conformant document is one that this
spec accepts and a conformant decoder is one that this spec describes.
Round-trip and cross-codec tests on the producer side validate that
the JSON it emits round-trips through the binary form without loss; if
this document and producer behaviour disagree, the producer wins and
this document gets fixed.

A reference consumer ships in this repo:
`src/main/java/com/digitalsubstrate/viper/dsm/DSMDefinitionsJsonDecoder.java`
— a tree-model Jackson decoder that tracks the JSON path on every
error. The key-name constants it uses are mirrored in
`DSMDefinitionsJsonLexicon.java`. Anyone implementing a decoder in
another language can use these as a working blueprint.


## Conformance

- The keywords **MUST**, **SHOULD**, and **MAY** are used per RFC 2119.
- A document is a **single JSON object** at the root.
- All keys are mandatory unless stated otherwise. Decoders **MUST**
  reject a document that is missing a required key, has a key with the
  wrong JSON type, or carries an unknown discriminator value.
- Field order in a JSON object is not significant. Producers
  **SHOULD** emit keys in alphabetical order to keep diffs stable, but
  consumers **MUST NOT** depend on order.
- All strings are UTF-8.


## Top-level structure

```json
{
  "concepts":                   [ ... ],
  "clubs":                      [ ... ],
  "enumerations":               [ ... ],
  "structures":                 [ ... ],
  "attachments":                [ ... ],
  "function_pools":             [ ... ],
  "attachment_function_pools":  [ ... ]
}
```

| Key                          | Type   | Description                                           |
| ---------------------------- | ------ | ----------------------------------------------------- |
| `concepts`                   | array  | List of concept declarations.                         |
| `clubs`                      | array  | List of club declarations and their memberships.      |
| `enumerations`               | array  | List of enumerations and their cases.                 |
| `structures`                 | array  | List of structures and their fields.                  |
| `attachments`                | array  | List of attachment declarations (key→document).       |
| `function_pools`             | array  | Free function pools.                                  |
| `attachment_function_pools`  | array  | Function pools that target an attachment.             |

Empty arrays are permitted and represent "no entries of this kind".


## Common patterns

### Identity (TypeName)

Every named definition (concept, club, enumeration, structure,
attachment) carries the same three fields that together form a fully
qualified `TypeName`:

| Field            | JSON type | Notes                                                                |
| ---------------- | --------- | -------------------------------------------------------------------- |
| `namespace_uuid` | string    | RFC 4122 UUID, lowercase hex, hyphenated.                            |
| `namespace_name` | string    | Human-readable namespace alias (e.g. `"Test"`).                      |
| `name`           | string    | The unqualified identifier within the namespace (e.g. `"Position"`). |

### Documentation

Every definition carries a `documentation` string. It MAY be empty
(`""`); it is never absent.

### Runtime identity

Every top-level *named* entity (concept, club, enumeration, structure,
attachment) carries a `runtime_id` (UUID string). Function pools use
the key `uuid` instead — see the function-pool section.

### Polymorphic objects via `class_name`

Two object families are polymorphic:

- **Types** (the type tree): see [Type system](#type-system)
- **Literals** (default values): see [Literals](#literals)

Each polymorphic object carries a `class_name` string that selects the
shape. Decoders dispatch on this discriminator. Unknown values **MUST**
yield a decode error.


## Concepts

```json
{
  "namespace_uuid":  "8fdd9ba9-b85e-4b33-a749-9b9615e43453",
  "namespace_name":  "TestComprehensive",
  "name":            "ConceptB",
  "documentation":   "A concept derived from another.",
  "parent":          { "class_name": "reference", ... },
  "runtime_id":      "529d57ac-5779-6d37-6703-9cefb0ce4591"
}
```

| Field          | Type           | Required | Notes                                                  |
| -------------- | -------------- | -------- | ------------------------------------------------------ |
| identity       | (see above)    | yes      | `namespace_uuid`, `namespace_name`, `name`.            |
| `documentation`| string         | yes      | May be empty.                                          |
| `parent`       | TypeReference  | optional | Present only when the concept extends another.         |
| `runtime_id`   | UUID string    | yes      |                                                        |

`parent` is the **only optional key** in the schema. A concept without
a parent omits the key entirely; an explicit `"parent": null` is **not
allowed**.


## Clubs

A club groups one or more concepts as members.

```json
{
  "namespace_uuid":  "...",
  "namespace_name":  "TestComprehensive",
  "name":            "Klub",
  "documentation":   "...",
  "members":         [ <TypeReference>, ... ],
  "runtime_id":      "..."
}
```

`members` is an array of TypeReferences targeting concepts.


## Enumerations

```json
{
  "namespace_uuid":  "...",
  "namespace_name":  "TestComprehensive",
  "name":            "EnumerationE",
  "documentation":   "...",
  "members":         [ <EnumerationCase>, ... ],
  "runtime_id":      "..."
}
```

Each `EnumerationCase`:

```json
{ "name": "a", "documentation": "..." }
```


## Structures

```json
{
  "namespace_uuid":  "...",
  "namespace_name":  "TestComprehensive",
  "name":            "StructureS",
  "documentation":   "...",
  "fields":          [ <StructureField>, ... ],
  "runtime_id":      "..."
}
```

Each `StructureField`:

| Field          | Type     | Notes                                          |
| -------------- | -------- | ---------------------------------------------- |
| `name`         | string   | Field identifier.                              |
| `documentation`| string   |                                                |
| `type`         | Type     | Polymorphic — see [Type system](#type-system). |
| `default_value`| Literal  | Polymorphic — see [Literals](#literals).       |

A field with no semantic default is encoded with a literal of domain
`none`; the key is **never absent**.


## Attachments

```json
{
  "namespace_uuid":  "...",
  "namespace_name":  "...",
  "name":            "...",
  "documentation":   "...",
  "key_type":        <TypeReference>,
  "document_type":   <Type>,
  "runtime_id":      "..."
}
```

`key_type` MUST be a TypeReference. `document_type` is a full
polymorphic Type (not necessarily a reference).


## Function pools

### Free function pools (`function_pools`)

```json
{
  "uuid":          "...",
  "name":          "...",
  "documentation": "...",
  "functions":     [ <Function>, ... ]
}
```

Note the pool's identifier is `uuid`, not `runtime_id`. There is no
namespace on a pool — it is identified by UUID + display name only.

Each `Function`:

```json
{
  "prototype":     <FunctionPrototype>,
  "documentation": "..."
}
```

### Attachment function pools (`attachment_function_pools`)

Same shape as a free function pool, but each function carries an
`is_mutable` boolean:

```json
{
  "uuid":          "...",
  "name":          "...",
  "documentation": "...",
  "functions":     [
    {
      "is_mutable":    true,
      "prototype":     <FunctionPrototype>,
      "documentation": "..."
    }
  ]
}
```

### FunctionPrototype

```json
{
  "name":        "...",
  "parameters":  [ <Parameter>, ... ],
  "return_type": <Type>
}
```

Each `Parameter`:

```json
{
  "name": "...",
  "type": <Type>
}
```

A void-returning function uses a Reference to the primitive `void`.


## Type system

A `Type` is a JSON object carrying `class_name` and shape-specific
fields. Decoders **MUST** reject a Type whose `class_name` is not in
the table below.

| `class_name` | Shape                                                       |
| ------------ | ----------------------------------------------------------- |
| `reference`  | A leaf reference to a primitive or named entity.            |
| `vec`        | Fixed-size vector of a referenced element type.             |
| `mat`        | Fixed-size matrix of a referenced element type.             |
| `tuple`      | Heterogeneous, ordered list of types.                       |
| `optional`   | Wraps another type (may be absent).                         |
| `vector`     | Homogeneous, dynamic-size sequence.                         |
| `set`        | Homogeneous unordered, unique collection.                   |
| `map`        | Key-type → element-type association.                        |
| `xarray`     | N-dimensional homogeneous array (numerical workloads).      |
| `variant`    | Sum type over a list of types.                              |
| `key`        | A reference targeting an attachment key type.               |

### Reference

```json
{
  "class_name":     "reference",
  "namespace_uuid": "00000000-0000-0000-0000-000000000000",
  "namespace_name": "",
  "name":           "float",
  "domain":         "primitive"
}
```

| Field        | Notes                                                                                |
| ------------ | ------------------------------------------------------------------------------------ |
| identity     | `namespace_uuid` + `namespace_name` + `name`.                                        |
| `domain`     | One of: `any`, `primitive`, `concept`, `club`, `any_concept`, `enumeration`, `structure`. |

Namespace conventions by domain:

| `domain`                                              | Namespace fields                                                                |
| ----------------------------------------------------- | ------------------------------------------------------------------------------- |
| `primitive`, `any`, `any_concept`                     | `namespace_uuid` is the zero UUID, `namespace_name` is `""`.                    |
| `concept`, `club`, `enumeration`, `structure`         | `namespace_uuid` and `namespace_name` identify the namespace of the target.     |

Allowed `name` values when `domain` is `primitive`: `void`, `bool`,
`uint8`, `uint16`, `uint32`, `uint64`, `int8`, `int16`, `int32`,
`int64`, `float`, `double`, `string`, `uuid`, `blob`, `blob_id`,
`commit_id`. A primitive Reference whose `name` is not in this list
**MUST** be rejected.

For `domain` of `any`, `name` is `"any"`. For `any_concept`, `name`
is `"any_concept"`.

### Vec

```json
{
  "class_name":   "vec",
  "element_type": <TypeReference>,
  "size":         3
}
```

`element_type` MUST be a TypeReference. `size` is a positive integer.

### Mat

```json
{
  "class_name":   "mat",
  "element_type": <TypeReference>,
  "columns":      4,
  "rows":         4
}
```

### Tuple

```json
{ "class_name": "tuple", "types": [ <Type>, ... ] }
```

### Optional, Vector, Set, XArray

All four share the same shape — one `element_type` field carrying a
full Type:

```json
{ "class_name": "optional", "element_type": <Type> }
{ "class_name": "vector",   "element_type": <Type> }
{ "class_name": "set",      "element_type": <Type> }
{ "class_name": "xarray",   "element_type": <Type> }
```

### Map

```json
{
  "class_name":   "map",
  "key_type":     <Type>,
  "element_type": <Type>
}
```

### Variant

```json
{ "class_name": "variant", "types": [ <Type>, ... ] }
```

### Key

```json
{ "class_name": "key", "element_type": <TypeReference> }
```

`element_type` MUST be a TypeReference.


## Literals

A `Literal` represents a default value. It is polymorphic via
`class_name`:

| `class_name`    | Shape                                       |
| --------------- | ------------------------------------------- |
| `literal_value` | A scalar default (or absence).              |
| `literal_list`  | A list of literals (for vector/set/array). |

### Literal value

```json
{
  "class_name": "literal_value",
  "domain":     "double",
  "value":      "3.141592653589793"
}
```

| Field      | Type     | Notes                                          |
| ---------- | -------- | ---------------------------------------------- |
| `domain`   | string   | One of the literal domains (table below).      |
| `value`    | string   | Always a string, even for numeric/bool/uuid.   |

The `value` field is **always a JSON string**, regardless of the
domain. Consumers parse the string according to `domain`. This keeps
the representation lossless for floats and bigints, and avoids the
language-specific JSON-numeric ambiguity. Empty string is permitted
when `domain` is `none`.

Literal domains:

| `domain`           | `value` parsing                                                       |
| ------------------ | --------------------------------------------------------------------- |
| `none`             | Marker for "no default"; `value` SHOULD be `""`.                      |
| `boolean`          | `"true"` or `"false"`.                                                |
| `integer`          | Decimal integer literal.                                              |
| `float`            | IEEE 754 single-precision in textual form.                            |
| `double`           | IEEE 754 double-precision in textual form.                            |
| `string`           | The string value as-is.                                               |
| `uuid`             | RFC 4122 UUID string.                                                 |
| `enumeration_case` | The case identifier (the `name` of an `EnumerationCase`).             |

### Literal list

```json
{
  "class_name": "literal_list",
  "members":    [ <Literal>, ... ]
}
```

`members` MAY contain other literal lists (nested), allowing defaults
for matrices and N-D arrays.


## Validation

A conformant decoder **MUST** distinguish four error categories. The
reference implementation maintains a JSON path so each error quotes
the failing node by location (e.g. `clubs[2].runtime_id`,
`structures[0].fields[1].type.class_name`).

| Code                  | When it fires                                                              |
| --------------------- | -------------------------------------------------------------------------- |
| `expected_type`       | A node has the wrong JSON kind (array expected at root, etc.).             |
| `expected_member`     | A required key is absent.                                                  |
| `expected_member_type`| A key is present but its value has the wrong JSON kind.                    |
| `unknown_value`       | A discriminator (`class_name`, `domain`) is not in the closed enumeration. |

Decoders **SHOULD** include the JSON path of the offending node in the
error message. They **MUST NOT** silently coerce or skip unknown
fields — forward compatibility is handled by versioning, not by leniency.


## Versioning

The schema version is **paired with the viper release** that defines
it. There is no separate schema version number. A breaking schema
change requires a major-version bump on viper, with the change
documented in the release notes.

Producers **SHOULD** emit a separate sidecar field for any future
optional extension. Consumers **MUST** reject unknown top-level keys —
this is what makes versioning safe and explicit.


## Minimal example

A concept-only document, well-formed and decodable:

```json
{
  "concepts": [
    {
      "namespace_uuid": "8fdd9ba9-b85e-4b33-a749-9b9615e43453",
      "namespace_name": "Demo",
      "name":           "Thing",
      "documentation":  "An empty concept for the schema example.",
      "runtime_id":     "00000000-0000-0000-0000-000000000001"
    }
  ],
  "clubs":                     [],
  "enumerations":              [],
  "structures":                [],
  "attachments":               [],
  "function_pools":            [],
  "attachment_function_pools": []
}
```


## See also

- `src/main/java/com/digitalsubstrate/viper/dsm/DSMDefinitionsJsonLexicon.java`
  — the key-name constants used throughout this spec.
- `src/main/java/com/digitalsubstrate/viper/dsm/DSMDefinitionsJsonDecoder.java`
  — a reference consumer with full path-tracking error reporting.
- `src/main/java/com/digitalsubstrate/viper/dsm/DSMDefinitionsJsonDecodingException.java`
  — the four error categories (`expected_type`, `expected_member`,
  `expected_member_type`, `unknown_value`) as factory methods.
