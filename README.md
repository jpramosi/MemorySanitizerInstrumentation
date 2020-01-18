##  Memory Sanitizer Instrumentation STL, OpenSSL & Boost Libraries

  

This guide will introduce you into compiling stl, openssl & boost libraries instrumented with MemorySanitizer and how to use it later with a test programm on ubuntu-18.04.<br>
To the best of my knowledge memory sanitizer unfortunately doesn't allow blacklist external non-instrumented libraries,<br>
so it is needed to instrument it even if the source will be suppressed anyway.<br>
Instead installing headers into a separate include folder in '/usr/local/include' it will be installed together with the library itself.<br>
Afterwards it can be found with a standard CMake module with a common 'X_ROOT' hint variable.<br>
The installed libraries will be also put in separate folders, so it won't influence already installed binaries.

<br>
<br>

## Compile instrumented libraries


Requirements: git, clang
````
sudo apt-get install git -y
sudo apt-get install clang -y
sudo apt-get install libclang-dev -y
````
<br>

Compile libcxx:
<br>
New headers located in '/usr/local/include/c++/v1'
<br>
New libraries located in '/usr/local/lib/libcxx_msan'
```
cd /your/libray/path/
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
mkdir build && cd build
cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_INSTALL_PREFIX=/usr/local/lib/libcxx_msan -DLIBCXX_INSTALL_PREFIX=/usr/local/lib/libcxx_msan/ -DLIBCXX_INSTALL_HEADER_PREFIX=/usr/local/lib/libcxx_msan/ -DLIBCXXABI_INSTALL_PREFIX=/usr/local/lib/libcxx_msan/ -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" -DCMAKE_BUILD_TYPE=Release -DLLVM_USE_SANITIZER=Memory ../llvm
make cxx -j4
sudo make install-cxx install-cxxabi
```

<br>

Compile openssl:
<br>
New headers located in '/usr/local/lib/openssl_1_1_1_msan/include'
<br>
New libraries located in '/usr/local/lib/openssl_1_1_1_msan/lib'
```
cd /your/libray/path/
git clone -b OpenSSL_1_1_1-stable --recursive https://github.com/openssl/openssl
cd openssl
wget https://raw.githubusercontent.com/reapler/Memory-Sanitizer-Instrumentation/master/sanitizer_suppression.txt
CC="clang -fsanitize=memory -O1 -fsanitize-blacklist=sanitizer_suppression.txt" ./config --strict-warnings -no-shared --prefix=/usr/local/lib/openssl_1_1_1_msan --openssldir=/usr/local/lib/openssl_1_1_1_msan
make clean && make -j 4
sudo make install
```
Note: Since OpenSSL is known for having false-positives, a suppression file for all source files is used.<br>
Since the project is anyway tested by its maintainers, it is fine now.
<br>
<br>

Compile boost:
<br>
New headers located in '/usr/local/lib/boost_1_70_0_msan/include'
<br>
New libraries located in '/usr/local/lib/boost_1_70_0_msan/lib'
```
cd /your/libray/path/
wget https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz
tar -xzvf boost_1_70_0.tar.gz
cd boost_1_70_0
./bootstrap.sh --with-toolset=clang --prefix=/usr/local/lib/boost_1_70_0_msan
sudo ./b2 -a toolset=clang cxxflags="-std=c++11 -nostdinc++ -I/usr/local/lib/libcxx_msan/include/c++/v1 -fsanitize=memory" linkflags="-fsanitize=memory" --prefix=/usr/local/lib/boost_1_70_0_msan -j4 install
sudo ldconfig
```
Note: Even it is not set with '-stdlib=libc++' it seems to use its headers (displays libcpp deprecation warnings).<br>
Since it gets linked with libc++ and no link or runtime errors occures, i assume this is working.

<br>
<br>

## Use instrumented libraries

Now it is possible to switch between instrumented & raw libraries just by setting the environment hint variable in  [CMakeLists.txt](https://github.com/reapler/Memory-Sanitizer-Instrumentation/blob/master/CMakeLists.txt#L11) like this:
```
# libc++
set(ENV{LIBCPP_ROOT} "/usr/local/lib/libcxx_msan")
set(LIBCPP_USE_STATIC ON)
find_package(Libc++)

# openssl
set(ENV{OPENSSL_ROOT_DIR} "/usr/local/lib/openssl_1_1_1_msan")
set(OPENSSL_USE_STATIC_LIBS ON)
find_package(OpenSSL REQUIRED)

# boost
set(ENV{BOOST_ROOT} "/usr/local/lib/boost_1_70_0_msan")
set(Boost_USE_STATIC_LIBS ON)
find_package(Boost 1.70.0 REQUIRED COMPONENTS filesystem system date_time)
```

To test if everything is working as expected, common functions are used for each library:
```cpp
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
```

The expected output:
```
==12828==WARNING: MemorySanitizer: use-of-uninitialized-value
    #0 0x50fb54 in undefined_read() /projects/tests/MsanInstrumentation/src/main.cpp:35:9
    #1 0x50fc2f in main /projects/tests/MsanInstrumentation/src/main.cpp:44:5
    #2 0x7f3990d41b96 in __libc_start_main /build/glibc-OTsEL5/glibc-2.27/csu/../csu/libc-start.c:310
    #3 0x495249 in _start (/projects/tests/MsanInstrumentation/build/msan+0x495249)

SUMMARY: MemorySanitizer: use-of-uninitialized-value /projects/tests/MsanInstrumentation/src/main.cpp:35:9 in undefined_read()
```

<br>
<br>

## Modules

The modules [BinaryWrapper](https://github.com/reapler/Memory-Sanitizer-Instrumentation/blob/master/cmake/BinaryWrapper.cmake), [FindBoostCustom](https://github.com/reapler/Memory-Sanitizer-Instrumentation/blob/master/cmake/FindBoostCustom.cmake), [FindLibc++](https://github.com/reapler/Memory-Sanitizer-Instrumentation/blob/master/cmake/FindLibc%2B%2B.cmake) & [FindOpenSSLCustom](https://github.com/reapler/Memory-Sanitizer-Instrumentation/blob/master/cmake/FindOpenSSLCustom.cmake) are no default cmake modules,<br>the '*Custom' behave similary like the original module and can be used
in a project if you don't like to mess up the find_package's cache variables from the original one. But in this project here it is not needed.<br>
See also [Sanitize-Coredump-Coverage](https://github.com/reapler/Sanitize-Coredump-Coverage) to get an overview of the other excellent tools.