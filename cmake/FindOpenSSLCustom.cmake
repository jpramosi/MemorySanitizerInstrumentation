#[[
    - Try to find openssl and opensslabi
    Once done, this will define

    OPENSSLC_FOUND - system has openssl
    OPENSSLC_ROOT - base directory of openssl
    OPENSSLC_INCLUDE_DIR - the openssl include directories
    OPENSSLC_LIBRARIES - link these to use openssl
]]

function(_opensslc_find_header_dir)

    if (NOT "${OPENSSLC_INCLUDE_DIR}" STREQUAL "")
        return()
    endif()

    find_path(OPENSSLC_INCLUDE_DIR
    NAMES
        openssl/ssl.h
    HINTS
        $ENV{OPENSSLC_ROOT}
    PATH_SUFFIXES
        include
    )

endfunction()

function(_opensslc_find_libraries)

    if (NOT "${OPENSSLC_SSL_LIBRARY}" STREQUAL "" AND NOT "${OPENSSLC_CRYPTO_LIBRARY}" STREQUAL "")
        return()
    endif()

    if (OPENSSLC_USE_STATIC)
        set(OPENSSLC_SEARCH_LIBSSL "libssl.a")
        set(OPENSSLC_SEARCH_LIBCRYPTO "libcrypto.a")
    else()
        set(OPENSSLC_SEARCH_LIBSSL "libssl.so")
        set(OPENSSLC_SEARCH_LIBCRYPTO "libcrypto.so")
    endif()

    find_library(OPENSSLC_SSL_LIBRARY
        NAMES
            ${OPENSSLC_SEARCH_LIBSSL}
        HINTS
            $ENV{OPENSSLC_ROOT}
        PATH_SUFFIXES
            lib
    )
    find_library(OPENSSLC_CRYPTO_LIBRARY
        NAMES
            ${OPENSSLC_SEARCH_LIBCRYPTO}
        HINTS
            $ENV{OPENSSLC_ROOT}
        PATH_SUFFIXES
            lib
    )

    if(OPENSSLC_INCLUDE_DIR AND OPENSSLC_SSL_LIBRARY AND OPENSSLC_CRYPTO_LIBRARY)
        SET(OPENSSLC_FOUND TRUE CACHE INTERNAL "")
        set(OPENSSLC_LIBRARIES ${OPENSSLC_SSL_LIBRARY} ${OPENSSLC_CRYPTO_LIBRARY} CACHE INTERNAL "")
    endif()
    if(OPENSSLC_FOUND)
        MESSAGE(STATUS "Found ssl: ${OPENSSLC_SSL_LIBRARY}")
        MESSAGE(STATUS "Found crypto: ${OPENSSLC_CRYPTO_LIBRARY}")
    endif()

endfunction()

_opensslc_find_header_dir()
_opensslc_find_libraries()