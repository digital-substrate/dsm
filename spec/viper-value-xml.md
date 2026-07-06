# Viper Values — XML Wire Format

This document specifies the **XML wire format** for a Viper `Value` — the
runtime representation of data in the Viper type/value system. It is the
on-the-wire / on-disk encoding that producers emit and consumers read, a
third dialect alongside the JSON and BSON forms of
[`viper-value-json.md`](viper-value-json.md).

> **What this is not.** This is **not** an [XML Schema
> (XSD)](https://www.w3.org/XML/Schema): it is a prose specification of the
> structure of conforming XML documents, not a machine-readable schema for
> them. It is also **not** the encoding of a *type model*: that is the job of
> the companion document `dsm-xml.md` (forthcoming), the XML sibling of
> [`dsm-json.md`](dsm-json.md). This document describes how a *value* of a
> known type is serialized.

The JSON, BSON, and XML forms encode the **same logical model** through
different containers; only the physical representation differs. Everything in
[`viper-value-json.md`](viper-value-json.md) about type-driven decoding and
the definitions dependency applies here unchanged — this document restates it
for self-containedness and specifies the XML-specific choices.

This document is the contract, and it is self-contained. A conformant document
is one that this spec accepts; a conformant decoder is one that this spec
describes. A producer or consumer can be implemented against this spec alone,
in any language under any license.


## Conformance

- The keywords **MUST**, **SHOULD**, and **MAY** are used per RFC 2119.
- All text is UTF-8. A document **SHOULD** begin with the XML declaration
  `<?xml version="1.0" encoding="UTF-8"?>`.
- A value document has exactly one root element (§Root).
- Producers **SHOULD** emit child elements in a stable order and indent for
  readable diffs; consumers **MUST NOT** depend on insignificant whitespace
  between elements.
- **Data travels in elements.** Attributes are reserved for the XML-instance
  markers `xsi:type` and `xsi:nil` (§Any, §Optional). No value datum is
  encoded as an attribute.
- **Local (field, item, entry) element names are unqualified** — they carry no
  namespace prefix. Only *type-named* elements (the root, and elements whose
  name is a type QName) are namespace-qualified. This mirrors XSD's
  `elementFormDefault="unqualified"` and keeps documents free of prefix noise.
- The XML-instance namespace is
  `xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"`, declared on the
  root when `xsi:type` or `xsi:nil` is used.


## Namespaces — DSM identity as a QName

A Viper type's identity is a `TypeName` = (`namespace_uuid`, `namespace_name`,
`name`) (see [`dsm-json.md`](dsm-json.md)). It maps to an XML **QName** as:

| DSM field        | XML role                                             |
| ---------------- | ---------------------------------------------------- |
| `namespace_uuid` | the **namespace URI**: `urn:uuid:<namespace_uuid>`   |
| `namespace_name` | the **preferred prefix**                             |
| `name`           | the **local name**                                   |

So a `Raptor` structure `SurfaceProperties` in namespace
`f2d9ea90-2adc-4e9a-a2bf-02288281747d` is the element:

```xml
<Raptor:SurfaceProperties
    xmlns:Raptor="urn:uuid:f2d9ea90-2adc-4e9a-a2bf-02288281747d">
  ...
</Raptor:SurfaceProperties>
```

The **URI carries identity** (a URN derived from the UUID — an identifier, not
a dereferenceable location); the **prefix is cosmetic** (readability only). A
document declares, on its root element, an `xmlns:<prefix>` for every DSM
namespace it references, plus `xmlns:xsi` when needed. Primitive types live in
the zero namespace and are written **unqualified** (`<int32>`, not
`<xs:int>`).


## The central principle: encoding is type-driven

An XML value document is **not self-describing**. With two exceptions
([`any`](#any) and [`variant`](#variant)), an element carries no type marker;
the same XML text decodes to different values depending on the type supplied at
decode time. The text `<x>5</x>` decodes to an `int32`, a `uint8`, or an
`int64` according to the type the decoder is given; `<x>1 2 3</x>` decodes to a
`vec` or a scalar `vector`/`set` according to the type.

Consequently a decoder **MUST** be given:

1. the **root `Type`** the document was produced for, and
2. a **definitions registry** able to resolve every named type (concept, club,
   enumeration, structure, primitive) referenced inside the document or its
   embedded types (see [Type dependency](#type-dependency)).

An encoder needs only the value: it carries its own type at runtime.


## Root

The root element **names the value's type**:

- a **named** type (structure, enumeration) → its QName, e.g.
  `<Raptor:SurfaceProperties>`;
- a **primitive** → its unqualified primitive name, e.g. `<int32>42</int32>`;
- a **container / composite** with no type name (`vector`, `map`, `tuple`,
  `optional`, `variant`, `any`, `key`, `xarray`) → its type-kind name, e.g.
  `<vector>`, `<map>`.

The root carries the `xmlns` declarations for every namespace used in the
document.


## Value encoding

Each Viper type code maps to one XML shape. The encoder dispatches on the
value's runtime type code; the decoder dispatches on the supplied type.

| Type code       | XML shape                                                             |
| --------------- | --------------------------------------------------------------------- |
| `void`          | empty element with `xsi:nil="true"`                                   |
| `bool`          | text `true` / `false`                                                 |
| `uint8/…/64`    | decimal text (unsigned)                                               |
| `int8/…/64`     | decimal text (signed)                                                 |
| `float`         | text (`xs:float` lexical: `5.0`, `1.5E3`, `INF`, `-INF`, `NaN`)       |
| `double`        | text (`xs:double` lexical)                                            |
| `string`        | text (XML-escaped)                                                    |
| `blob`          | text (Base64, `xs:base64Binary`)                                      |
| `uuid`          | text (RFC 4122, 36 chars)                                             |
| `blob_id`       | text (40 hex chars)                                                   |
| `commit_id`     | text (40 hex chars)                                                   |
| `vec`           | scalar element type → space-separated text; complex → `<item>` list   |
| `mat`           | scalar element type → space-separated text; complex → `<item>` list   |
| `tuple`         | positional `<item>` children, heterogeneous                           |
| `optional`      | the wrapped value inline, or `xsi:nil="true"` when empty              |
| `vector`        | scalar element type → space-separated text; complex → `<item>` list   |
| `set`           | scalar element type → space-separated text; complex → `<item>` list   |
| `map`           | `<entry><key>…</key><value>…</value></entry>` children                |
| `xarray`        | `<positions>` `<deleted>` `<elements>` children                       |
| `enumeration`   | text: the bare case name                                              |
| `structure`     | one child element per field, named by the field, unqualified         |
| `key`           | `<instance>` + `<concept>` children                                   |
| `any`           | `xsi:type` (or `<type>`/`<value>`) — see [Any](#any)                  |
| `variant`       | `xsi:type` (or `<type>`/`<value>`) — see [Variant](#variant)          |

### Primitives

**Booleans** encode as `true` / `false`. On decode, `1` / `0` are also
accepted (`xs:boolean` lexical space).

**Integers** encode as decimal text. Unsigned types accept any integer literal
and are range-checked against the target width; signed types require a signed
integer literal and are range-checked. A value outside the width is rejected.

**`float` / `double`** encode as text carrying a fraction or exponent (a whole
value is written `5.0`, not `5`), using the `xs:float` / `xs:double` lexical
space, including `INF`, `-INF`, `NaN`. On decode a bare integer literal such as
`5` is accepted and read as `5.0`. `float` is range-checked to single
precision.

**`string`** is text content, XML-escaped (`&`, `<`, `>` mandatory; `"`, `'`
inside text optional). Leading/trailing significant whitespace, if any, is
preserved (`xml:space="preserve"` MAY be set; producers SHOULD avoid
significant whitespace at element edges).

**`blob`** is Base64 text; whitespace within is ignored on decode.

**`uuid`** is a lowercase, hyphenated RFC 4122 string (36 chars). **`blob_id`
/ `commit_id`** are 40-char lowercase hex (20 bytes). Wrong length or non-hex
is rejected.

**`void`** is an empty element with `xsi:nil="true"`.

### Vec and Mat

Both are fixed-size. When the element type is a **scalar** (numeric, bool),
the elements are written as **space-separated text** (`xs:list` style):

```xml
<transform>1 0 0 0  0 1 0 0  0 0 1 0  0 0 0 1</transform>
```

When the element type is **complex**, the elements are `<item>` children.
`vec` carries exactly `size` elements; `mat` carries exactly `columns × rows`
in linear element order. Decoders reject the wrong count.

### Tuple

Heterogeneous and positional → `<item>` children, one per tuple slot, each
decoded against its declared element type. The count is fixed by the type.

```xml
<item>42</item>
<item>label</item>
<item>true</item>
```

### Optional

An optional encodes **inline**: a present value is encoded as the element's
content directly; an empty optional is the empty element `xsi:nil="true"`.

```xml
<note>present</note>          <!-- some -->
<note xsi:nil="true"/>        <!-- none -->
```

`xsi:nil` disambiguates none from a nested nullable only via the supplied
type, consistent with the type-driven principle.

### Vector and Set

Both are dynamic collections. When the element type is a **scalar**, the
elements are **space-separated text**; when **complex**, they are `<item>`
children:

```xml
<weights>0.5 0.3 0.2</weights>                 <!-- vector<double> -->
<parts><item>…</item><item>…</item></parts>    <!-- vector<Part>   -->
```

A `set` carries no duplicates; uniqueness is re-established on decode.

### Map

A wrapper element containing an `<entry>` per pair, each with a `<key>` and a
`<value>` child — because map keys may be of any type, not only strings:

```xml
<materials>
  <entry><key>alpha</key><value>1</value></entry>
  <entry><key>beta</key><value>2</value></entry>
</materials>
```

`<key>` is decoded against the key type, `<value>` against the element type.

### XArray

The internal memento encodes as three named children:

```xml
<positions>uuid-a uuid-b …</positions>   <!-- ordered live positions (xs:list) -->
<deleted>uuid-x …</deleted>              <!-- tombstones (xs:list)              -->
<elements>
  <entry><key>uuid-a</key><value>…</value></entry>
  …
</elements>
```

Position identifiers are RFC 4122 strings; `<positions>` fixes element order,
`<elements>` maps each live position to its encoded element value.

### Enumeration

The **bare case name** as text (the `xs:enumeration` convention):

```xml
<mode>Cylindrical</mode>
```

On decode the text **MUST** name a case of the target enumeration; anything
else is rejected as a malformed enumeration case.

### Structure

One child element per field, **named by the field**, unqualified, in the
struct's declared field order:

```xml
<Raptor:SurfaceProperties xmlns:Raptor="urn:uuid:f2d9ea90-…">
  <billboardMode>Cylindrical</billboardMode>
  <color>0.5 0.5 0.5</color>
  <mirror xsi:nil="true"/>
</Raptor:SurfaceProperties>
```

Decoding is **lenient by design**, supporting schema evolution:

- a declared field **absent** from the element keeps its type default — not an
  error;
- a child element that does **not** correspond to a declared field is
  **ignored**.

This is the one deliberate exception to strict rejection (contrast the strict
`dsm-xml` type-model document).

### Key

A reference to a keyed instance encodes as two children:

```xml
<owner>
  <instance>6b3d1c2e-0000-4000-8000-000000000001</instance>
  <concept>529d57ac-5779-6d37-6703-9cefb0ce4591</concept>
</owner>
```

`<instance>` is the instance UUID; `<concept>` is the target concept's runtime
id, resolved against the registry. An **all-zero** concept runtime id denotes
an unassigned **null key** (admissible for any element type). Otherwise the
resolved concept **MUST** conform to the key's element type (concept:
same-or-descendant; club: member-or-descendant-of-member; `any_concept`: any
known concept).

### Any

`any` is one of the two **self-describing** shapes. The common case — content
of a **primitive or named** type — uses the idiomatic `xsi:type` attribute
carrying the type's QName:

```xml
<extra xsi:type="int32">7</extra>
<extra xsi:type="Raptor:Surface"> … </extra>
```

When the content type is **parametric** (a `vector`, `map`, `tuple`, … that a
QName cannot name), the element instead carries a structural `<type>` /
`<value>` pair, with the embedded type encoded as elements
(§[Embedded type encoding](#embedded-type-encoding)):

```xml
<extra>
  <type><vector><element_type><reference>int32</reference></element_type></vector></type>
  <value><item>1</item><item>2</item></value>
</extra>
```

An **empty** `any` is `xsi:nil="true"`. On decode, `xsi:type` (or the embedded
`<type>`) is resolved against the registry.

### Variant

`variant` embeds its content type the same way as `any` (`xsi:type` for a
named/primitive member, structural `<type>`/`<value>` for a parametric one). On
decode the embedded type **MUST** be a member of the variant's declared type
set, otherwise the document is rejected. Unlike `any`, a `variant` is never
nil.


## Embedded type encoding

The type carried by an `any` / `variant` (when not expressible as an
`xsi:type` QName) is a serialized `Type`, encoded as **elements** whose name is
the type family, mirroring the JSON embedded-type shape but in XML:

| Family (element)                                                | Children                                  |
| --------------------------------------------------------------- | ----------------------------------------- |
| `<reference>`                                                   | text: the QName (or primitive name)       |
| `<vec>` / `<mat>`                                               | `<element_type>`, `size` \| `columns`/`rows` (attributes on the element) |
| `<tuple>` / `<variant>`                                         | a `<type>` child per member               |
| `<optional>` / `<vector>` / `<set>` / `<xarray>` / `<key>`      | one `<element_type>`                       |
| `<map>`                                                         | `<key_type>`, `<element_type>`             |

`<element_type>`, `<key_type>`, and members are **full** embedded types
(recursively encoded). A `<reference>` resolves by QName against the registry;
its `name` is the primitive name for primitives.


## Type dependency

Decoding requires a **definitions registry** — the loaded type model (from
[`dsm-json.md`](dsm-json.md) or the forthcoming `dsm-xml.md`). The registry
resolves, by QName / runtime id, every `reference`, `concept`, `club`,
`enumeration`, `structure`, and `key` target. A name absent from the registry
is a decode error. This is why decoding is type-driven: the wire format
references types by identity, and the identities must already be known.


## Validation

A conformant decoder distinguishes the following categories (it **SHOULD**
locate the failing element by path; the exact context string is
implementation-defined):

| Code                           | When it fires                                                         |
| ------------------------------ | --------------------------------------------------------------------- |
| `expected_type`                | an element has the wrong shape for the expected type                  |
| `expected_member`              | a required child element is absent (outside structure leniency)       |
| `expected_member_type`         | a child is present but has the wrong shape                            |
| `malformed_enumeration_case`   | enumeration text is not a case of the target                          |
| `not_a_club_member_descendant` | a `key`'s concept is not a member/descendant of the target club       |
| `not_a_member_of_variant`      | an embedded type is not in the variant's set                          |
| `not_a_concept_descendant`     | a `key`'s concept is not the element concept nor a descendant         |
| `malformed_document`           | the input is not well-formed XML                                      |

Decoders additionally surface **range errors** (integer / `float` width) and
**parse errors** (`uuid`, `blob_id`, `commit_id`, Base64 `blob`). Structure
leniency (§Structure) is the one deliberate exception to strict rejection.


## Versioning

The wire format is **paired with the viper release** that defines it; there is
no separate schema version number. A breaking change requires a major-version
bump on viper, documented in the release notes. Forward compatibility for
**structures** is handled by the leniency rule; outside structures, decoding
relies on the type model being in lockstep with the data.


## Minimal example

A structure value, with a scalar vector, an empty optional, and an embedded
`any`, in the `Raptor` namespace:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Raptor:SurfaceProperties
    xmlns:Raptor="urn:uuid:f2d9ea90-2adc-4e9a-a2bf-02288281747d"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <label>origin</label>
  <color>0.5 0.5 0.5</color>
  <note xsi:nil="true"/>
  <extra xsi:type="int32">7</extra>
</Raptor:SurfaceProperties>
```

Decoding this requires the structure's `Type` and a definitions registry that
resolves `Raptor:SurfaceProperties` and the `int32` primitive.


## Appendix A — Reserved names

- **Namespaces.** `urn:uuid:<namespace_uuid>` for each DSM namespace;
  `http://www.w3.org/2001/XMLSchema-instance` for `xsi`.
- **Instance attributes.** `xsi:type` (embedded type QName), `xsi:nil`
  (`true` for void / empty optional / null-ish absence).
- **Reserved local element names.** `item` (container element),
  `entry` / `key` / `value` (map & xarray-element entries),
  `instance` / `concept` (key), `positions` / `deleted` / `elements`
  (xarray), `type` / `value` (structural any / variant),
  `element_type` / `key_type` (embedded types). A structure field **MUST NOT**
  be named to collide with a reserved name in a position where the collision is
  ambiguous; producers SHOULD document any such field.
- **Embedded type families.** `reference`, `vec`, `mat`, `tuple`, `optional`,
  `vector`, `set`, `map`, `xarray`, `variant`, `key`.


## See also

- [`viper-value-json.md`](viper-value-json.md) — the JSON + BSON dialects of
  the same logical model; the type-driven decode contract inherited here.
- [`dsm-json.md`](dsm-json.md) — the type-model wire format the registry is
  loaded from; `dsm-xml.md` (forthcoming) is its XML sibling.
