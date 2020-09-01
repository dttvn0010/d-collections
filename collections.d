module collections;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import std.algorithm;
import std.typecons;
import std.algorithm.mutation : move;

//version = noboundcheck;

nothrow:

enum isCopyable(S) = is(typeof(() { S foo = S.init; S copy = foo; } ));

struct _RCListData(T) {
    T* _items;
    size_t _size;
    size_t _capacity;

    @disable this(this); // not copyable

    ~this() {
        if(_items) {
            printf("Free RCList\n");
            for(int i = 0; i < _size; i++) {
                destroy(_items[i]);
            }
            free(_items);
            _items = null;
            _size = _capacity = 0;
        }
    }
}

struct RCList(T) {
nothrow:    
    RefCounted!(_RCListData!T, RefCountedAutoInitialize.no) data;

    static RCList nullRCList() {
        RCList lst;
        return lst;
    }

    bool isInitialized() {
        return data.refCountedStore().isInitialized();
    }

    static RCList opCall(int sz) {
        RCList lst;
        auto data = _RCListData!T(null, 0, 0);
        lst.data = refCounted(move(data));

        lst.data._items = cast (T*) malloc(T.sizeof * sz);
        memset(cast(char*) lst.data._items, 0, T.sizeof * sz);
        lst.data._size = lst.data._capacity = sz;

        return lst;
    }

    static RCList opCall() {
        return opCall(0);
    }

    private void ensureCap(size_t new_capacity) {
        if(new_capacity < data._capacity) return;
        size_t capacity = data._capacity;
        while(capacity < new_capacity) {
            capacity += capacity/2 + 8; 
        }

        if(data._items == null) {
            data._items = cast (T*) malloc(T.sizeof * capacity);
            memset(cast(char*) data._items, 0, T.sizeof * capacity);
        }else {
            data._items = cast (T*) realloc(data._items, T.sizeof*capacity);
            memset(cast(char*) data._items + data._size * T.sizeof, 0, T.sizeof * (capacity - data._size));
        }
        data._capacity = capacity;
    }

    size_t size() {
        return data._items ? data._size : 0;
    }

    void resize(size_t size) {
        ensureCap(size);
        data._size = size;
    }

    static if(isCopyable!T) {        
        void add(T item) {
            ensureCap(1 + data._size);
            data._items[data._size] = item;
            data._size += 1;
        }

        void remove(int index) {
            if(index < data._size) {
                destroy(data._items[index]);
            }

            for(int i = index; i < data._size - 1; i++) {
                data._items[i] = data._items[i+1];
            }
            data._size -= 1;

        }
    }else {
        void add(T item) {
            ensureCap(1 + data._size);
            data._items[data._size] = move(item);
            data._size += 1;
        }    

        void remove(int index) {
            if(index < data._size) {
                destroy(data._items[index]);
            }

            for(int i = index; i < data._size - 1; i++) {
                data._items[i] = move(data._items[i+1]);
            }
            data._size -= 1;
        }
    }

    ref T opIndex(int i) {
        version(noboundcheck) {} else {
            if(cast(uint) i >= data._size) {
                printf("RCList index %d is out of range %d", cast(int) i, cast(int) data._size);
                exit(0);
            }
        }
        return data._items[i];
    }

    static if(isCopyable!T) {
        private static RCList _fromRaw(T* ptr, size_t size) {
            RCList lst;
            auto data = _RCListData!T(null, 0, 0);
            lst.data = refCounted(move(data));
            lst.data._items = ptr;
            lst.data._size = size;
            lst.data._capacity = size;
            return lst;
        }

        static RCList opCall(T[] items) {
            auto lst = RCList();
            lst.resize(items.length);

            for(int i = 0; i < items.length; i++) {
                lst.data._items[i] = items[i];
            }    

            return lst;
        }

        int find(T item) {
            for(int i = 0; i < data._size; i++) {
                if(data._items[i] == item) return i;
            }
            return -1;
        }

        RCList!int findAll(T item) {
            RCList!int lst = RCList!int();
            for(int i = 0; i < data._size; i++) {
                if(data._items[i] == item) lst.add(i);
            }
            return lst;
        }

        int rfind(T item) {
            for(int i = cast(int) (data._size-1); i >= 0; i--) {
                if(data._items[i] == item) return i;
            }
            return -1;
        }

        RCList opSlice(size_t start, size_t end) {
            if(start < 0) start = 0;
            if(end > data._size) end = data._size;

            if(end > start) {
                size_t size = end - start;
                T* ptr = cast(T*) malloc(T.sizeof * size);
                memcpy(cast(void*) ptr, cast(void*)data._items + T.sizeof*start,  T.sizeof*size);
                return _fromRaw(ptr, size);
            }

            return RCList();
        }

        RCList opIndex(int[] indexes) {
            auto lst = RCList();
            lst.resize(indexes.length);
            T[] tmp = lst._view();

            for(int i = 0; i < indexes.length; i++) {
                int index = indexes[i];
                version(noboundcheck) {} else {
                    if(cast(uint) index >= data._size) {
                        printf("RCList index %d is out of range %d", cast(int) index, cast(int) data._size);
                        exit(0);
                    }
                }
                tmp[i] = data._items[index];
            }

            return lst;
        }

        RCList opIndex(RCList!int indexes) {
            return opIndex(indexes._view());
        }

        RCList filter(bool delegate(ref T) nothrow func) {
            auto lst = RCList();
            for(int i = 0; i < data._size; i++) {
                if(func(data._items[i])) {
                    lst.add(data._items[i]);
                }
            }
            return lst;
        }

        RCList filter(bool delegate(T) nothrow func) {
            auto lst = RCList();
            for(int i = 0; i < data._size; i++) {
                if(func(data._items[i])) {
                    lst.add(data._items[i]);
                }
            }
            return lst;
        }

        RCList!U map(U)(U delegate(T) nothrow f) {
            auto lst = RCList!U();
            lst.resize(size());

            for(int i = 0; i < data._size; i++) 
            {
                lst.data._items[i] = f(data._items[i]);
            }

            return lst;
        }

        RCDict!(U, RCList!T) groupBy(U)(U delegate(ref T) nothrow f) {
            auto groups = RCDict!(U, RCList!T)();
            RCList null_lst;
            for(int i = 0; i < data._size; i++) {
                auto key = f(data._items[i]);
                auto group = groups.getOrDefault(key, null_lst);
                if(group.isInitialized()) {
                    groups[key].add(data._items[i]);
                }else {
                    groups[key] = RCList!T();
                }
            }
            return groups;
        }
    }

    T[] _view() {
        return data._items[0..data._size];
    }

    int opApply(int delegate(ref T) nothrow operations) {
        int result = 0;
        for(int i = 0; i < data._size; i++) {
            result = operations(data._items[i]);
            if(result) break;
        }
        return result;
    }

    int opApply(int delegate(size_t i, ref T) nothrow operations) {
        int result = 0;
        for(int i = 0; i < data._size; i++) {
            result = operations(i, data._items[i]);
            if(result) break;
        }
        return result;
    }

    int count(bool delegate(ref T) nothrow func) {
        int total = 0;
        for(int i = 0; i < data._size; i++) {
            if(func(data._items[i])) {
                total += 1;
            }
        }
        return total;
    }

    RCList!U map(U)(U delegate(ref T) nothrow f) {
        auto lst = RCList!U();
        lst.resize(size());

        for(int i = 0; i < data._size; i++) 
        {
            lst.data._items[i] = f(data._items[i]);
        }

        return lst;
    }

    void sort(alias lt= "a < b")() { 
        if(data && data._items) {
            _toRange().sort!lt();
        }
    }

    RCString toRCString() {
        auto result = RCString("[");
        char[1024] tmp;

        char* cptr = cast(char*) tmp;
        for(int i = 0; i < data._size; i++) 
        {        
            static if (is(typeof(data._items[0].toRCString()) == RCString)) {
                result += data._items[i].toRCString();
            }else {
                format!T(cptr, data._items[i]);
                int len = strlen(cptr);
                result += cast(string) tmp[0..len];
            }
            if(i + 1 < data._size) result += " , ";
        }
        result += "]";
        return result;
    }
}

struct DictItem(K,V) {
    K key;
    V value;
    DictItem* next;
}

DictItem!(K,V)* newItem(K,V)() {
    int allocSize = DictItem!(K,V).sizeof;
    auto ptr = cast(DictItem!(K,V)*) malloc(allocSize);
    memset(cast(char*) ptr, 0, allocSize);
    ptr.next = null;
    return ptr;
}

struct _RCDictData(K, V) {
nothrow:
    DictItem!(K,V)** table;
    int _bucketSize;
    int _size;    

    @disable this(this); // not copyable

    ~this() {
        if(table) {                
            printf("Free RCDict\n");
            for(int i = 0; i < _size; i++) {
                auto ptr = table[i];
                while(ptr != null) {
                    auto tmp = ptr;
                    ptr = ptr.next;
                    destroy(tmp.key);
                    destroy(tmp.value);
                    free(tmp);
                }
            }
            free(table);
        }
        table = null;
        _bucketSize = _size = 0;
    }
}

public struct RCDict(K, V) {
nothrow:

    RefCounted!(_RCDictData!(K,V), RefCountedAutoInitialize.no) data;

    bool isInitialized() {
        return data.refCountedStore().isInitialized();
    }

    static RCDict opCall() {
        RCDict dict;
        auto data = _RCDictData!(K,V)(null, 0, 0);
        dict.data = refCounted(move(data));
        dict.data._size = 0;
        dict.data._bucketSize = 16;
        size_t allocSize = (DictItem!(K,V)*).sizeof * dict.data._bucketSize;
        dict.data.table = cast(DictItem!(K,V)**) malloc(allocSize);
        memset(cast(char*) dict.data.table, 0, allocSize);
        return dict;
    }

    void opIndexAssign(V value, K key) {

        if(data._size >= data._bucketSize >> 1) {
            _doubleSize();
        }

        size_t hash = key.hashOf();
        size_t index = hash % data._bucketSize;

        auto ptr = data.table[index];

        while(ptr && ptr.next && ptr.key != key) {
            ptr = ptr.next;
        }

        if(ptr && ptr.key == key) {
            static if(isCopyable!V) {
                ptr.value = value;            
            }else {
                ptr.value = move(value);
            }
        }else {    
            auto new_ptr = newItem!(K,V)();
            new_ptr.key = key;

            static if(isCopyable!V) {
                new_ptr.value = value;
            }else {
                new_ptr.value = move(value);
            }

            data._size += 1;

            if(ptr) {
                ptr.next = new_ptr;
            }else {
                data.table[index] = new_ptr;
            }
        }
    }

    ref V opIndex(K key) {
        size_t hash = key.hashOf();
        size_t index = hash % data._bucketSize;        
        auto ptr = data.table[index];

        while(ptr != null && ptr.key != key) {
            ptr = ptr.next;
        }

        if(!ptr) {
            printf("Fatal error: RCDict key not found \n");
            exit(0);
        }

        return ptr.value;
    }

    bool containsKey(K key) {
        size_t hash = key.hashOf();
        size_t index = hash % data._bucketSize;        
        auto ptr = data.table[index];

        while(ptr != null && ptr.key != key) {
            ptr = ptr.next;
        }
        return ptr != null;
    }

    void remove(K key) {
        size_t hash = key.hashOf();
        size_t index = hash % data._bucketSize;
        bool result;

        if(data.table[index] == null) return;

        auto ptr = data.table[index];
        DictItem!(K,V)* prev = null;

        while(ptr.next != null && ptr.key != key) {
            prev = ptr;
            ptr = ptr.next;
        }

        if(ptr.key == key) {
            if(prev != null) {
                prev.next = ptr.next;
            }else {
                data.table[index] = ptr.next;
            }
            destroy(ptr.key);
            destroy(ptr.value);
            free(ptr);
            data._size -= 1;

        }
    }

    private void _doubleSize() {        
        int itemSize = (DictItem!(K,V)*).sizeof;
        data.table = cast(DictItem!(K,V)**) realloc(data.table, 2 * itemSize * data._bucketSize);    
        memset(cast (char*) data.table + data._bucketSize * itemSize, 0, data._bucketSize * itemSize);

        for(int i = 0; i < data._bucketSize; i++) {
            auto ptr = data.table[i];
            DictItem!(K,V)* prev = null;
            DictItem!(K,V)* new_ptr = null;

            while(ptr != null) {
                size_t hash = ptr.key.hashOf();                
                size_t index = hash % (2* data._bucketSize);
                auto next = ptr.next;

                if(index == i + data._bucketSize) {
                    if(new_ptr == null) {
                        data.table[index] = new_ptr = newItem!(K,V)();                        
                    }else {
                        new_ptr.next = newItem!(K,V)();
                        new_ptr = new_ptr.next;
                    }

                    new_ptr.key = ptr.key;
                    new_ptr.value = move(ptr.value);

                    if(prev == null) {
                        data.table[i] = next;
                    }else {
                        prev.next = next;
                    }

                    destroy(ptr.key);
                    free(ptr);
                }else {
                    prev = ptr;
                }

                ptr = next;
            }
        }
        data._bucketSize *= 2;
    }

    RCList!K getKeys() {
        auto lst = RCList!K();
        for(int i = 0; i < data._bucketSize;i++) {
            auto ptr = data.table[i];
            while(ptr != null) {
                lst.add(ptr.key);
                ptr = ptr.next;
            }
        }
        return lst;
    }

    static if(isCopyable!V) {
        RCList!V getValues() {
            auto lst = RCList!V();
            for(int i = 0; i < data._bucketSize;i++) {
                auto ptr = data.table[i];
                while(ptr != null) {
                    lst.add(ptr.value);
                    ptr = ptr.next;
                }
            }
            return lst;
        }

        RCList!(DictItem!(K,V)) getItems() {
            auto lst = RCList!(DictItem!(K,V))();
            for(int i = 0; i < data._bucketSize;i++) {
                auto ptr = data.table[i];
                while(ptr != null) {
                    lst.add(*ptr);
                    ptr = ptr.next;
                }
            }
            return lst;
        }


        V getOrDefault(K key, V defaultValue) {
            size_t hash = key.hashOf();
            size_t index = hash % data._bucketSize;        
            auto ptr = data.table[index];

            while(ptr != null && ptr.key != key) {
                ptr = ptr.next;
            }
            return ptr? ptr.value : defaultValue;
        }

        V getOrInsert(K key, V defaultValue) {
            size_t hash = key.hashOf();
            size_t index = hash % data._bucketSize;        
            auto ptr = data.table[index];

            while(ptr && ptr.key != key && ptr.next != null) {
                ptr = ptr.next;
            }

            if(ptr && ptr.key == key) {
                return ptr.value;
            }else {            
                auto new_ptr = newItem!(K,V)();
                new_ptr.key = key;
                new_ptr.value = defaultValue;
                data._size += 1;

                if(ptr) {
                    ptr.next = new_ptr;
                }else{
                    data.table[index] = new_ptr;
                }

                data._size += 1;
                return defaultValue;
            }
        }
    }

    int opApply(int delegate(ref DictItem!(K,V)) nothrow operations) {
        int result = 0;

        for(int i = 0; i < data._bucketSize;i++) {
            auto ptr = data.table[i];
            while(ptr != null) {
                result = operations(*ptr);
                ptr = ptr.next;
            }
        }

        return result;
    }

    RCString toRCString() {
        auto result = RCString("{");
        int count = 0;
        char[1024] tmp;
        char* cptr = cast(char*) tmp;
        int len;

        for(int i = 0; i < data._bucketSize;i++) {
            auto ptr = data.table[i];
            while(ptr != null) {
                static if (is(typeof(ptr.key.toRCString()) == RCString)) {
                    result += ptr.key.toRCString();
                }else {
                    format!K(cptr, ptr.key);
                    len = strlen(cptr);
                    result += cast(string) tmp[0..len];
                }

                result += ":";

                static if (is(typeof(ptr.value.toRCString()) == RCString)) {
                    result += ptr.value.toRCString();
                }else {
                    format!V(cptr, ptr.value);
                    len = strlen(cptr);
                    result += cast(string) tmp[0..len];
                }

                if(count + 1 < data._size) result += " , ";    
                count += 1;
                ptr = ptr.next;
            }
        }

        result += "}";
        return result;
    }
}

struct RCSetItem(T) {
    T value;
    RCSetItem* next;
}

RCSetItem!(T)* newRCSetItem(T)(T value) {
    int allocSize = RCSetItem!(T).sizeof;
    auto ptr = cast(RCSetItem!(T)*) malloc(allocSize);
    memset(cast(char*) ptr, 0, allocSize);
    ptr.value = value;
    ptr.next = null;
    return ptr;
}

struct _RCSetData(T) {
nothrow:
    RCSetItem!(T)** table;
    int _bucketSize;
    int _size;    

    @disable this(this); // not copyable

    ~this() {
        if(table) {                
            printf("Free RCSet\n");
            for(int i = 0; i < _size; i++) {
                auto ptr = table[i];
                while(ptr != null) {
                    auto tmp = ptr;
                    ptr = ptr.next;
                    destroy(tmp.value);
                    free(tmp);
                }
            }
            free(table);
        }
        table = null;
        _bucketSize = _size = 0;
    }
}


public struct RCSet(T) {
nothrow:
    RefCounted!(_RCSetData!(T), RefCountedAutoInitialize.no) data;

    bool isInitialized() {
        return data.refCountedStore().isInitialized();
    }

    static RCSet opCall() {
        RCSet set;
        auto data = _RCSetData!(T)(null, 0, 0);
        set.data = refCounted(move(data));
        set.data._size = 0;
        set.data._bucketSize = 16;
        size_t allocSize = (RCSetItem!(T)*).sizeof * set.data._bucketSize;
        set.data.table = cast(RCSetItem!(T)**) malloc(allocSize);
        memset(cast(char*) set.data.table, 0, allocSize);
        return set;
    }

    static RCSet opCall(T[] arr) {
        auto set = RCSet();
        foreach(x; arr) {
            set.add(x);
        }
        return set;
    }

    static RCSet opCall(RCList!T lst) {
        auto set = RCSet();
        foreach(x; lst) {
            set.add(x);
        }
        return set;
    }

    void add(T value) {

        if(data._size >= data._bucketSize >> 1) {
            _doubleSize();
        }

        size_t hash = value.hashOf();
        size_t index = hash % data._bucketSize;

        auto ptr = data.table[index];

        while(ptr && ptr.next && ptr.value != value) {
            ptr = ptr.next;
        }

        if(!ptr || ptr.value != value) {
            auto new_ptr = newRCSetItem(value);
            data._size += 1;
            if(ptr) {
                ptr.next = new_ptr;
            }else {
                data.table[index] = new_ptr;
            }
        }

    }

    bool contains(T value) {
        size_t hash = value.hashOf();
        size_t index = hash % data._bucketSize;        
        auto ptr = data.table[index];

        while(ptr != null && ptr.value != value) {
            ptr = ptr.next;
        }
        return ptr != null;
    }

    void remove(T value) {
        size_t hash = value.hashOf();
        size_t index = hash % data._bucketSize;
        bool result;

        if(data.table[index] == null) return;

        auto ptr = data.table[index];
        RCSetItem!(T)* prev = null;

        while(ptr.next != null && ptr.value != value) {
            prev = ptr;
            ptr = ptr.next;
        }

        if(ptr.value == value) {
            if(prev != null) {
                prev.next = ptr.next;
            }else {
                data.table[index] = ptr.next;
            }
            destroy(ptr.value);
            free(ptr);
            data._size -= 1;

        }
    }

    private void _doubleSize() {        
        size_t itemSize = (RCSetItem!(T)*).sizeof;
        data.table = cast(RCSetItem!(T)**) realloc(data.table, 2 * itemSize * data._bucketSize);    
        memset(cast (char*) data.table + data._bucketSize * itemSize, 0, data._bucketSize * itemSize);

        for(int i = 0; i < data._bucketSize; i++) {
            auto ptr = data.table[i];
            RCSetItem!(T)* prev = null;
            RCSetItem!(T)* new_ptr = null;

            while(ptr != null) {
                size_t hash = ptr.value.hashOf();                
                size_t index = hash % (2* data._bucketSize);
                auto next = ptr.next;

                if(index == i + data._bucketSize) {
                    if(new_ptr == null) {
                        data.table[index] = new_ptr = newRCSetItem(ptr.value);
                    }else {
                        new_ptr.next = newRCSetItem(ptr.value);
                        new_ptr = new_ptr.next;                        
                    }

                    if(prev == null) {
                        data.table[i] = next;
                    }else {
                        prev.next = next;
                    }

                    destroy(ptr.value);
                    free(ptr);                    
                }else {
                    prev = ptr;
                }

                ptr = next;
            }
        }
        data._bucketSize *= 2;
    }

    RCList!T toList() {
        auto lst = RCList!T();
        for(int i = 0; i < data._size;i++) {
            auto ptr = data.table[i];
            while(ptr != null) {
                lst.add(ptr.value);
                ptr = ptr.next;
            }
        }
        return lst;
    }

    int opApply(int delegate(ref T) nothrow operations) {
        int result = 0;

        for(int i = 0; i < data._bucketSize;i++) {
            auto ptr = data.table[i];
            while(ptr != null) {
                result = operations(ptr.value);
                ptr = ptr.next;
            }
        }

        return result;
    }

    RCString toRCString() {
        char[1024] tmp;
        auto result = RCString("{");
        int count = 0;
        char* cptr = cast(char*) tmp;

        for(int i = 0; i < data._bucketSize;i++) {
            auto ptr = data.table[i];
            while(ptr != null) {
                static if (is(typeof(ptr.value.toRCString()) == RCString)) {
                    result += ptr.value.toRCString();
                }else {
                    format!T(cptr, ptr.value);
                    int len = strlen(cptr);
                    result += cast(string) tmp[0..len];
                }
                if(count + 1 < data._size) result += " , ";
                count += 1;
                ptr = ptr.next;
            }
        }

        result += "}";
        return result;
    }
}

struct _RCStringData{
nothrow:
    char* ptr;
    int _length;
    int _capacity;

    @disable this(this); // not copyable

    ~this() {
        if(ptr) {
            free(ptr);
            ptr = null;
        }
    }
}

struct RCString {
nothrow:
    RefCounted!(_RCStringData, RefCountedAutoInitialize.no) data;

    bool isInitialized() {
        return data.refCountedStore().isInitialized();
    }

    static RCString emptyRCString() {
        RCString result;
        auto data = _RCStringData(null, 0, 0);
        result.data = refCounted(move(data));
        return result;
    }

    static RCString opCall() {
        auto result = emptyRCString();
        result.data.ptr = cast(char*) malloc(1);
        result.data.ptr[0] = 0;
        result.data._length = 0;
        result.data._capacity = 1;
        return result;
    }

    void ensureCap(size_t new_capacity) {
        if(new_capacity <= data._capacity) return;

        size_t capacity = data._capacity;

        while(capacity < new_capacity) {
            capacity += capacity/2 + 8; 
        }
        if(!data.ptr) {
            data.ptr = cast(char*) malloc(capacity);
            memset(data.ptr, 0, capacity);
        }else {
            data.ptr = cast(char*) realloc(data.ptr, capacity);
            memset(data.ptr + data._length, 0, capacity - data._length);
        }
    }

    static RCString opCall(string st) {
        auto result = emptyRCString();
        int len = st.length;
        result.data.ptr = cast(char*) malloc(len+1);
        strncpy(result.data.ptr, &st[0], len);
        result.data.ptr[len] = 0;
        result.data._length = len;
        return result;
    }

    void opAssign(string rhs) {
        int len = rhs.length;
        ensureCap(len + 1);
        strncpy(data.ptr, &rhs[0], len);
        data.ptr[len] = 0;
        data._length = len;
    }

    int length() {
        return data._length;
    }

    RCString opBinary(string op)(RCString rhs)
    {
        static if (op == "+") {
            auto result = emptyRCString();
            int len1 = data.length;
            int len2 = rhs.data.length;
            result.data.ptr = cast(char*) malloc(len1 + len2 + 1);
            strncpy(result.data.ptr, data.ptr, len1);
            strncpy(result.data.ptr + len1, rhs.data.ptr, len2);
            result.data.ptr[len1+len2] = 0;
            result.data.length = len1+len2;
            return result;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    RCString opBinary(string op)(string rhs)
    {
        static if (op == "+") {
            auto result = emptyRCString();
            int len1 = data._length;
            int len2 = rhs.length;
            result.data.ptr = cast(char*) malloc(len1 + len2 + 1);
            strncpy(result.data.ptr, data.ptr, len1);
            strncpy(result.data.ptr + len1, &rhs[0], len2);
            result.data.ptr[len1+len2] = 0;
            result.data._length = len1+len2;
            return result;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    RCString opBinary(string op, T)(T rhs)
    {
        char[1024] tmp;
        char* cptr = cast(char*) tmp;
        format!T(cptr, rhs);

        static if (op == "+") {
            auto result = emptyRCString();
            int len1 = data._length;
            int len2 = strlen(cptr);
            result.data.ptr = cast(char*) malloc(len1 + len2 + 1);
            strncpy(result.data.ptr, data.ptr, len1);
            strncpy(result.data.ptr + len1, cptr, len2);
            result.data.ptr[len1+len2] = 0;
            result.data._length = len1+len2;
            return result;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    void opOpAssign(string op)(string rhs) {
        static if (op == "+") {
            int len1 = data._length;
            int len2 = rhs.length;
            ensureCap(len1 + len2 + 1);
            strncpy(data.ptr + len1, &rhs[0], len2);
            data.ptr[len1+len2] = 0;
            data._length = len1 + len2;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    void opOpAssign(string op)(RCString rhs) {
        static if (op == "+") {
            int len1 = data._length;
            int len2 = rhs.length;
            ensureCap(len1 + len2 + 1);
            strncpy(data.ptr + len1, rhs.data.ptr, len2);
            data.ptr[len1+len2] = 0;
            data._length = len1 + len2;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    void opOpAssign(string op, T)(T rhs) {
        char [1024] tmp;
        char* cptr = cast(char*) tmp;
        format!T(cptr, rhs);

        static if (op == "+") {
            int len1 = data._length;
            int len2 = strlen(cptr);
            ensureCap(len1 + len2 + 1);
            strncpy(data.ptr + len1, cptr, len2);
            data.ptr[len1+len2] = 0;
            data._length = len1 + len2;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    RCString subString(int start, int end) {
        if(start < 0) start = 0;
        if(end > data._length) end = data._length;
        if(start > end) end = start;
        int len = end - start;

        auto result = emptyRCString();
        result.data.ptr = cast(char*) malloc(len + 1);
        strncpy(result.data.ptr, data.ptr + start, len);
        result.data.ptr[len] = 0;
        result.data._length = len;
        return result;
    }

    private int indexOf(const char* ptr) {
        char* pos = strstr(data.ptr, ptr);
        if(pos) {
            return pos - ptr;
        }
        return -1;
    }

    int indexOf(string st) {
        const char* ptr = &st[0];
        return indexOf(ptr);

    }

    int indexOf(RCString st) {
        return indexOf(st.data.ptr);
    }

    private RCList!RCString split(const char* delimiter) {
        auto lst = RCList!RCString();
        int delimiter_len = strlen(delimiter);
        char *ptr = data.ptr;
        char *pos;

        while (true)
        {
            pos = strstr(ptr, delimiter);
            if(!pos) break;

            int len = pos - ptr;
            if (len > 0) {
                lst.add(RCString(cast (string) (ptr[0..len])));
            }
            ptr = pos + delimiter_len;
        }

        if (ptr  < data.ptr + data._length){
            int len = data.ptr + data._length - ptr;
            lst.add(RCString(cast (string) (ptr[0..len])));
        }

        return lst;
    }

    RCList!RCString split(string st) {
        return split(&st[0]);
    }

    RCList!RCString split(RCString st) {
        return split(st.data.ptr);
    }

    RCString join(RCList!RCString lst) {
        int totalLength = 0;

        foreach(i,st; lst) {
            totalLength += st.data._length;
            if(i + 1 < lst.size()) {
                totalLength += data._length;
            }
        }

        auto result = emptyRCString();
        result.data.ptr = cast(char*) malloc(totalLength + 1);

        char* ptr = result.data.ptr;

        foreach(i,st; lst) {
            memcpy(ptr, st.data.ptr, st.data._length);
            ptr += st.data._length;

            if(i + 1 < lst.size()) {
                memcpy(ptr, data.ptr, data._length);
                ptr += data._length;
            }            
        }

        ptr[0] = 0;
        result.data._length = totalLength;
        return result;
    }

    hash_t toHash() const nothrow {
        return hashOf(cast(string)data.ptr[0..data._length]);
    }

    bool opEquals(RCString st2){        
        auto s1 = cast(string) data.ptr[0..data._length];
        auto s2 = cast(string) st2.data.ptr[0..st2.data._length];
        return s1 == s2;
    }

    void print() {
        printf("%s", data.ptr);
    }

    void printLine() {
        printf("%s\n", data.ptr);
    }
}

void format(T)(char* ptr, ref T x) {
    static if(is(T == int) || is(T == short) || is (T == byte)) {
        sprintf(ptr, "%d", cast (int) x);
        return;

    }else static if(is(T == uint) || is(T == ushort) || is (T == ubyte)) {
        sprintf(ptr, "%u", cast (uint) x);
        return;

    }else static if(is(T == long)) {
        sprintf(ptr, "%ld", x);
        return;

    }else static if(is(T == ulong)) {
        sprintf(ptr, "%lu", x);
        return;

    }else static if(is(T == float)) {
        sprintf(ptr, "%f", x);
        return;

    }else static if(is(T == double)) {
        sprintf(ptr, "%lf", x);
        return;
    }

    printf("Data type not supported.\n");
    exit(0);
}
