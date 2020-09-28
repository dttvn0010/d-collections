import core.stdc.stdio;
import collections;

void test1() {
    int[5] arr = [2,3,1,5,0];
    auto lst = RCList!int(arr);    

    printf("Original list: ");
    lst.toRCString.printLine();
    
    auto indexes = lst.argsort();
    printf("Sorted indexes: ");
    indexes.toRCString.printLine();

    lst.sort();
    printf("Sorted list: ");
    lst.toRCString().printLine();

    auto sum = lst.reduce((x, y) => x + y);
    printf("Sum: %d\n", sum);

    lst = lst.filter(x => x > 1).map(x => x*x);
    auto llst = RCList!(RCList!int)();
    llst.add(lst);

    llst.toRCString().printLine();

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
