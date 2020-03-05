cmake_minimum_required (VERSION 3.8)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
include(BinaryWrapper)
set(CMAKE_CXX_STANDARD 11)
set(REPORT_FOLDER "Reports")# Set to "Report" if you wish to report to a file




# libc++ needs compile flag -stdlib=libc++
set(ENV{LIBCPP_ROOT} "/usr/local/lib/libcxx_msan")
set(LIBCPP_USE_STATIC ON)
find_package(Libc++)

# openssl
# Sanitized openssl builds requires to be linked statically
set(ENV{OPENSSL_ROOT_DIR} "/usr/local/lib/openssl_1_1_1_msan")
set(OPENSSL_USE_STATIC_LIBS ON)
find_package(OpenSSL REQUIRED)

# boost
set(ENV{BOOST_ROOT} "/usr/local/lib/boost_1_72_0_msan")
set(Boost_USE_STATIC_LIBS ON)
find_package(Boost 1.72.0 REQUIRED COMPONENTS filesystem system date_time)




#[[ 
    "-O0"                      [optional]       Disables optimizations, allowing better stacktraces. Alternative: -01
    "-g"                       [required]       Compile with debug information (filenames, line numbers etc)
    "-rdynamic"                [optional]       Needed for shared libraries, so the function can be backtraced
    "-fno-omit-frame-pointer"  [optional]       Nicer stacktraces
    "-funwind-tables"          [required:ARM]   "Allows walking back in the stack frame from given a given point",
                                                toggling this flag avoids stacktraces with only one entry
    "-mapcs-frame"             [required:ARM]   "Generate a stack frame that is compliant 
                                                with the ARM Procedure Call Standard"
    "-stdlib=libc++"           [required]       This will enable the use of the libc++ stl library.
]]
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")

	# MemorySanitizer
	# https://clang.llvm.org/docs/MemorySanitizer.html
    include_directories(${PROJECT_SOURCE_DIR} 
                "${LIBCPP_INCLUDE_DIR}"
                "${PROJECT_SOURCE_DIR}/src"
                "${OPENSSL_INCLUDE_DIR}"
                "${Boost_INCLUDE_DIRS}")
    add_executable(msan "${PROJECT_SOURCE_DIR}/src/main.cpp")
    set_target_properties(msan PROPERTIES COMPILE_FLAGS "-stdlib=libc++ -O0 -g -pthread -fsanitize=memory")
    set_target_properties(msan PROPERTIES LINK_FLAGS "-pthread -fno-omit-frame-pointer -rdynamic -fsanitize=memory")
    target_link_libraries(msan 
                ${LIBCPP_LIBRARIES}
                ${OPENSSL_LIBRARIES}
                ${Boost_LIBRARIES})
    create_script_msan(msan "${REPORT_FOLDER}")

endif()