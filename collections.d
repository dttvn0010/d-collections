module RC;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import std.algorithm;
import std.typecons;
import std.algorithm.mutation : move;
import std.traits: isCopyable, isOrderingComparable;

//version = noboundcheck;

nothrow:

private struct _StringData{
nothrow:
    char* _ptr;
    size_t _length;
    size_t _capacity;

    @disable this(this); // not copyable

    ~this() {
        if(_ptr) {
            //printf("Free String\n");
            free(_ptr);
            _ptr = null;
        }
    }
}

struct String {
nothrow:
    private RefCounted!(_StringData, RefCountedAutoInitialize.no) _data;

    bool isInitialized() {
        return _data.refCountedStore().isInitialized();
    }

    private static String _emptyString() {
        String result;
        auto data = _StringData(null, 0, 0);
        result._data = refCounted(move(data));
        return result;
    }

    static String opCall() {
        auto result = _emptyString();
        result._data._ptr = cast(char*) malloc(1);
        result._data._ptr[0] = 0;
        result._data._length = 0;
        result._data._capacity = 1;
        return result;
    }

    private void _ensureCap(size_t new_capacity) {
        if(new_capacity <= _data._capacity) return;

        size_t capacity = _data._capacity;

        while(capacity < new_capacity) {
            capacity += capacity/2 + 8; 
        }
        if(!_data._ptr) {
            _data._ptr = cast(char*) malloc(capacity);
            memset(_data._ptr, 0, capacity);
        }else {
            _data._ptr = cast(char*) realloc(_data._ptr, capacity);
            memset(_data._ptr + _data._length, 0, capacity - _data._length);
        }
    }

    static String opCall(string st) {
        auto result = _emptyString();
        size_t len = st.length;
        result._data._ptr = cast(char*) malloc(len+1);
        if(len > 0) strncpy(result._data._ptr, &st[0], len);
        result._data._ptr[len] = 0;
        result._data._length = len;
        return result;
    }

    void opAssign(string rhs) {
        size_t len = rhs.length;
        _ensureCap(len + 1);
        if(len > 0) strncpy(_data._ptr, &rhs[0], len);
        _data._ptr[len] = 0;
        _data._length = len;
    }

    size_t length() {
        return _data._length;
    }

    String opBinary(string op)(String rhs)
    {
        static if (op == "+") {
            auto result = _emptyString();
            int len1 = _data._length;
            int len2 = rhs._data._length;
            result._data._ptr = cast(char*) malloc(len1 + len2 + 1);
            if(len1 > 0) strncpy(result._data._ptr, _data._ptr, len1);
            if(len2 > 0) strncpy(result._data._ptr + len1, rhs._data._ptr, len2);
            result._data._ptr[len1+len2] = 0;
            result._data._length = len1+len2;
            return result;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    String opBinary(string op)(string rhs)
    {
        static if (op == "+") {
            auto result = _emptyString();
            size_t len1 = _data._length;
            size_t len2 = rhs.length;
            result._data._ptr = cast(char*) malloc(len1 + len2 + 1);
            if(len1 > 0) strncpy(result._data._ptr, _data._ptr, len1);
            if(len2 > 0) strncpy(result._data._ptr + len1, &rhs[0], len2);
            result._data._ptr[len1+len2] = 0;
            result._data._length = len1+len2;
            return result;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    String opBinary(string op, T)(T rhs)
    {
        static if (op == "+") {
            static if(is(typeof(rhs) == String)) {
                return opBinary!op(rhs);
            }else static if (is(typeof(rhs.toString()) == String)) {
                return opBinary!op(rhs.toString());
            }else {
                auto result = String("[");
                char[1024] tmp;
                char* cptr = cast(char*) tmp;
                format!T(cptr, rhs);

                size_t len1 = _data._length;
                size_t len2 = strlen(cptr);
                
                result._data._ptr = cast(char*) malloc(len1 + len2 + 1);
                if(len1 > 0) strncpy(result._data._ptr, _data._ptr, len1);
                if(len2 > 0) strncpy(result._data._ptr + len1, cptr, len2);
                result._data._ptr[len1+len2] = 0;
                result._data._length = len1+len2;
                return result;
            }
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    void opOpAssign(string op)(string rhs) {
        static if (op == "+") {
            size_t len1 = _data._length;
            size_t len2 = rhs.length;
            _ensureCap(len1 + len2 + 1);
            if(len2 > 0) strncpy(_data._ptr + len1, &rhs[0], len2);
            _data._ptr[len1+len2] = 0;
            _data._length = len1 + len2;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    void opOpAssign(string op)(String rhs) {
        static if (op == "+") {
            size_t len1 = _data._length;
            size_t len2 = rhs.length;
            _ensureCap(len1 + len2 + 1);
            if(len2 > 0) strncpy(_data._ptr + len1, rhs._data._ptr, len2);
            _data._ptr[len1+len2] = 0;
            _data._length = len1 + len2;
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    void opOpAssign(string op, T)(T rhs) {
        
        static if (op == "+") {
            static if(is(typeof(rhs) == String)) {
                opOpAssign!op(rhs);
            }else static if (is(typeof(rhs.toString()) == String)) {
                opOpAssign!op(rhs.toString());
            }else {
                char [1024] tmp;
                char* cptr = cast(char*) tmp;
                format!T(cptr, rhs);

                int len1 = _data._length;
                int len2 = strlen(cptr);
                _ensureCap(len1 + len2 + 1);
                if(len2 > 0) strncpy(_data._ptr + len1, cptr, len2);
                _data._ptr[len1+len2] = 0;
                _data._length = len1 + len2;
            }
        }

        else static assert(0, "Operator "~op~" not implemented");
    }

    String subString(size_t start, size_t end) {
        if(start < 0) start = 0;
        if(end > _data._length) end = _data._length;
        if(start > end) end = start;
        int len = cast(int) (end - start);

        auto result = _emptyString();
        result._data._ptr = cast(char*) malloc(len + 1);
        if(len > 0) strncpy(result._data._ptr, _data._ptr + start, len);
        result._data._ptr[len] = 0;
        result._data._length = len;
        return result;
    }

    String subString(int start) {
        return subString(start, _data._length);
    }

    private int indexOf(const char* ptr) {
        char* pos = strstr(_data._ptr, ptr);
        if(pos) {
            return cast(int)(pos - _data._ptr);
        }
        return -1;
    }

    int indexOf(string st) {
        const char* ptr = &st[0];
        return indexOf(ptr);
    }

    int indexOf(String st) {
        return indexOf(st._data._ptr);
    }
    
    private List!String _split(const char* delimiter) {
        auto lst = List!String();
        size_t delimiter_len = strlen(delimiter);
        char *ptr = _data._ptr;
        char *pos;

        while (true)
        {
            pos = strstr(ptr, delimiter);
            if(!pos) break;

            int len = cast(int)(pos - ptr);
            if (len > 0) {
                lst.add(String(cast (string) (ptr[0..len])));
            }
            ptr = pos + delimiter_len;
        }

        if (ptr  < _data._ptr + _data._length){
            int len = cast(int)(_data._ptr + _data._length - ptr);
            lst.add(String(cast (string) (ptr[0..len])));
        }

        return lst;
    }

    List!String split(string st) {
        return _split(&st[0]);
    }

    List!String split(String st) {
        return _split(st._data._ptr);
    }

    String join(List!String lst) {
        int totalLength = 0;

        foreach(i,st; lst) {
            totalLength += st._data._length;
            if(i + 1 < lst.size()) {
                totalLength += _data._length;
            }
        }

        auto result = _emptyString();
        result._data._ptr = cast(char*) malloc(totalLength + 1);

        char* ptr = result._data._ptr;

        foreach(i,st; lst) {
            memcpy(ptr, st._data._ptr, st._data._length);
            ptr += st._data._length;

            if(i + 1 < lst.size()) {
                memcpy(ptr, _data._ptr, _data._length);
                ptr += _data._length;
            }            
        }

        ptr[0] = 0;
        result._data._length = totalLength;
        return result;
    }

    hash_t toHash() const nothrow {
        return hashOf(cast(string)_data._ptr[0.._data._length]);
    }

    bool opEquals(String st2){        
        auto s1 = cast(string) _data._ptr[0.._data._length];
        auto s2 = cast(string) st2._data._ptr[0..st2._data._length];
        return s1 == s2;
    }

    bool opEquals(string st2){        
        auto s1 = cast(string) _data._ptr[0.._data._length];
        return s1 == st2;
    }

    void print() {
        printf("%s", _data._ptr);
    }

    void printLine() {
        printf("%s\n", _data._ptr);
    }

    unittest {
        auto items = String("1,2,3,4").split(",");        
        assert(String("-").join(items) == "1-2-3-4");
        auto st = String("Hello world");
        assert(st.indexOf("123") == -1);
        assert(st.indexOf("world") == 6);
        assert(st.subString(6, 8) == "wo");
        assert(st.subString(6) == "world");
    }
}

private struct _ListData(T) {
    T* _items;
    size_t _size;
    size_t _capacity;

    @disable this(this); // not copyable

    ~this() {
        if(_items) {
            //printf("Free List\n");
            for(int i = 0; i < _size; i++) {
                static if(!is(typeof(_items[0]) == String)) {
                    destroy(_items[i]);
                }else {
                    destroy(_items[i]._data);
                }
            }
            free(_items);
            _items = null;
            _size = _capacity = 0;
        }
    }
}

struct List(T) {
nothrow:    
    private RefCounted!(_ListData!T, RefCountedAutoInitialize.no) _data;
    
    @disable hash_t toHash();

    bool isInitialized() {
        return _data.refCountedStore().isInitialized();
    }

    static List opCall(size_t sz) {
        List lst;
        auto data = _ListData!T(null, 0, 0);
        lst._data = refCounted(move(data));

        lst._data._items = cast (T*) malloc(T.sizeof * sz);

        //memset(cast(char*) lst._data._items, 0, T.sizeof * sz);

        for(size_t i = 0; i < sz; i++) {
            lst._data._items[i] = T();
        }

        lst._data._size = lst._data._capacity = sz;

        return lst;
    }

    static List opCall() {
        return opCall(0);
    }

    private void _ensureCap(size_t new_capacity) {
        if(new_capacity < _data._capacity) return;
        size_t capacity = _data._capacity;
        while(capacity < new_capacity) {
            capacity += capacity/2 + 8; 
        }

        if(_data._items == null) {
            _data._items = cast (T*) malloc(T.sizeof * capacity);
            memset(cast(char*) _data._items, 0, T.sizeof * capacity);
        }else {
            _data._items = cast (T*) realloc(_data._items, T.sizeof*capacity);
            memset(cast(char*) _data._items + _data._size * T.sizeof, 0, T.sizeof * (capacity - _data._size));
        }
        _data._capacity = capacity;
    }

    size_t size() {
        return _data._size;
    }

    void resize(size_t size) {
        _ensureCap(size);
        if(size > _data._size) {
            for(size_t i = _data._size; i < size; i++) {
                _data._items[i] = T();
            }
        }
        _data._size = size;
    }

    static if(isCopyable!T) {        
        void add(T item) {
            _ensureCap(1 + _data._size);
            _data._items[_data._size] = item;
            _data._size += 1;
        }

        void remove(int index) {
            if(cast(uint) index >= _data._size) {
                printf("List index %d is out of range %d", cast(int) index, cast(int) _data._size);
                exit(0);
            }
            
            destroy(_data._items[index]);

            for(int i = index; i < _data._size - 1; i++) {
                _data._items[i] = _data._items[i+1];
            }
            _data._size -= 1;

        }
    }else {
        void add(T item) {
            _ensureCap(1 + _data._size);
            _data._items[_data._size] = move(item);
            _data._size += 1;
        }    

        void remove(int index) {
            if(cast(uint) index >= _data._size) {
                printf("List index %d is out of range %d", cast(int) index, cast(int) _data._size);
                exit(0);
            }
            
            destroy(_data._items[index]);

            for(int i = index; i < _data._size - 1; i++) {
                _data._items[i] = move(_data._items[i+1]);
            }
            _data._size -= 1;
        }
    }

    ref T opIndex(int i) {
        version(noboundcheck) {} else {
            if(cast(uint) i >= _data._size) {
                printf("List index %d is out of range %d", cast(int) i, cast(int) _data._size);
                exit(0);
            }
        }
        return _data._items[i];
    }

    static if(isCopyable!T) {
        private static List _fromRaw(T* ptr, size_t size) {
            List lst;
            auto data = _ListData!T(null, 0, 0);
            lst._data = refCounted(move(data));
            lst._data._items = ptr;
            lst._data._size = size;
            lst._data._capacity = size;
            return lst;
        }

        static List opCall(T[] items) {
            auto lst = List();
            lst.resize(items.length);

            for(int i = 0; i < items.length; i++) {
                lst._data._items[i] = items[i];
            }    

            return lst;
        }

        int find(T item) {
            for(int i = 0; i < _data._size; i++) {
                if(_data._items[i] == item) return i;
            }
            return -1;
        }

        List!int findAll(T item) {
            List!int lst = List!int();
            for(int i = 0; i < _data._size; i++) {
                if(_data._items[i] == item) lst.add(i);
            }
            return lst;
        }

        int rfind(T item) {
            for(int i = cast(int) (_data._size-1); i >= 0; i--) {
                if(_data._items[i] == item) return i;
            }
            return -1;
        }

        List opSlice(size_t start, size_t end) {
            if(start < 0) start = 0;
            if(end > _data._size) end = _data._size;

            if(end > start) {
                size_t size = end - start;
                T* ptr = cast(T*) malloc(T.sizeof * size);
                memcpy(cast(void*) ptr, cast(void*)_data._items + T.sizeof*start,  T.sizeof*size);
                return _fromRaw(ptr, size);
            }

            return List();
        }

        List opIndex(int[] indexes) {
            auto lst = List();
            lst.resize(indexes.length);
            T[] tmp = lst._view();

            for(int i = 0; i < indexes.length; i++) {
                int index = indexes[i];
                version(noboundcheck) {} else {
                    if(cast(uint) index >= _data._size) {
                        printf("List index %d is out of range %d", cast(int) index, cast(int) _data._size);
                        exit(0);
                    }
                }
                tmp[i] = _data._items[index];
            }

            return lst;
        }

        List opIndex(List!int indexes) {
            return opIndex(indexes._view());
        }

        List filter(bool delegate(ref T) nothrow func) {
            auto lst = List();
            for(int i = 0; i < _data._size; i++) {
                if(func(_data._items[i])) {
                    lst.add(_data._items[i]);
                }
            }
            return lst;
        }

        List filter(bool delegate(T) nothrow func) {
            auto lst = List();
            for(int i = 0; i < _data._size; i++) {
                if(func(_data._items[i])) {
                    lst.add(_data._items[i]);
                }
            }
            return lst;
        }

        List!U map(U)(U delegate(T) nothrow f) {
            auto lst = List!U();
            lst.resize(size());

            for(int i = 0; i < _data._size; i++) 
            {
                lst._data._items[i] = f(_data._items[i]);
            }

            return lst;
        }

        Dict!(U, List!T) groupBy(U)(U delegate(ref T) nothrow f) {
            auto groups = Dict!(U, List!T)();
            List null_lst;
            for(int i = 0; i < _data._size; i++) {
                auto key = f(_data._items[i]);
                auto group = groups.getOrDefault(key, null_lst);
                if(!group.isInitialized()) {
                    group = List!T();
                    groups[key] = group;
                }
                group.add(_data._items[i]);
            }
            return groups;
        }

        Dict!(U, List!T) groupBy(U)(U delegate(T) nothrow f) {
            auto groups = Dict!(U, List!T)();
            List null_lst;
            for(int i = 0; i < _data._size; i++) {
                auto key = f(_data._items[i]);
                auto group = groups.getOrDefault(key, null_lst);
                if(!group.isInitialized()) {
                    group = List!T();
                    groups[key] = group;
                }
                group.add(_data._items[i]);
            }
            return groups;
        }

        T reduce(T delegate(T, T) nothrow f, T init=T.init) {
            T acc = init;
            for(int i = 0; i < _data._size; i++) {
                acc = f(acc, _data._items[i]);
            }
            return acc;
        }
    }

    private T[] _view() {
        return _data._items[0.._data._size];
    }

    int opApply(int delegate(ref T) nothrow operations) {
        int result = 0;
        for(int i = 0; i < _data._size; i++) {
            result = operations(_data._items[i]);
            if(result) break;
        }
        return result;
    }

    int opApply(int delegate(size_t i, ref T) nothrow operations) {
        int result = 0;
        for(int i = 0; i < _data._size; i++) {
            result = operations(i, _data._items[i]);
            if(result) break;
        }
        return result;
    }

    int count(bool delegate(ref T) nothrow func) {
        int total = 0;
        for(int i = 0; i < _data._size; i++) {
            if(func(_data._items[i])) {
                total += 1;
            }
        }
        return total;
    }

    List!U map(U)(U delegate(ref T) nothrow f) {
        auto lst = List!U();
        lst.resize(size());

        for(int i = 0; i < _data._size; i++) 
        {
            lst._data._items[i] = f(_data._items[i]);
        }

        return lst;
    }


    static if(isOrderingComparable!T) {

        void sort(alias lt= "a < b")() { 
            _view().sort!lt();
        }

        private void _swap(int* indexes, int i, int j) {
            int tmp = indexes[i];
            indexes[i] = indexes[j];
            indexes[j] = tmp;  
        }

        private int _partition(int* indexes, T* values, bool delegate(T, T) nothrow lt_func, int low, int high) {  
            int pivot = values[indexes[high]];
            int i = (low - 1);
          
            for (int j = low; j <= high - 1; j++) {
                bool lt = lt_func != null? lt_func(values[indexes[j]], pivot) : (values[indexes[j]] < pivot);

                if (lt) {  
                    i++;
                    _swap(indexes, i, j);               
                }  
            }  
            _swap(indexes, i + 1, high);
            return (i + 1);  
        }  

        private void _qsort(int* indexes, T* values, bool delegate(T, T) nothrow lt_func, int low, int high) {
            if(low < high) {
                int pi = _partition(indexes, values, lt_func, low, high); 
                _qsort(indexes, values, lt_func, low, pi - 1);  
                _qsort(indexes, values, lt_func, pi + 1, high);  
            }
        }

        List!int argsort(bool delegate(T, T) nothrow lt_func=null) { 
            auto indexes = List!int(_data._size);

            auto indexes_ptr = indexes._data._items;

            for(int i = 0; i < _data._size; i++) {
                indexes_ptr[i] = i;
            }

            _qsort(indexes_ptr, _data._items, lt_func, 0, cast(int)(_data._size - 1));

            return indexes;
        }
    }

    String toString() {
        auto result = String("[");
        char[1024] tmp;

        char* cptr = cast(char*) tmp;
        for(int i = 0; i < _data._size; i++) 
        {        
            static if(is(typeof(_data._items[0]) == String)) {
                result += "'";
                result += _data._items[i] + "'";
            }else static if (is(typeof(_data._items[0].toString()) == String)) {
                result += _data._items[i].toString();
            }else {
                format!T(cptr, _data._items[i]);
                size_t len = strlen(cptr);
                result += cast(string) tmp[0..len];
            }
            if(i + 1 < _data._size) result += ", ";
        }
        result += "]";
        return result;
    }
}

unittest {    

    int[5] arr = [2,3,1,5,0];
    auto lst = List!int(arr);    

    auto indexes = lst.argsort();
    assert(indexes[0] == 4 && indexes[1] == 2 && indexes[2] == 0 && indexes[3] == 1 && indexes[4] == 3);

    lst.sort();
    assert(lst[0] == 0 && lst[1] == 1 && lst[2] == 2 && lst[3] == 3 && lst[4] == 5);

    auto sum = lst.reduce((x, y) => x + y);
    assert(sum == 11);

    lst = lst.filter(x => x > 1).map(x => x*x);
    auto llst = List!(List!int)();
    llst.add(lst);

    foreach(ref x; llst[0]) {
        x += 1;
    }

    foreach(i, x; llst[0]) {
        if(i == 0) assert(x == 5);
        if(i == 1) assert(x == 10);
        if(i == 2) assert(x == 26);
    }
}

unittest {
    auto arr = List!int();
    for(int i = 0; i < 100; i++) {
        arr.add(i);
    }
    auto groups = arr.groupBy(x => x%4);
    foreach(entry; groups) {        
        auto key = entry.key;
        auto value = entry.value;

        if(key == 0) {
            assert(value[0] == 0);
            assert(value[1] == 4);
            assert(value[23] == 92);
            assert(value[24] == 96);
        }
        if(key == 1) {
            assert(value[0] == 1);
            assert(value[1] == 5);
            assert(value[23] == 93);
            assert(value[24] == 97);
        }
        if(key == 2) {
            assert(value[0] == 2);
            assert(value[1] == 6);
            assert(value[23] == 94);
            assert(value[24] == 98);
        }
        if(key == 3) {
            assert(value[0] == 3);
            assert(value[1] == 7);
            assert(value[23] == 95);
            assert(value[24] == 99);
        }        
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

private struct _DictData(K, V) {
nothrow:
    DictItem!(K,V)** _table;
    size_t _bucketSize;
    size_t _size;    

    @disable this(this); // not copyable

    ~this() {
        if(_table) {                
            //printf("Free Dict\n");
            for(int i = 0; i < _bucketSize; i++) {
                auto ptr = _table[i];
                while(ptr != null) {
                    auto tmp = ptr;
                    ptr = ptr.next;
                    destroy(tmp.key);
                    destroy(tmp.value);
                    free(tmp);
                }
            }
            free(_table);
        }
        _table = null;
        _bucketSize = _size = 0;
    }
}

public struct Dict(K, V) {
nothrow:

    private RefCounted!(_DictData!(K,V), RefCountedAutoInitialize.no) _data;

    @disable hash_t toHash();
    
    bool isInitialized() {
        return _data.refCountedStore().isInitialized();
    }

    static Dict opCall() {
        Dict dict;
        auto data = _DictData!(K,V)(null, 0, 0);
        dict._data = refCounted(move(data));
        dict._data._size = 0;
        dict._data._bucketSize = 16;
        size_t allocSize = (DictItem!(K,V)*).sizeof * dict._data._bucketSize;
        dict._data._table = cast(DictItem!(K,V)**) malloc(allocSize);
        memset(cast(char*) dict._data._table, 0, allocSize);
        return dict;
    }

    void opIndexAssign(V value, K key) {

        if(_data._size >= _data._bucketSize >> 1) {
            _doubleSize();
        }

        size_t hash = key.hashOf();
        size_t index = hash % _data._bucketSize;

        auto ptr = _data._table[index];

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

            _data._size += 1;

            if(ptr) {
                ptr.next = new_ptr;
            }else {
                _data._table[index] = new_ptr;
            }
        }
    }
    
    private void _printKeyNotFoundError(K)(K key) {
        char[1024] tmp;
        char* cptr = cast(char*) tmp;
        
        printf("Dict key not found error: ");
        
        static if(is(typeof(key) == String)) {
            key.print();
        }
        else static if (is(typeof(key.toString()) == String)) {
            key.toString().print();
        }else {
            format!K(cptr, key);
            printf("%s", cptr);
        }
        printf("\n");
    }

    ref V opIndex(K key) {
        size_t hash = key.hashOf();
        size_t index = hash % _data._bucketSize;        
        auto ptr = _data._table[index];

        while(ptr != null && ptr.key != key) {
            ptr = ptr.next;
        }

        if(!ptr) {
            _printKeyNotFoundError!K(key);
            exit(0);
        }

        return ptr.value;
    }

    bool containsKey(K key) {
        size_t hash = key.hashOf();
        size_t index = hash % _data._bucketSize;        
        auto ptr = _data._table[index];

        while(ptr != null && ptr.key != key) {
            ptr = ptr.next;
        }
        return ptr != null;
    }
    
    void remove(K key) {
        
        size_t hash = key.hashOf();
        size_t index = hash % _data._bucketSize;
        bool result;
        
        if(_data._table[index] == null) return;
        
        auto ptr = _data._table[index];
        DictItem!(K,V)* prev = null;

        while(ptr.next != null && ptr.key != key) {
            prev = ptr;
            ptr = ptr.next;
        }

        if(ptr.key == key) {
            if(prev != null) {
                prev.next = ptr.next;
            }else {
                _data._table[index] = ptr.next;
            }
            destroy(ptr.key);
            destroy(ptr.value);
            free(ptr);
            _data._size -= 1;
        }
    }

    private void _doubleSize() {        
        int itemSize = (DictItem!(K,V)*).sizeof;
        _data._table = cast(DictItem!(K,V)**) realloc(_data._table, 2 * itemSize * _data._bucketSize);    
        memset(cast (char*) _data._table + _data._bucketSize * itemSize, 0, _data._bucketSize * itemSize);

        for(int i = 0; i < _data._bucketSize; i++) {
            auto ptr = _data._table[i];
            DictItem!(K,V)* prev = null;
            DictItem!(K,V)* new_ptr = null;

            while(ptr != null) {
                size_t hash = ptr.key.hashOf();                
                size_t index = hash % (2* _data._bucketSize);
                auto next = ptr.next;

                if(index == i + _data._bucketSize) {
                    if(new_ptr == null) {
                        _data._table[index] = new_ptr = newItem!(K,V)();                        
                    }else {
                        new_ptr.next = newItem!(K,V)();
                        new_ptr = new_ptr.next;
                    }

                    new_ptr.key = ptr.key;
                    static if(isCopyable!V) {
                        new_ptr.value = ptr.value;
                    }else{
                        new_ptr.value = move(ptr.value);
                    }

                    if(prev == null) {
                        _data._table[i] = next;
                    }else {
                        prev.next = next;
                    }

                    destroy(ptr.key);
                    static if(isCopyable!V) {
                        destroy(ptr.value);
                    }
                    free(ptr);
                }else {
                    prev = ptr;
                }

                ptr = next;
            }
        }
        _data._bucketSize *= 2;
    }

    List!K getKeys() {
        auto lst = List!K();
        for(int i = 0; i < _data._bucketSize;i++) {
            auto ptr = _data._table[i];
            while(ptr != null) {
                lst.add(ptr.key);
                ptr = ptr.next;
            }
        }
        return lst;
    }

    static if(isCopyable!V) {
        List!V getValues() {
            auto lst = List!V();
            for(int i = 0; i < _data._bucketSize;i++) {
                auto ptr = _data._table[i];
                while(ptr != null) {
                    lst.add(ptr.value);
                    ptr = ptr.next;
                }
            }
            return lst;
        }

        List!(DictItem!(K,V)) getItems() {
            auto lst = List!(DictItem!(K,V))();
            for(int i = 0; i < _data._bucketSize;i++) {
                auto ptr = _data._table[i];
                while(ptr != null) {
                    lst.add(*ptr);
                    ptr = ptr.next;
                }
            }
            return lst;
        }


        V getOrDefault(K key, V defaultValue) {
            size_t hash = key.hashOf();
            size_t index = hash % _data._bucketSize;        
            auto ptr = _data._table[index];

            while(ptr != null && ptr.key != key) {
                ptr = ptr.next;
            }
            return ptr? ptr.value : defaultValue;
        }

        V getOrInsert(K key, V defaultValue) {
            size_t hash = key.hashOf();
            size_t index = hash % _data._bucketSize;        
            auto ptr = _data._table[index];

            while(ptr && ptr.key != key && ptr.next != null) {
                ptr = ptr.next;
            }

            if(ptr && ptr.key == key) {
                return ptr.value;
            }else {            
                auto new_ptr = newItem!(K,V)();
                new_ptr.key = key;
                new_ptr.value = defaultValue;

                if(ptr) {
                    ptr.next = new_ptr;
                }else{
                    _data._table[index] = new_ptr;
                }

                _data._size += 1;
                return defaultValue;
            }
        }
    }

    int opApply(int delegate(ref DictItem!(K,V)) nothrow operations) {
        int result = 0;

        for(int i = 0; i < _data._bucketSize;i++) {
            auto ptr = _data._table[i];
            while(ptr != null) {
                result = operations(*ptr);
                ptr = ptr.next;
            }
        }

        return result;
    }

    size_t size() {
        return _data._size;
    }

    String toString() {
        auto result = String("{");
        int count = 0;
        char[1024] tmp;
        char* cptr = cast(char*) tmp;
        size_t len;

        for(int i = 0; i < _data._bucketSize;i++) {
            auto ptr = _data._table[i];
            while(ptr != null) {
                static if(is(typeof(ptr.key) == String)) {
                    result += "'";
                    result += ptr.key;
                    result += "'";
                }
                else static if (is(typeof(ptr.key.toString()) == String)) {
                    result += ptr.key.toString();
                }else {
                    format!K(cptr, ptr.key);
                    len = strlen(cptr);
                    result += cast(string) tmp[0..len];
                }

                result += ": ";

                static if(is(typeof(ptr.value) == String)) {
                    result += "'";
                    result += ptr.value;
                    result += "'";
                }
                else static if (is(typeof(ptr.value.toString()) == String)) {
                    result += ptr.value.toString();
                }else {
                    format!V(cptr, ptr.value);
                    len = strlen(cptr);
                    result += cast(string) tmp[0..len];
                }

                if(count + 1 < _data._size) result += ", ";    
                count += 1;
                ptr = ptr.next;
            }
        }

        result += "}";
        return result;
    }
}

unittest {
    auto m = Dict!(int, int)();
    for(int i = 50; i < 70; i++) {
        m[2*i] = i;
    }
    m[256] = 128;
    assert(m[100] == 50 && m[110] == 55 && m[120] == 60 && m[128] == 64 && m[256] == 128);
}

unittest {
    auto m = Dict!(String, int)();    
    m[String("12")] = 100;
    auto s = String("1");
    assert(m[s + "2"] == 100);
}

public struct Set(T) {
nothrow:
    private Dict!(T, int) _dict;
   
    @disable hash_t toHash();

    bool isInitialized() {
        return _dict.isInitialized();
    }

    static Set opCall() {
        Set set;
        set._dict = Dict!(T, int)();
        return set;
    }

    static Set opCall(T[] arr) {
        auto set = Set();
        foreach(x; arr) {
            set._dict[x] = 1;
        }
        return set;
    }

    static Set opCall(List!T lst) {
        auto set = Set();
        foreach(x; lst) {
            set._dict[x] = 1;
        }
        return set;
    }

    void add(T value) {
        _dict[value] = 1;
    }

    bool contains(T value) {
        return _dict.containsKey(value);
    }
    
    void remove(T value) {
        _dict.remove(value);
    }

    List!T toList() {
        return _dict.getKeys();
    }

    int opApply(int delegate(ref T) nothrow operations) {
        int result = 0;

        foreach(ref item; _dict) {
            result = operations(item.key);
        }

        return result;
    }

    size_t size() {
        return _dict.size();
    }

    String toString() {
        char[1024] tmp;
        auto result = String("{");
        int count = 0;
        char* cptr = cast(char*) tmp;
        auto sz = size();

        foreach(ref item; _dict) {
            static if(is(typeof(item.key) == String)) {
                result += "'";
                result += item.key;
                result += "'";
            }else static if (is(typeof(item.key.toString()) == String)) {
                result += item.key.toString();
            }else {
                format!T(cptr, item.key);
                size_t len = strlen(cptr);
                result += cast(string) tmp[0..len];
            }
            if(count + 1 < sz) result += ", ";
            count += 1;
        }

        result += "}";
        return result;
    }
}

unittest {
    int[5] arr = [1, 5, 6, 7, 8];
    auto s = Set!int(arr);
    s.add(1);
    s.add(2);
    s.add(3);
    s.add(2);
    s.add(1);
    assert(s.size() == 7);
    assert(s.contains(1) && s.contains(2) && s.contains(3) && s.contains(5) 
                        && s.contains(6) && s.contains(7) && s.contains(8));
    assert(!s.contains(4));
}

private void format(T)(char* ptr, ref T x) {
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

    sprintf(ptr, "[Object]");
}
