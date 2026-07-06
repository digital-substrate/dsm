# DSM Definitions — XML Wire Format

This document specifies the **XML wire format** for a `DSMDefinitions` — the
data model that results from parsing one or more `.dsm` source files. It is the
XML sibling of [`dsm-json.md`](dsm-json.md), and the type-model counterpart of
[`viper-value-xml.md`](viper-value-xml.md).

> **What this is not.** This is **not** an [XML Schema (XSD)](https://www.w3.org/XML/Schema)
> document — it is a prose specification of the structure of conforming XML
> documents. It is also **not** an XML form of the surface grammar (that lives
> in [`grammar/DSM.g4`](../grammar/DSM.g4)); it describes what the parsed model
> looks like once serialized as XML.

The JSON ([`dsm-json.md`](dsm-json.md)) and XML forms encode the **same logical
model**; the same `DSMDefinitions` loaded from either yields the same model
(and therefore the same definitions digest). This document is the contract and
is self-contained: a conformant producer or consumer can be implemented against
it alone, in any language under any license.

A conformant document is intentionally **round-trip stable** so read-modify-write
tools (editors, visualizers) see no field drift.


## Conformance

- The keywords **MUST**, **SHOULD**, and **MAY** are used per RFC 2119.
- All text is UTF-8; a document **SHOULD** begin with
  `<?xml version="1.0" encoding="UTF-8"?>`.
- The root is a single `<definitions>` element in the DSM meta-namespace
  `xmlns="urn:dsm"`. All meta-vocabulary elements below live in this namespace.
- **This is a strict document.** A decoder **MUST** reject an unknown element,
  an unknown attribute, a required element/attribute that is absent, or an
  unknown discriminator value. Forward compatibility is handled by versioning,
  **not** by leniency. (This is the opposite of `viper-value-xml.md`'s lenient
  *structure* rule — a schema is strict, its instances are lenient.)

### Attribute-vs-element convention (schema-shaped, like XSD)

Because this document *describes types* (it is a schema, not business data), it
follows the **XSD idiom**, not the data-XML idiom of `viper-value-xml.md`:

- **Attributes** carry the whitespace-safe scalar identity / metadata:
  `namespaceUuid`, `namespaceName`, `name`, `runtimeId`, `uuid`, `domain`,
  `size`, `columns`, `rows`, `isMutable`.
- **Elements** carry documentation, literal values, and all nested trees:
  `<documentation>`, `<value>`, and the collection / field / type / literal
  structures. Two things are elements specifically to survive XML attribute
  whitespace-normalization: **`<documentation>`** (may be long / multi-line)
  and a literal's **`<value>`** (may be an arbitrary string).
- **Polymorphism is expressed by element name**, not a `class_name` attribute:
  a Type is a `<reference>` / `<vector>` / `<map>` / … element; a Literal is a
  `<literalValue>` / `<literalList>` element. The element name *is* the
  discriminator.
- **Names are lowerCamelCase** (the XML/XSD idiom). They correspond one-to-one
  to the `dsm-json.md` keys — `namespaceUuid` ↔ `namespace_uuid`, `elementType`
  ↔ `element_type` — rendered in XML-native casing. Closed **values** (the
  `domain` tokens such as `any_concept`, `enumeration_case`, and the primitive
  `name`s such as `blob_id`) are format-independent vocabulary and are kept
  **verbatim** from `dsm-json.md`.


## Top-level structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="urn:dsm">
  <concepts> … </concepts>
  <clubs> … </clubs>
  <enumerations> … </enumerations>
  <structures> … </structures>
  <attachments> … </attachments>
  <functionPools> … </functionPools>
  <attachmentFunctionPools> … </attachmentFunctionPools>
</definitions>
```

Each grouping element is present (it MAY be empty) and contains the
corresponding declarations, mirroring the seven arrays of `dsm-json.md`.


## Common patterns

### Identity (TypeName)

Every named declaration (concept, club, enumeration, structure, attachment)
carries three identity **attributes**:

| Attribute       | Notes                                                        |
| --------------- | ------------------------------------------------------------ |
| `namespaceUuid` | RFC 4122 UUID, lowercase hex, hyphenated.                    |
| `namespaceName` | Human-readable namespace alias (e.g. `Raptor`).             |
| `name`          | The unqualified identifier within the namespace.            |

### Documentation

Every declaration carries a `<documentation>` **element**. It MAY be empty
(`<documentation/>`); it is never absent.

### Runtime identity

Every top-level *named* entity carries a `runtimeId` **attribute** (UUID).
Function pools use `uuid` instead (see Function pools).


## Concepts

```xml
<concept namespaceUuid="8fdd9ba9-b85e-4b33-a749-9b9615e43453"
         namespaceName="Raptor" name="Surface"
         runtimeId="529d57ac-5779-6d37-6703-9cefb0ce4591">
  <documentation>A surface concept.</documentation>
  <parent><reference domain="concept" namespaceUuid="…" namespaceName="Raptor" name="Base"/></parent>
</concept>
```

`<parent>` is the **only optional element**: present only when the concept
extends another (its child is a TypeReference). A concept without a parent
omits the element entirely.


## Clubs

```xml
<club namespaceUuid="…" namespaceName="Raptor" name="Renderable" runtimeId="…">
  <documentation>…</documentation>
  <members>
    <reference domain="concept" namespaceUuid="…" namespaceName="Raptor" name="Surface"/>
    …
  </members>
</club>
```

`<members>` contains one TypeReference (`<reference>`) per member concept.


## Enumerations

```xml
<enumeration namespaceUuid="…" namespaceName="Raptor" name="SurfaceBillboardMode" runtimeId="…">
  <documentation>…</documentation>
  <cases>
    <case name="Cylindrical"><documentation>…</documentation></case>
    <case name="Spherical"><documentation/></case>
  </cases>
</enumeration>
```


## Structures

```xml
<structure namespaceUuid="…" namespaceName="Raptor" name="SurfaceProperties" runtimeId="…">
  <documentation>…</documentation>
  <fields>
    <field name="billboardMode">
      <documentation/>
      <type><reference domain="enumeration" namespaceUuid="…" namespaceName="Raptor" name="SurfaceBillboardMode"/></type>
      <defaultValue><literalValue domain="enumeration_case"><value>Cylindrical</value></literalValue></defaultValue>
    </field>
    <field name="color">
      <documentation/>
      <type><vec size="3"><elementType><reference domain="primitive" name="double"/></elementType></vec></type>
      <defaultValue><literalList><members>
        <literalValue domain="double"><value>0.5</value></literalValue>
        <literalValue domain="double"><value>0.5</value></literalValue>
        <literalValue domain="double"><value>0.5</value></literalValue>
      </members></literalList></defaultValue>
    </field>
  </fields>
</structure>
```

Each `<field>` carries a `name` attribute, a `<documentation>`, a `<type>`
(polymorphic Type), and a `<defaultValue>` (polymorphic Literal). A field with
no semantic default uses a literal of domain `none`; the element is never
absent.


## Attachments

```xml
<attachment namespaceUuid="…" namespaceName="Raptor" name="properties" runtimeId="…">
  <documentation>…</documentation>
  <keyType><reference domain="concept" namespaceUuid="…" namespaceName="Raptor" name="Surface"/></keyType>
  <documentType><reference domain="structure" namespaceUuid="…" namespaceName="Raptor" name="SurfaceProperties"/></documentType>
</attachment>
```

`<keyType>` MUST wrap a TypeReference; `<documentType>` wraps a full
polymorphic Type.


## Function pools

### Free function pools

```xml
<functionPool uuid="…" name="Tools">
  <documentation>…</documentation>
  <functions>
    <function>
      <documentation>…</documentation>
      <prototype name="clamp"> … </prototype>
    </function>
  </functions>
</functionPool>
```

The pool's identifier is `uuid` (attribute), not `runtimeId`; there is no
namespace on a pool.

### Attachment function pools

Same shape, but each `<function>` carries an `isMutable` attribute:

```xml
<function isMutable="true">
  <documentation>…</documentation>
  <prototype name="setColor"> … </prototype>
</function>
```

### Prototype & parameters

```xml
<prototype name="clamp">
  <parameters>
    <parameter name="x"><type><reference domain="primitive" name="double"/></type></parameter>
  </parameters>
  <returnType><reference domain="primitive" name="double"/></returnType>
</prototype>
```

A void-returning function uses a `<reference domain="primitive" name="void"/>`.


## Type system

A Type is one of the following **elements** (the element name is the
discriminator). A decoder **MUST** reject any other element in a type position.

| Element     | Shape                                                                    |
| ----------- | ------------------------------------------------------------------------ |
| `reference` | leaf reference to a primitive or named entity (identity attributes)      |
| `vec`       | `size` attr + `<elementType>` (a TypeReference)                          |
| `mat`       | `columns` + `rows` attrs + `<elementType>` (a TypeReference)             |
| `tuple`     | `<types>` (ordered, heterogeneous full Types)                            |
| `optional`  | `<elementType>` (a full Type)                                            |
| `vector`    | `<elementType>` (a full Type)                                            |
| `set`       | `<elementType>` (a full Type)                                            |
| `xarray`    | `<elementType>` (a full Type)                                            |
| `map`       | `<keyType>` + `<elementType>` (full Types)                               |
| `variant`   | `<types>` (a full Type per member)                                       |
| `key`       | `<elementType>` (a TypeReference targeting an attachment key type)       |

### Reference

```xml
<reference domain="primitive" name="float"/>
<reference domain="structure" namespaceUuid="…" namespaceName="Raptor" name="SurfaceProperties"/>
```

`domain` is one of `any`, `primitive`, `concept`, `club`, `any_concept`,
`enumeration`, `structure`. For `primitive`, `any`, `any_concept` the identity
is the zero namespace and the `namespaceUuid` / `namespaceName` attributes
**MAY be omitted** (they default to the zero UUID and empty string); for named
domains they are **required**. Allowed primitive `name` values: `void`, `bool`,
`uint8`, `uint16`, `uint32`, `uint64`, `int8`, `int16`, `int32`, `int64`,
`float`, `double`, `string`, `uuid`, `blob`, `blob_id`, `commit_id`.

### Composite types

```xml
<vec size="3"><elementType><reference domain="primitive" name="double"/></elementType></vec>
<mat columns="4" rows="4"><elementType><reference domain="primitive" name="double"/></elementType></mat>
<tuple><types><reference domain="primitive" name="int32"/><reference domain="primitive" name="string"/></types></tuple>
<optional><elementType><reference domain="structure" namespaceUuid="…" namespaceName="Raptor" name="Mesh"/></elementType></optional>
<map><keyType><reference domain="primitive" name="uuid"/></keyType><elementType><reference domain="structure" namespaceUuid="…" namespaceName="Raptor" name="Material"/></elementType></map>
<variant><types><reference domain="primitive" name="int32"/><reference domain="primitive" name="double"/></types></variant>
<key><elementType><reference domain="concept" namespaceUuid="…" namespaceName="Raptor" name="Surface"/></elementType></key>
```

`<elementType>`, `<keyType>`, and the members of `<types>` are **full**
embedded Types (recursively encoded). `vec` / `mat` / `key` require their
`<elementType>` to be a `<reference>`.


## Literals

A default value is one of two **elements**:

### Literal value

```xml
<literalValue domain="double"><value>3.141592653589793</value></literalValue>
```

`domain` (attribute) is one of `none`, `boolean`, `integer`, `float`, `double`,
`string`, `uuid`, `enumeration_case`. The `<value>` **element** always holds a
**string**, parsed by the consumer according to `domain` — this keeps floats
and bigints lossless, avoids XML-numeric ambiguity, and (being an element, not
an attribute) survives arbitrary string content without whitespace
normalization. An empty `<value/>` is permitted when `domain` is `none`.

### Literal list

```xml
<literalList><members>
  <literalValue domain="double"><value>1.0</value></literalValue>
  <literalList> … </literalList>
</members></literalList>
```

`<members>` MAY nest literal lists (matrices, N-D arrays).


## Validation

A conformant decoder distinguishes:

| Code                   | When it fires                                                          |
| ---------------------- | --------------------------------------------------------------------- |
| `expected_type`        | an element has the wrong shape for its position                       |
| `expected_member`      | a required element or attribute is absent                             |
| `expected_member_type` | an element/attribute is present but ill-formed for its position       |
| `unknown_value`        | a discriminator element name or `domain` is not in the closed set     |
| `unknown_member`       | an unknown element or attribute is present (strict: not ignored)      |
| `malformed_document`   | the input is not well-formed XML                                      |

Decoders **SHOULD** locate the failing node by element path. They **MUST NOT**
silently coerce or skip unknown content.


## Versioning

The schema version is **paired with the viper release** that defines it; there
is no separate schema version number. A breaking change requires a major-version
bump on viper, documented in the release notes. Consumers **MUST** reject
unknown elements and attributes — this is what makes versioning safe and
explicit.


## Minimal example

A concept-only document, well-formed and decodable:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="urn:dsm">
  <concepts>
    <concept namespaceUuid="8fdd9ba9-b85e-4b33-a749-9b9615e43453"
             namespaceName="Demo" name="Thing"
             runtimeId="00000000-0000-0000-0000-000000000001">
      <documentation>An empty concept for the schema example.</documentation>
    </concept>
  </concepts>
  <clubs/>
  <enumerations/>
  <structures/>
  <attachments/>
  <functionPools/>
  <attachmentFunctionPools/>
</definitions>
```


## Appendix A — Lexicon

### Meta-namespace

`urn:dsm` (default namespace of every element below).

### Collection & structural elements

`definitions`, `concepts`, `concept`, `clubs`, `club`, `enumerations`,
`enumeration`, `cases`, `case`, `structures`, `structure`, `fields`, `field`,
`attachments`, `attachment`, `functionPools`, `functionPool`,
`attachmentFunctionPools`, `functions`, `function`, `prototype`, `parameters`,
`parameter`, `members`, `documentation`, `parent`, `type`, `elementType`,
`keyType`, `documentType`, `returnType`, `defaultValue`, `types`, `value`.

### Attributes (lowerCamelCase; ↔ `dsm-json.md` keys)

`namespaceUuid` ↔ `namespace_uuid`, `namespaceName` ↔ `namespace_name`, `name`,
`runtimeId` ↔ `runtime_id`, `uuid`, `domain`, `size`, `columns`, `rows`,
`isMutable` ↔ `is_mutable`.

### Type-family elements (discriminators)

`reference`, `vec`, `mat`, `tuple`, `optional`, `vector`, `set`, `map`,
`xarray`, `variant`, `key`.

### Literal-family elements (discriminators)

`literalValue`, `literalList`.

### `domain` values (verbatim from `dsm-json.md`)

TypeReference: `any`, `primitive`, `concept`, `club`, `any_concept`,
`enumeration`, `structure`. LiteralValue: `none`, `boolean`, `integer`, `float`,
`double`, `string`, `uuid`, `enumeration_case`.

### Primitive type names (verbatim)

`void`, `bool`, `uint8`, `uint16`, `uint32`, `uint64`, `int8`, `int16`,
`int32`, `int64`, `float`, `double`, `string`, `uuid`, `blob`, `blob_id`,
`commit_id`.


## See also

- [`dsm-json.md`](dsm-json.md) — the JSON form of the same type model; its
  snake_case keys map one-to-one to this spec's lowerCamelCase names.
- [`viper-value-xml.md`](viper-value-xml.md) — the XML form of a *value* of a
  type described here; note it is data-shaped (elements) where this is
  schema-shaped (attributes).
- [`grammar/DSM.g4`](../grammar/DSM.g4) — the source-language grammar.
