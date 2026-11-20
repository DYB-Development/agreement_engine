# The byte form, version 1

Every issued version in agreement_engine carries a SHA-256 hash. The hash is
taken from the version's byte form, a fixed series of bytes built from its
content by the rule below. Anyone holding a byte-form file can recompute the
hash with any SHA-256 tool and compare it with the hash recorded on a
signature, without trusting the app that recorded it.

## The rule

1. Build one JSON object with exactly five keys:
   - `slug`: the slug of the keystone_ui-pages page the version was issued from.
   - `number`: that page version's number, as an integer.
   - `document`: that page version's JSON document, exactly as it was published.
   - `values`: the host values the document was filled with, as an object, or
     `{}` when there are none.
   - `period`: the period the document covers, or `null` when it has none.
2. Sort the keys of every object, at every depth, by their characters in
   Unicode code point order. Arrays keep their order.
3. Write the object as JSON with no whitespace between tokens, encoded as
   UTF-8. Characters outside ASCII are written as themselves, not escaped.
4. The hash is the SHA-256 of those bytes, written as 64 lowercase hex digits.

Rendered HTML and PDFs are never part of the bytes, so a change to how a page
is drawn never changes a hash. Version 1 of the rule never changes. A later
rule would be version 2, kept beside version 1 for as long as any version 1
hash exists, and each issued version records which version it was hashed with.

## Checking a file

```
shasum -a 256 copy.json
agreement_engine-verify copy.json <hash>
```

The `agreement_engine-verify` command is installed with the gem and loads no
app. The verify page at `/verify` gives the same answer.

## Worked examples

Each folder under `docs/byte-form/examples/` holds an `input.json` written for
reading, the `bytes.json` the rule produces from it, and the `sha256` of those
bytes. The gem's test suite fails if any example would produce different bytes
or a different hash.
