# Domain Contract (Milestone B)

The domain layer lives in `IndianFoodTracker/Domain/`. It uses Foundation only, is `nonisolated` and `Sendable`, and never reads the system clock.

## Invariants (all enforced by tests)

- Changing a Food never changes a FoodLogEntry that was already logged. Entries hold a frozen snapshot of the food, and edits recompute from that snapshot.
- Unknown is not zero. A missing nutrient is unknown, a stored 0 is known. Totals report `noEntries`, `noKnownValues`, `partial`, or `complete`.
- Nutrition math uses Decimal only. Values are rounded to 4 places once, when stored. Totals sum stored values. Display rounding is separate.
- A day is a `LocalDate` (Gregorian), stored as an Int key such as 20261007. It is never recomputed from a time zone later.
- Future days cannot be logged. "Today" is always passed in.
- A DaySummary is derived from entries. It is never stored.
- Energy must be known for a food to be loggable. Every other nutrient may be unknown.
- Variants adjust only known nutrients, never go below zero, and are estimates unless marked otherwise.

## Not in this layer yet

Persistence, the catalog, Codable and backup, provenance and categories, refreshing an entry from the current food, and any UI.
