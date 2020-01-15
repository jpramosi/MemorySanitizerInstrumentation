#include <fstream>
#include <openssl/ssl.h>
#include <boost/filesystem.hpp>

void stl_test()
{
    // If stl library 'libc++' is correctly instrumented,
    // this should not report to memory sanitizer
    std::ofstream o;
    o.open("test");
    o << "test" << std::endl;
}

void openssl_test()
{
    // If openssl library is correctly instrumented,
    // this should not report to memory sanitizer
    SSL_load_error_strings();
}

void boost_test()
{
    // If boost library is correctly instrumented,
    // this should not report to memory sanitizer
    if (boost::filesystem::exists("blub.txt"))
        printf("test\n");
}

void undefined_read()
{
    // If all libraries are instrumented correctly,
    // this is the only piece of code that is allowed to be reported
    // to memory sanitizer
    int a;
    if (a == 0)
        printf("test\n");
}

int main(int argc, char **argv)
{
    stl_test();
    openssl_test();
    boost_test();
    undefined_read();

    return 0;
}