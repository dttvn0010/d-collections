import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import collections;
//import std.typecons;

nothrow:
void testDict1() {
    auto m = RCDict!(int, int)();
    for(int i = 50; i < 70; i++) {
        m[2*i] = i;
    }
    
    auto items = m.getItems();
    
    foreach(item; m) {
        printf("%d --> %d\n", item.key, item.value);
    }
    m.toRCString().printLine();
    printf("%d\n", m[100]);
}

void testDict2() {
    auto m = RCDict!(RCString, int)();    
    m[RCString("12")] = 100;
    auto s = RCString("1");
    s += "1";
    auto s2 = s + 2;
    s2.printLine();
    printf("%d\n", m[RCString("1") + "2"]);
}


void testDict3() {
    auto m = RCDict!(int, int)();
    
    int s = 0;
    for(int j = 0; j < 100; j++) {
        for(int i = 0; i < 1000000; i++) {
            m[i]  = i % 5;
        }
        for(int i = 0; i < 1000000; i++) {
            s += m[i];
        }        
    }
    
    printf("%d\n", s);
}

void testList1() {
    int[5] arr = [2,3,1,5,0];
    auto lst = RCList!int(arr);    
    //arr.sort();

    auto st = lst.toRCString();
    st.printLine();

    lst = lst.filter(x => x > 1).map(x => x*x);
    auto llst = RCList!(RCList!int)();
    llst.add(lst);

    st = llst.toRCString((ref x) => x.toRCString());
    st.printLine();

    foreach(ref x; llst[0]) {
        x += 1;
    }

    foreach(i, x; llst[0]) {
        printf("arr[%d] = %d\n", cast(int) i, x);
    }
}

void testList2() {
    auto arr = RCList!int();
    for(int i = 0; i < 100; i++) {
        arr.add(i);
    }
    auto groups = arr.groupBy((ref x) => x%4);
    foreach(entry; groups) {
        printf("Key=%d : ", entry.key);
        foreach(x; entry.value)printf("%d ", x);
        printf("\n");
    }    
}

/*
Tuple!(int, RCString) test() {
    return tuple(2, RCString("2"));
}

void testTuple() {
    auto t = test();
    printf("key=%d, value=", t[0]);
    t[1].printLine();
}
*/

void testSet() {
    int[5] arr = [1, 5, 6, 7, 8];
    auto s = RCSet!int(arr);
    s.add(1);
    s.add(2);
    s.add(3);
    s.add(2);
    s.add(1);
    foreach(x; s){
        printf("%d\n", x);
    }
    s.toRCString().printLine();
}

extern(C) int main() {
    //testList1();
    //testList2();
    //testDict1();
    //testDict2();
    //testDict3();
    testSet();
    return 0;
}
