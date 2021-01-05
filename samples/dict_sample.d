import core.stdc.stdio;
import RC: Dict, String;

void test1() {
    auto m = Dict!(int, int)();
    
    for(int i = 50; i < 70; i++) {
        m[2*i] = i;
    }
    
    m[256] = 100;
    
    foreach(item; m) {
        printf("%d --> %d\n", item.key, item.value);
    }
    
    m.toString().printLine();
}

void test2() {
    auto m = Dict!(String, int)();    
    m[String("12")] = 100;
    auto s = String("1");   
    printf("%d\n", m[s + "2"]);
}

extern(C) int main() 
{
    test1();
    test2();
    return 0;
}
