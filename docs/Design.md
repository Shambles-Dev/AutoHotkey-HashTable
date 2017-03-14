The constructor does not support converting an Object because how to convert an Object with `1` and `2` as keys would be ambiguous.

`Set(Key, Value)` returns `Value` instead of `this` because that is how AutoHotkey’s `__Set(Key..., Value)` meta-function and properties work, because that is how chained assignment works.

The parts of Object’s interface that made sense for an unordered data structure were adopted in the interest of consistency.

I considered but rejected the idea of allowing objects to customize their hashing and equality comparison because it is unlikely it would see much use while AutoHotkey does not support operator overloading.  I avoided using the names I would have used for the methods, `Hash()` and `Eq(Other)`, so that it could be implemented in the future.
