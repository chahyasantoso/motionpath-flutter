# Phase 2 acceptance gate

Phase 2 remains active after PR #69. That PR delivered the optional top-level interest filter, but it did not close the immutable patch contract.

## Remaining required work

- Define public output, internal, renderer metadata, and plugin-owned key categories.
- Add one public patch normalizer/serializer boundary before renderer consumption.
- Prove top-level and nested patch immutability at every public boundary.
- Document units and semantics for transforms, depth, opacity, colors, filters, images, instances, and custom properties.
- Expand JS-backed parity coverage to every supported plugin and record intentional divergences.
- Add tests for normalized output shape and consumer mutation attempts.

## Exit rule

Do not open or merge a Phase 3 renderer PR until every item above has code and tests, CI is green, the implementation plan is updated, and this gate is marked complete.
