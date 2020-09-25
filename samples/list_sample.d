import core.stdc.stdio;
import collections;

void test1() {
    int[5] arr = [2,3,1,5,0];
    auto lst = RCList!int(arr);    
    lst.sort();

    auto st = lst.toRCString();
    st.printLine();

    lst = lst.filter(x => x > 1).map(x => x*x);
    auto llst = RCList!(RCList!int)();
    llst.add(lst);

    st = llst.toRCString();
    st.printLine();

    foreach(ref x; llst[0]) {
        x += 1;
    }

    foreach(i, x; llst[0]) {
        printf("arr[%d] = %d\n", cast(int) i, x);
    }
}

void test2() {
    auto arr = RCList!int();
    for(int i = 0; i < 100; i++) {
        arr.add(i);
    }
    auto groups = arr.groupBy(x => x%4);
    foreach(entry; groups) {
        printf("Key=%d : ", entry.key);
        foreach(x; entry.value)printf("%d ", x);
        printf("\n");
    }    
}

extern(C) int main() 
{
	test1();
	test2();
	return 0;
}
