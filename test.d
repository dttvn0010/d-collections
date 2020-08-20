import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import collections;

void testHashMap1() {
	auto m = HashMap!(int, int)();
	for(int i = 50; i < 70; i++) {
		m[2*i] = i;
	}
	auto entries = m.getEntries();
	
	foreach(entry; m) {
		printf("%d --> %d\n", entry.key, entry.value);
	}
	printf("%d\n", m[100]);
}

void testHashMap() {
	auto m = HashMap!(string, int)();
	char[256] s;
	sprintf(&s[0], "%d%d", 1, 2);
	string st = cast(string) s[0..2];
	if(st == "12")printf("true\n");
	m[st] = 1;
	//printf("%d\n", m["12"]);
}


void testList() {
	auto lst = List!int();	
	lst.add(2);
	lst.add(3);
	lst.add(1);
	lst.add(5);
	lst.add(0);
	//lst.sort();
	
	lst = lst.filter(x => x > 1).map(x => x*x);
	printf("%d\n", lst.at(0));
	auto llst = List!(List!int)();
	llst.add(lst);
	
	foreach(ref x; llst[0]) {
		x += 1;
	}

	foreach(i, x; llst[0]) {
		printf("lst[%d] = %d\n", cast(int) i, x);
	}
}

void testList2() {
	auto lst = List!int();
	for(int i = 0; i < 100; i++) {
		lst.add(i);
	}
	auto groups = lst.groupBy((ref x) => x%4);
	foreach(entry; groups) {
		printf("Key=%d : ", entry.key);
		foreach(x; entry.value)printf("%d ", x);
		printf("\n");
	}	
}

void testArray() {

	auto arr = Array!(int)(100);
	for(int i = 0; i < arr.size(); i++) {
		arr[i] = i;
	}

	auto chunk = arr[10..20];
	for(int i = 0; i < chunk.size(); i++) {
		printf("%d\n", chunk[i]);
	}
	auto arr2 = arr.map((ref x) => x*x);
	for(int i = 0; i < 10; i++) {
		printf("%d\n", arr2[i]);
	}
}

/*
void testHashSet() {
	auto s = HashSet!int([1, 5, 6, 7, 8]);
	s.add(1);
	s.add(2);
	s.add(3);
	s.add(2);
	s.add(1);
	foreach(x; s){
		printf("%d\n", x);
	}
}*/

extern(C) int main() {
            
	testList();
    return 0;
}
