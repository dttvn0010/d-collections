import core.stdc.stdio;
import collections;

extern(C) int main() 
{
    auto items = RCString("1,2,3,4").split(",");
    items.toRCString().printLine();

    RCString("-").join(items).printLine();

    printf("%d\n", RCString("Hello world").indexOf("123"));
    printf("%d\n", RCString("Hello world").indexOf("world"));
    RCString("Hello world").subString(6, 8).printLine();
    RCString("Hello world").subString(6).printLine();
    
    return 0;
}
