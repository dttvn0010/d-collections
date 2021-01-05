import core.stdc.stdio;
import RC : String;

extern(C) int main() 
{
    auto items = String("1,2,3,4").split(",");
    items.toString().printLine();

    String("-").join(items).printLine();

    printf("%d\n", String("Hello world").indexOf("123"));
    printf("%d\n", String("Hello world").indexOf("world"));
    String("Hello world").subString(6, 8).printLine();
    String("Hello world").subString(6).printLine();
    
    return 0;
}
