import core.stdc.stdio;
import RC : Set;

extern(C) int main() 
{
    int[5] arr = [1, 5, 6, 7, 8];
    auto s = Set!int(arr);
    
    s.add(1);
    s.add(2);
    s.add(3);
    s.add(2);
    s.add(1);
    
    foreach(x; s){
        printf("%d\n", x);
    }
    
    s.toString().printLine();
    
    return 0;
}
