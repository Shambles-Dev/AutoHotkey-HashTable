HashTable
=========

HashTable is an improvement on storing items in AutoHotkey Objects.

With HashTable you can
* store any string key without losing access to HashTable’s methods
* prevent string keys from being case-folded
* prevent floating-point keys from being indexed by their current string representation instead of their value

:warning: Hash tables are inherently unordered.  When enumerating a hash table, do not expect to process keys in sorted order or insertion order.  If you need to process keys in a certain order, store them in that order in an Array and enumerate that while operating on the HashTable or use something other than a hash table (like an [AVL tree](https://en.wikipedia.org/wiki/AVL_tree)).

:warning: Mutating a hash table while enumerating it might cause items to be processed more than once or skipped.  You can get the desired effect by enumerating a clone of the HashTable while mutating the HashTable you intend to keep.

:warning: Floating-point keys are rarely useful because it is rarely safe to compare the result of a floating-point calculation exactly.  Deduplicating floating-point results and converting mathematical constants to their names are examples of valid uses.

:warning: Object keys are rarely useful because they are indexed by their address.  Two objects might behave identically in every way, but if they are not the *same* object (stored in the same location in memory), they will not be associated with the same value.  Recording visited nodes in a graph traversal algorithm is an example of a valid use.

[Design](docs/Design.md) contains the reasons for the design decisions.

HashTable is compatible with AutoHotkey v1.


## Installation

HashTable.ahk must be placed in a [library directory](https://www.autohotkey.com/docs/Functions.htm#lib).


## Usage

HashTable’s constructor accepts items as Arrays containing a key and a value, in that order.

HashTable supports the following methods:
```AutoHotkey
Get(Key)
Set(Key, Value)
```

`Get(Key)` reads the value associated with a key.

`Set(Key, Value)` writes the value associated with a key.

HashTable also supports the following interfaces from [Object](https://www.autohotkey.com/docs/objects/Object.htm):
```AutoHotkey
Delete(Key)
Count()
_NewEnum()
HasKey(Key)
Clone()
```

HashTable will throw an exception when attempting to get or delete a nonexistent key.
