module collections;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import std.algorithm;
import std.typecons;
import std.algorithm.mutation : move;

//version = noboundcheck;

nothrow:

struct _ArrayData(T) {
	T* items;
	size_t _size;

	@disable this(this); // not copyable

	~this() {
		if(items) free(items);
	}
}

struct Array(T) {
nothrow:
	RefCounted!(_ArrayData!T, RefCountedAutoInitialize.no) data;

	this(size_t sz) {
		auto tmp = _ArrayData!T(null, 0);
		data = refCounted(move(tmp));		
	}

	size_t size() {
		return data._size;
	}

	ref T opIndex(int i) {
		version(noboundcheck) {} else {
			if(cast(uint) i >= data._size) {
				printf("Fatal error: list index %d is out of range %d", cast(int) i, cast(int) data._size);
				exit(0);
			}
		}
		return data.items[i];
	}

	T opIndexAssign(T val, int i) {
		version(noboundcheck) {} else {
			if(cast(uint) i >= data._size) {
				printf("Falta error: list index %d is out of range %d", cast(int) i, cast(int) data._size);
				exit(0);
			}
		}

		data.items[i] = val;
		return val;
	}

	// Use for debug only
	private T[] _view() {
		return data.items[0..data._size];
	}

	Array opSlice(size_t start, size_t end) {
		if(start < 0) start = 0;
		if(end > data._size) end = data._size;

		if(end <= start) {
			return Array!T(0);
		}

		size_t size = end - start;
		auto arr = Array!T(size);

		memcpy(cast(void*) arr.data.items, cast(void*)data.items + T.sizeof * start,  T.sizeof * size);

		return arr;
	}

	Array!T opIndex(int[] indexes) {
		auto arr = Array!T(indexes.length);
		T[] tmp = arr._view();
		for(int i = 0; i < indexes.length; i++) {
			int index = indexes[i];
			if(cast(uint) index >= data._size) {
				printf("Fatal error: list index %d is out of range %d", cast(int) index, cast(int) data._size);
				exit(0);
			}
			tmp[i] = data.items[index];
		}
		return arr;
	}

	Array!T opIndex(Array!int indexes) {
		return opIndex(indexes._view());
	}

	Array!T opIndex(List!int indexes) {
		return opIndex(indexes._view());
	}

	int opApply(int delegate(ref T) nothrow operations) {
		int result = 0;
		T[] items  = _view();
		for(int i = 0; i < data._size; i++) {
			result = operations(items[i]);
			if(result) break;
		}
		return result;
	}

	int opApply(int delegate(size_t i, ref T) nothrow operations) {
		int result = 0;
		T[] items  = _view();
		for(int i = 0; i < data._size; i++) {
			result = operations(i, items[i]);
			if(result) break;
		}
		return result;
	}

	List!T toList() {
		auto lst = List!T();
		lst._setSize(data._size);
		memcpy(cast(void*) lst.data.items, cast(void*)data.items,  T.sizeof * data._size);
		return lst;
	}

	Array!U map(U)(U delegate(ref T) nothrow f) {
		auto arr = Array!(U)(data._size);
		for(int i = 0; i < data._size; i++) 
		{
			arr.data.items[i] = f(data.items[i]);
		}
		return arr;
	}

	Array!U map(U)(U delegate(T) nothrow f) {
		auto arr = Array!(U)(data._size);
		for(int i = 0; i < data._size; i++) 
		{
			arr.data.items[i] = f(data.items[i]);
		}
		return arr;
	}

	void sort(alias lt= "a < b")() { 
		if(data) {
			_toRange().sort!lt();
		}
	}

	/*
	nothrow Array!int argsort(alias lt= "a < b")() {

		auto arr = Array!int(data._size);

		makeIndex!lt(_toRange(), arr._toRange());

		return arr;
	}*/
}

struct _ListData(T) {
	T* items;
	size_t _size;
	size_t _capacity;

	@disable this(this); // not copyable

	~this() {
		if(items) {
			printf("Free list\n");
			for(int i = 0; i < _size; i++) {
				destroy(items[i]);
			}
			free(items);
			items = null;
			_size = _capacity = 0;
		}
	}
}

struct List(T) {
nothrow:	
	RefCounted!(_ListData!T, RefCountedAutoInitialize.no) data;

	static List opCall() {
		List lst;
		auto data = _ListData!T(null, 0, 0);
		lst.data = refCounted(move(data));
		
		lst.data.items = null;
		lst.data._size = 0;
		lst.data._capacity = 0;
		return lst;
	}

	static List opCall(T[] arr) {
		auto lst = List();
		lst._setSize(arr.length);
		
		for(int i = 0; i < arr.length; i++) {
			lst.data.items[i] = arr[i];
		}	
		
		return lst;
	}

	private static List _fromRaw(T* ptr, size_t size) {
		List lst;
		auto data = _ListData!T(null, 0, 0);
		lst.data = refCounted(move(data));
		lst.data.items = ptr;
		lst.data._size = size;
		lst.data._capacity = size;
		return lst;
	}
	
	private void _expand(size_t new_capacity) {
		if(new_capacity < data._capacity) return;
		size_t capacity = data._capacity;
		while(capacity < new_capacity) {
			capacity += capacity/2 + 8; 
		}

		if(data.items == null) {
			data.items = cast (T*) malloc(T.sizeof * capacity);
			memset(cast(char*) data.items, 0, T.sizeof * capacity);
		}else {
			data.items = cast (T*) realloc(data.items, T.sizeof*capacity);
			memset(cast(char*) data.items + data._size * T.sizeof, 0, T.sizeof * (capacity - data._size));
		}
		data._capacity = capacity;
	}

	size_t size() {
		return data.items ? data._size : 0;
	}

	private void _setSize(size_t size) {
		_expand(size);
		data._size = size;
	}

	void add(T item) {
		_expand(1 + data._size);
		data.items[data._size] = item;
		data._size += 1;
	}

	void remove(int index) {
		for(int i = index; i < data._size - 1; i++) {
			data.items[i] = data.items[i+1];
		}
		data._size -= 1;
	}

	int find(T item) {
		for(int i = 0; i < data._size; i++) {
			if(data.items[i] == item) return i;
		}
		return -1;
	}

	Array!int findAll(T item) {
		List!int lst = List!int();
		for(int i = 0; i < data._size; i++) {
			if(data.items[i] == item) lst.add(i);
		}
		return lst.toArray();
	}

	int rfind(T item) {
		for(int i = cast(int) (data._size-1); i >= 0; i--) {
			if(data.items[i] == item) return i;
		}
		return -1;
	}

	List opSlice(size_t start, size_t end) {
		if(start < 0) start = 0;
		if(end > data._size) end = data._size;

		if(end > start) {
			size_t size = end - start;
			T* ptr = cast(T*) malloc(T.sizeof * size);
			memcpy(cast(void*) ptr, cast(void*)data.items + T.sizeof*start,  T.sizeof*size);
			return _fromRaw(ptr, size);
		}

		return List();
	}

	List opIndex(int[] indexes) {
		auto lst = List();
		lst._setSize(indexes.length);
		T[] tmp = lst._view();

		for(int i = 0; i < indexes.length; i++) {
			int index = indexes[i];
			version(noboundcheck) {} else {
				if(cast(uint) index >= data._size) {
					printf("Fatal error: list index %d is out of range %d", cast(int) index, cast(int) data._size);
					exit(0);
				}
			}
			tmp[i] = data.items[index];
		}

		return lst;
	}

	List opIndex(Array!int indexes) {
		return opIndex(indexes._view());
	}

	List opIndex(List!int indexes) {
		return opIndex(indexes._view());
	}

	T at(int i) {
		auto items = data.items;
		return items[0];
	}

	ref T opIndex(int i) {
		version(noboundcheck) {} else {
			if(cast(uint) i >= data._size) {
				printf("List index %d is out of range %d", cast(int) i, cast(int) data._size);
				exit(0);
			}
		}
		return data.items[i];
	}

	T opIndexAssign(T val, int i) {
		version(noboundcheck) {} else {
			if(cast(uint) i >= data._size) {
				printf("List index %d is out of range %d", cast(int) i, cast(int) data._size);
				exit(0);
			}
		}

		data.items[i] = val;
		return val;
	}

	T[] _view() {
		return data.items[0..data._size];
	}

	Array!T toArray() {
		auto arr = Array!T(data._size);
		memcpy(cast(void*) arr.data.items, cast(void*)data.items,  T.sizeof*data._size);
		return arr;
	}
	
	int opApply(int delegate(ref T) nothrow operations) {
		int result = 0;
		T[] items  = _view();
		for(int i = 0; i < data._size; i++) {
			result = operations(items[i]);
			if(result) break;
		}
		return result;
	}

	int opApply(int delegate(size_t i, ref T) nothrow operations) {
		int result = 0;
		T[] items  = _view();
		for(int i = 0; i < data._size; i++) {
			result = operations(i, items[i]);
			if(result) break;
		}
		return result;
	}

	int count(bool delegate(T) nothrow func) {
		int total = 0;
		for(int i = 0; i < data._size; i++) {
			if(func(data.items[i])) {
				total += 1;
			}
		}
		return total;
	}

	List filter(bool delegate(T) nothrow func) {
		auto lst = List();
		for(int i = 0; i < data._size; i++) {
			if(func(data.items[i])) {
				lst.add(data.items[i]);
			}
		}
		return lst;
	}

	List!U map(U)(U delegate(ref T) nothrow f) {
		auto lst = List!U();
		lst._setSize(size());

		for(int i = 0; i < data._size; i++) 
		{
			lst.data.items[i] = f(data.items[i]);
		}

		return lst;
	}

	List!U map(U)(U delegate(T) nothrow f) {
		auto lst = List!U();
		lst._setSize(size());

		for(int i = 0; i < data._size; i++) 
		{
			lst.data.items[i] = f(data.items[i]);
		}

		return lst;
	}

	HashMap!(U, List!T) groupBy(U)(U delegate(ref T) nothrow f) {
		auto groups = HashMap!(U, List!T)();
		for(int i = 0; i < data._size; i++) {
			auto key = f(data.items[i]);
			auto group = groups.getOrDefault(key, List!T());
			if(group.size() == 0) {
				groups[key] = group;
			}
			group.add(data.items[i]);
 		}
		return groups;
	}

	void sort(alias lt= "a < b")() { 
		if(data && data.items) {
			_toRange().sort!lt();
		}
	}
}

struct Entry(K,V) {
	K key;
	V value;
	Entry* next;
}

Entry!(K,V)* newEntry(K,V)(K key, V value) {
	int allocSize = Entry!(K,V).sizeof;
	auto ptr = cast(Entry!(K,V)*) malloc(allocSize);
	memset(cast(char*) ptr, 0, allocSize);
	ptr.key = key;
	ptr.value = value;
	ptr.next = null;
	return ptr;
}

struct _HashMapData(K, V) {
nothrow:
	Entry!(K,V)** table;
	int _bucketSize;
	int _size;	

	@disable this(this); // not copyable

	~this() {
		if(table) {				
			printf("Free hashmap\n");
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

struct HashMapView(K,V) {
	nothrow:
	Entry!(K,V)[] items;
	private Entry!(K,V)* ptr;

	this(int N) {
		ptr = cast(Entry!(K,V)*) malloc(N * Entry!(K,V).sizeof);
		memset(cast(char*) ptr, 0, N * Entry!(K,V).sizeof);
		items = ptr[0..N];
	}

	~this() {
		if(ptr) {
			for(int i = 0; i < items.length; i++) {
				destroy(items[i].key);
				destroy(items[i].value);
			}
			free(ptr);
		}
	}
}

public struct HashMap(K, V) {
nothrow:
	RefCounted!(_HashMapData!(K,V), RefCountedAutoInitialize.no) data;

	static HashMap opCall() {
		HashMap map;
		auto data = _HashMapData!(K,V)(null, 0, 0);
		map.data = refCounted(move(data));
		map.data._size = 0;
		map.data._bucketSize = 16;
		size_t allocSize = (Entry!(K,V)*).sizeof * map.data._bucketSize;
		map.data.table = cast(Entry!(K,V)**) malloc(allocSize);
		memset(cast(char*) map.data.table, 0, allocSize);
		return map;
	}

	void opIndexAssign(V value, K key) {

		if(data._size >= data._bucketSize >> 1) {
			_doubleSize();
		}

		size_t hash = key.hashOf();
		size_t index = hash % data._bucketSize;

		if(data.table[index] == null) {			
			data.table[index] = newEntry(key, value);
			data._size += 1;
			return;
		}

		auto ptr = data.table[index];

		while(ptr.next != null && ptr.key != key) {
			ptr = ptr.next;
		}

		if(ptr.key == key) {
			ptr.value = value;			
		}else {			
			ptr.next = newEntry(key, value);	
			data._size += 1;
		}
	}

	V opIndex(K key) {
		size_t hash = key.hashOf();
		size_t index = hash % data._bucketSize;		
		auto ptr = data.table[index];

		while(ptr != null && ptr.key != key) {
			ptr = ptr.next;
		}

		if(!ptr) {
			printf("Fatal error: Hashmap key not found \n");
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

	V getOrDefault(K key, V defaultValue) {
		size_t hash = key.hashOf();
		size_t index = hash % data._bucketSize;		
		auto ptr = data.table[index];

		while(ptr != null && ptr.key != key) {
			ptr = ptr.next;
		}
		return ptr? ptr.value : defaultValue;
	}

	void remove(K key) {
		size_t hash = key.hashOf();
		size_t index = hash % data._bucketSize;
		bool result;

		if(data.table[index] == null) return;

		auto ptr = data.table[index];
		Entry!(K,V)* prev = null;

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
		int itemSize = (Entry!(K,V)*).sizeof;
		data.table = cast(Entry!(K,V)**) realloc(data.table, 2 * itemSize * data._bucketSize);	
		memset(cast (char*) data.table + data._bucketSize * itemSize, 0, data._bucketSize * itemSize);

		for(int i = 0; i < data._bucketSize; i++) {
			auto ptr = data.table[i];
			Entry!(K,V)* prev = null;
			Entry!(K,V)* new_ptr = null;

			while(ptr != null) {
				size_t hash = ptr.key.hashOf();				
				size_t index = hash % (2* data._bucketSize);
				auto next = ptr.next;

				if(index == i + data._bucketSize) {
					if(new_ptr == null) {
						data.table[index] = new_ptr = newEntry(ptr.key, ptr.value);
					}else {
						new_ptr.next = newEntry(ptr.key, ptr.value);
						new_ptr = new_ptr.next;						
					}

					if(prev == null) {
						data.table[i] = next;
					}else {
						prev.next = next;
					}
					
					destroy(ptr.key);
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

	List!K getKeys() {
		auto lst = List!K();
		for(int i = 0; i < data._size;i++) {
			auto ptr = data.table[i];
			while(ptr != null) {
				lst.add(ptr.key);
				ptr = ptr.next;
			}
		}
		return lst;
	}

	List!V getValues() {
		auto lst = List!V();
		for(int i = 0; i < data._size;i++) {
			auto ptr = data.table[i];
			while(ptr != null) {
				lst.add(ptr.value);
				ptr = ptr.next;
			}
		}
		return lst;
	}

	List!(Entry!(K,V)) getEntries() {
		auto lst = List!(Entry!(K,V))();
		for(int i = 0; i < data._bucketSize;i++) {
			auto ptr = data.table[i];
			while(ptr != null) {
				lst.add(*ptr);
				ptr = ptr.next;
			}
		}
		return lst;
	}

	// Use for debug only
	private HashMapView!(K,V) _view() {		
		auto v = HashMapView!(K, V)(data._size);
		int index = 0;
		for(int i = 0; i < data._bucketSize;i++) {
			auto ptr = data.table[i];
			while(ptr != null) {
				v.items[index] = (*ptr);
				ptr = ptr.next;
				index += 1;
				if(index >= data._size)break;
			}
		}
		return v;
	}

	int opApply(int delegate(ref Entry!(K,V)) nothrow operations) {
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
}

struct SetEntry(T) {
	T value;
	SetEntry* next;
}

SetEntry!(T)* newSetEntry(T)(T value) {
	int allocSize = SetEntry!(T).sizeof;
	auto ptr = cast(SetEntry!(T)*) malloc(allocSize);
	memset(cast(char*) ptr, 0, allocSize);
	ptr.value = value;
	ptr.next = null;
	return ptr;
}

struct _HashSetData(T) {
nothrow:
	SetEntry!(T)** table;
	int _bucketSize;
	int _size;	

	@disable this(this); // not copyable

	~this() {
		if(table) {				
			printf("Free hashset\n");
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

struct HashSetView(T) {
nothrow:
	SetEntry!(T)[] items;
	private SetEntry!(T)* ptr;

	this(int N) {
		ptr = cast(SetEntry!(T)*) malloc(N * SetEntry!(T).sizeof);
		memset(cast(char*) ptr, 0, N * SetEntry!(T).sizeof);
		items = ptr[0..N];
	}

	~this() {
		if(ptr) {			
			for(int i = 0; i < items.length; i++) {
				destroy(items[i].value);
			}
			free(ptr);
		}
	}
}

public struct HashSet(T) {
nothrow:
	RefCounted!(_HashSetData!(T), RefCountedAutoInitialize.no) data;

	static HashSet opCall() {
		HashSet set;
		auto data = _HashSetData!(T)(null, 0, 0);
		set.data = refCounted(move(data));
		set.data._size = 0;
		set.data._bucketSize = 16;
		size_t allocSize = (SetEntry!(T)*).sizeof * set.data._bucketSize;
		set.data.table = cast(SetEntry!(T)**) malloc(allocSize);
		memset(cast(char*) set.data.table, 0, allocSize);
		return set;
	}
	
	static HashSet opCall(T[] arr) {
		auto set = HashSet();
		foreach(x; arr) {
			set.add(x);
		}
		return set;
	}

	static HashSet opCall(List!T lst) {
		auto set = HashSet();
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

		if(data.table[index] == null) {			
			data.table[index] = newSetEntry(value);
			data._size += 1;
			return;
		}

		auto ptr = data.table[index];

		while(ptr.next != null && ptr.value != value) {
			ptr = ptr.next;
		}

		if(ptr.value != value) {
			ptr.next = newSetEntry(value);	
			data._size += 1;
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
		SetEntry!(T)* prev = null;

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
		size_t itemSize = (SetEntry!(T)*).sizeof;
		data.table = cast(SetEntry!(T)**) realloc(data.table, 2 * itemSize * data._bucketSize);	
		memset(cast (char*) data.table + data._bucketSize * itemSize, 0, data._bucketSize * itemSize);

		for(int i = 0; i < data._bucketSize; i++) {
			auto ptr = data.table[i];
			SetEntry!(T)* prev = null;
			SetEntry!(T)* new_ptr = null;

			while(ptr != null) {
				size_t hash = ptr.value.hashOf();				
				size_t index = hash % (2* data._bucketSize);
				auto next = ptr.next;

				if(index == i + data._bucketSize) {
					if(new_ptr == null) {
						data.table[index] = new_ptr = newSetEntry(ptr.value);
					}else {
						new_ptr.next = newSetEntry(ptr.value);
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

	List!T toList() {
		auto lst = List!T();
		for(int i = 0; i < data._size;i++) {
			auto ptr = data.table[i];
			while(ptr != null) {
				lst.add(ptr.value);
				ptr = ptr.next;
			}
		}
		return lst;
	}

	// Use for debug only
	private HashSetView!(T) _view() {		
		auto v = HashSetView!(T)(data._size);
		int index = 0;
		for(int i = 0; i < data._bucketSize;i++) {
			auto ptr = data.table[i];
			while(ptr != null) {
				v.items[index] = (*ptr);
				ptr = ptr.next;
				index += 1;
				if(index >= data._size)break;
			}
		}
		return v;
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
}