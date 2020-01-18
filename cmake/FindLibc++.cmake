#[[
    - Try to find libc++ and libc++abi
    Once done, this will define

    LIBCPP_FOUND - system has libc++
    LIBCPP_ROOT - base directory of libc++
    LIBCPP_INCLUDE_DIR - the libc++ include directories, not really needed
    LIBCPP_LIBRARIES - link these to use libc++
]]

function(_libcpp_find_header_dir)

    if (NOT "${LIBCPP_INCLUDE_DIR}" STREQUAL "")
        return()
    endif()

    find_path(LIBCPP_INCLUDE_DIR
        NAMES
            v1/__libcpp_version
        HINTS
            $ENV{LIBCPP_ROOT}
        PATH_SUFFIXES
            include/c++
    )

endfunction()

function(_libcpp_find_libraries)

    if (NOT "${LIBCPP_LIBRARY}" STREQUAL "" AND NOT "${LIBCPPABI_LIBRARY}" STREQUAL "")
        return()
    endif()

    if (LIBCPP_USE_STATIC)
        set(LIBCPP_SEARCH_LIBCPP "libc++.a")
        set(LIBCPP_SEARCH_LIBCPPABI "libc++abi.a")
    else()
        set(LIBCPP_SEARCH_LIBCPP "libc++.so")
        set(LIBCPP_SEARCH_LIBCPPABI "libc++abi.so")
    endif()

    find_library(LIBCPP_LIBRARY
        NAMES
            ${LIBCPP_SEARCH_LIBCPP}
        HINTS
            $ENV{LIBCPP_ROOT}
        PATH_SUFFIXES
            lib
    )
    find_library(LIBCPPABI_LIBRARY
        NAMES
            ${LIBCPP_SEARCH_LIBCPPABI}
        HINTS
            $ENV{LIBCPP_ROOT}
        PATH_SUFFIXES
            lib
    )

    if(LIBCPP_INCLUDE_DIR AND LIBCPP_LIBRARY AND LIBCPPABI_LIBRARY)
        set(LIBCPP_FOUND TRUE CACHE INTERNAL "")
        set(LIBCPP_INCLUDE_DIR "${LIBCPP_INCLUDE_DIR}/v1" CACHE INTERNAL "")
        set(LIBCPP_LIBRARIES ${LIBCPP_LIBRARY} ${LIBCPPABI_LIBRARY} CACHE INTERNAL "")
    endif()
    if(LIBCPP_FOUND)
        message(STATUS "Found libc++: ${LIBCPP_LIBRARY}")
        message(STATUS "Found libc++abi: ${LIBCPPABI_LIBRARY}")
    else()
        if(LIBCPP_FIND_REQUIRED)
            message(FATAL_ERROR "Could not find libc++")
        endif()
    endif()

endfunction()

_libcpp_find_header_dir()
_libcpp_find_libraries()