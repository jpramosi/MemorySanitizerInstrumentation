##  Memory Sanitzer Instrumentation STL, OpenSSL & Boost Libraries

  

This guide will introduce you into compiling stl openssl & boost libraries instrumented with MemorySanitizer and how to use it later with a test programm on ubuntu-18.04.<br>
Instead installing headers into a separate include folder in '/usr/local/include' it will be installed together with the library itself.<br>
Afterwards it can be found with a standard CMake module with a common 'X_ROOT' hint variable.<br>
The installed libraries will be also put in separate folders, so it won't influence already installed binaries.

<br>
<br>

## Compile intrumented libraries


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
CC="clang -fsanitize=memory -O1 " ./config --strict-warnings -no-shared --prefix=/usr/local/lib/openssl_1_1_1_msan --openssldir=/usr/local/lib/openssl_1_1_1_msan
make clean && make -j 4
sudo make install
```
<br>

Compile boost:
<br>
New headers located in '/usr/local/lib/boost_1_70_0_msan/include/boost_1_70_0_msan'
<br>
New libraries located in '/usr/local/lib/boost_1_70_0_msan/lib'
```
cd /your/libray/path/
wget https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz
tar -xzvf boost_1_70_0.tar.gz
cd boost_1_70_0
./bootstrap.sh --with-toolset=clang --prefix=/usr/local/lib/boost_1_70_0_msan
sudo ./b2 -a toolset=clang cxxflags="-std=c++11 -nostdinc++ -I/usr/local/lib/libcxx_msan/include/c++/v1 -fsanitize=memory" linkflags="-fsanitize=memory" --prefix=/usr/local/lib/boost_1_70_0_msan -j4 install

```
Note: Even it is not set with '-stdlib=libc++' it seems to use its headers (displays libcpp deprecation warnings).
Since it gets linked with libc++ and no link or runtime errors occures, i assume this is working.

<br>
<br>

## Use intrumented libraries

Now it is possible to switch between intrumented & raw libraries just by setting the environment hint variable in  [CMakeLists.txt](https://github.com/reapler/Memory-Sanitzer-Instrumentation/blob/master/CMakeLists.txt#L11) like this:
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
The provied [cmake-modules](https://github.com/reapler/Memory-Sanitzer-Instrumentation/tree/master/cmake) can be also copied into other projects to find the desired packages.<br>
See also [cmake-example](https://github.com/reapler/cmake-example) to get an overview of other tools.