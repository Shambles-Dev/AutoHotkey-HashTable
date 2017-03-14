class HashTable
{
    __New(Items*)
    {
        local
        ; An AutoHotkey Array takes the place of the array that would normally
        ; be used to implement a hash table's buckets.
        ;
        ; Masking to remove the unwanted high bits to fit within the array
        ; bounds is unnecessary because AutoHotkey Arrays are sparse arrays that
        ; support negative indices.
        ;
        ; Rehashing everything and placing it in a new array that has the next
        ; highest power of 2 elements when over 3/4ths of the buckets are full
        ; is unnecessary for the same reason.
        ;
        ; Separate chaining (instead of Robin Hood hashing with a low probe
        ; count and backwards shift deletion) is used to resolve hash collisions
        ; because it is more time efficient when locality of reference is a lost
        ; cause.
        this._Buckets := []
       ,this._Count   := 0
        loop % Items.Length()
        {
            if (not Items.HasKey(A_Index))
            {
                throw Exception("Missing Arg Error", -1
                               ,"HashTable.__New(Items*)")
            }
            if (not (    IsObject(Items[A_Index])
                     and ComObjType(Items[A_Index]) == ""
                     and Items[A_Index].HasKey("HasKey") != ""))
            {
                throw Exception("Type Error", -1
                               ,"HashTable.__New(Items*)  Invalid argument (expected Array).")
            }
            if (not (    Items[A_Index].HasKey(1)
                     and Items[A_Index].HasKey(2)
                     and Items[A_Index].Count() == 2))
            {
                throw Exception("Value Error", -1
                               ,"HashTable.__New(Items*)  Invalid argument (expected 2 elements).")
            }
            this.Set(Items[A_Index][1], Items[A_Index][2])
        }
        return this
    }

    Count()
    {
        local
        return this._Count
    }

    _GetHash(Key)
    {
        ; _GetHash(Key) is used to find the bucket a key would be stored in.
        local
        if (IsObject(Key))
        {
            Hash := &Key
        }
        else
        {
            if Key is integer
            {
                Hash := Key
            }
            else if Key is float
            {
                ; Canonicalize most of the bitwise representation and prevent
                ; defective truncation (e.g. 1.1e1 & -1 is 1 instead of 11).
                Key          := Key + 0.0
               ,TruncatedKey := Key & -1
                if (Key == TruncatedKey)
                {
                    Hash := TruncatedKey
                }
                else
                {
                    ; This reinterpret casts a floating point value to an
                    ; Integer with the same bitwise representation.
                    ;
                    ; Removing the first step will result in warnings about
                    ; reading an uninitialized variable if warnings are turned
                    ; on.
                    VarSetCapacity(Hash, 8)
                   ,NumPut(Key, Hash,, "Double")
                   ,Hash := NumGet(Hash,, "Int64")
                }
            }
            else
            {
                ; This is the String hashing algorithm used in Java.  It makes
                ; use of modular arithmetic via Integer overflow.
                Hash := 0
                for _, Char in StrSplit(Key)
                {
                    Hash := 31 * Hash + Ord(Char)
                }
            }
        }
        return Hash
    }

    HasKey(Key)
    {
        local
        Found := false
       ,Hash  := this._GetHash(Key)
       ,Item  := this._Buckets.HasKey(Hash) ? this._Buckets[Hash]
               : ""
        while (not Found and Item != "")
        {
            if (Item.Key == Key)
            {
                Found := true
            }
            else
            {
                Item := Item.Next
            }
        }
        return Found
    }

    Get(Key)
    {
        local
        Found := false
       ,Hash  := this._GetHash(Key)
       ,Item  := this._Buckets.HasKey(Hash) ? this._Buckets[Hash]
               : ""
        while (not Found)
        {
            if (Item == "")
            {
                throw Exception("Key Error", -1
                               ,"HashTable.Get(Key)  Key not found.")
            }
            if (Item.Key == Key)
            {
                Value := Item.Value
               ,Found := true
            }
            else
            {
                Item := Item.Next
            }
        }
        return Value
    }

    Set(Key, Value)
    {
        local
        Found        := false
       ,Hash         := this._GetHash(Key)
       ,Item         := this._Buckets.HasKey(Hash) ? this._Buckets[Hash]
                      : ""
       ,PreviousItem := ""
        while (not Found and Item != "")
        {
            if (Item.Key == Key)
            {
                Item.Value := Value
                ; Perform chain reordering to speed up future lookups.
                if (PreviousItem != "")
                {
                    PreviousItem.Next   := Item.Next
                   ,Item.Next           := this._Buckets[Hash]
                   ,this._Buckets[Hash] := Item
                }
                Found := true
            }
            else
            {
                PreviousItem := Item
               ,Item         := Item.Next
            }
        }
        if (not Found)
        {
            Next                      := this._Buckets.HasKey(Hash) ? this._Buckets[Hash]
                                       : ""
           ,this._Buckets[Hash]       := {}
           ,this._Buckets[Hash].Key   := Key
           ,this._Buckets[Hash].Value := Value
           ,this._Buckets[Hash].Next  := Next
           ,this._Count               += 1
        }
        return Value
    }

    Delete(Key)
    {
        local
        Found        := false
       ,Hash         := this._GetHash(Key)
       ,Item         := this._Buckets.HasKey(Hash) ? this._Buckets[Hash]
                      : ""
       ,PreviousItem := ""
        while (not Found)
        {
            if (Item == "")
            {
                throw Exception("Key Error", -1
                               ,"HashTable.Delete(Key)  Key not found.")
            }
            if (Item.Key == Key)
            {
                Value := Item.Value
                if (PreviousItem == "")
                {
                    if (Item.Next == "")
                    {
                        this._Buckets.Delete(Hash)
                    }
                    else
                    {
                        this._Buckets[Hash] := Item.Next
                    }
                }
                else
                {
                    PreviousItem.Next := Item.Next
                }
                this._Count -= 1
               ,Found := true
            }
            else
            {
                PreviousItem := Item
               ,Item         := Item.Next
            }
        }
        return Value
    }

    Clone()
    {
        local
        global HashTable
        Clone := new HashTable()
        ; Avoid rehashing when cloning.
        for Hash, Item in this._Buckets
        {
            PreviousItemClone := ""
            while (Item != "")
            {
                ItemClone := Item.Clone()
                if (PreviousItemClone == "")
                {
                    Chain := ItemClone
                }
                else
                {
                    PreviousItemClone.Next := ItemClone
                }
                PreviousItemClone := ItemClone
               ,Item              := Item.Next
            }
            Clone._Buckets[Hash] := Chain
        }
        Clone._Count := this._Count
        return Clone
    }

    class Enumerator
    {
        __New(HashTable)
        {
            local
            this._BucketsEnum  := HashTable._Buckets._NewEnum()
           ,this._PreviousItem := ""
            return this
        }

        Next(byref Key, byref Value := "")
        {
            local
            if (this._PreviousItem == "" or this._PreviousItem.Next == "")
            {
                Result := this._BucketsEnum.Next(_, Item)
            }
            else
            {
                Item   := this._PreviousItem.Next
               ,Result := true
            }
            if (Result)
            {
                Key                := Item.Key
               ,Value              := Item.Value
               ,this._PreviousItem := Item
            }
            return Result
        }
    }

    _NewEnum()
    {
        local
        global HashTable
        return new HashTable.Enumerator(this)
    }
}
