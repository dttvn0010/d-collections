import core.stdc.stdio;
import collections;

extern(C) int main() 
{
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
    
    return 0;
}
