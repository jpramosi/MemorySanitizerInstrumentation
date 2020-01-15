# - Try to find libc++ and libc++abi
# Once done, this will define
#
# LIBCPP_FOUND - system has libc++
# LIBCPP_ROOT - base directory of libc++
# LIBCPP_INCLUDE_DIR - the libc++ include directories, not really needed
# LIBCPP_LIBRARIES - link these to use libc++

function(_libcpp_find_header_dir)
    if ("${LIBCPP_INCLUDE_DIR}" STREQUAL "")
        set(LIBCPP_SEARCH_FILE "__libcpp_version")
        if ("ENV{LIBCPP_ROOT}" STREQUAL "")
            file(GLOB_RECURSE LIBCPP_INCLUDE_DIR
                "/usr/include/*${LIBCPP_SEARCH_FILE}"
                "/usr/local/include/*${LIBCPP_SEARCH_FILE}"
                "/opt/local/include/*${LIBCPP_SEARCH_FILE}"
                "${CMAKE_SOURCE_DIR}/includes/*${LIBCPP_SEARCH_FILE}"
                )
        else()
            file(GLOB_RECURSE LIBCPP_INCLUDE_DIR
                "$ENV{LIBCPP_ROOT}/include/*${LIBCPP_SEARCH_FILE}"
                "$ENV{LIBCPP_ROOT}/local/include/*${LIBCPP_SEARCH_FILE}"
                "${CMAKE_SOURCE_DIR}/includes/*${LIBCPP_SEARCH_FILE}"
                )
        endif()
        foreach(VFILE ${LIBCPP_INCLUDE_DIR})
            get_filename_component(FILE_DIR "${VFILE}" DIRECTORY)
            set(LIBCPP_INCLUDE_DIR "${FILE_DIR}" CACHE INTERNAL "")
            break()
        endforeach()
    endif()
endfunction()

function(_libcpp_find_library_dir)

    if (LIBCPP_USE_STATIC)
        set(LIBCPP_SEARCH_LIBCPP "libc++.a")
        set(LIBCPP_SEARCH_LIBCPPABI "libc++abi.a")
    else()
        set(LIBCPP_SEARCH_LIBCPP "libc++.so")
        set(LIBCPP_SEARCH_LIBCPPABI "libc++abi.so")
    endif()

    if ("${LIBCPP_LIBRARY}" STREQUAL "" OR "${LIBCPPABI_LIBRARY}" STREQUAL "")
        if ("ENV{LIBCPP_ROOT}" STREQUAL "")
            file(GLOB_RECURSE LIBCPP_LIBRARY
                "/usr/lib64/*${LIBCPP_SEARCH_LIBCPP}"
                "/usr/lib/*${LIBCPP_SEARCH_LIBCPP}"
                "/usr/local/lib/*${LIBCPP_SEARCH_LIBCPP}"
                "/opt/local/lib/*${LIBCPP_SEARCH_LIBCPP}"
                "${CMAKE_SOURCE_DIR}/includes/*${LIBCPP_SEARCH_LIBCPP}"
                )
            file(GLOB_RECURSE LIBCPPABI_LIBRARY
                "/usr/lib64/*${LIBCPP_SEARCH_LIBCPPABI}"
                "/usr/lib/*${LIBCPP_SEARCH_LIBCPPABI}"
                "/usr/local/lib/*${LIBCPP_SEARCH_LIBCPPABI}"
                "/opt/local/lib/*${LIBCPP_SEARCH_LIBCPPABI}"
                "${CMAKE_SOURCE_DIR}/includes/*${LIBCPP_SEARCH_LIBCPPABI}"
                )
        else()
            file(GLOB_RECURSE LIBCPP_LIBRARY
                "$ENV{LIBCPP_ROOT}/lib64/*${LIBCPP_SEARCH_LIBCPP}"
                "$ENV{LIBCPP_ROOT}/lib/*${LIBCPP_SEARCH_LIBCPP}"
                "${CMAKE_SOURCE_DIR}/lib/*${LIBCPP_SEARCH_LIBCPP}"
                )
            file(GLOB_RECURSE LIBCPPABI_LIBRARY
                "$ENV{LIBCPP_ROOT}/lib64/*${LIBCPP_SEARCH_LIBCPPABI}"
                "$ENV{LIBCPP_ROOT}/lib/*${LIBCPP_SEARCH_LIBCPPABI}"
                "${CMAKE_SOURCE_DIR}/lib/*${LIBCPP_SEARCH_LIBCPPABI}"
                )
        endif()
    endif()

    foreach(VFILE ${LIBCPP_LIBRARY})
        set(LIBCPP_LIBRARY "${VFILE}" CACHE INTERNAL "")
        break()
    endforeach()

    foreach(VFILE ${LIBCPPABI_LIBRARY})
        set(LIBCPPABI_LIBRARY "${VFILE}" CACHE INTERNAL "")
        break()
    endforeach()

    if(LIBCPP_INCLUDE_DIR AND LIBCPP_LIBRARY AND LIBCPPABI_LIBRARY)
        SET(LIBCPP_FOUND TRUE)
        set(LIBCPP_LIBRARIES ${LIBCPP_LIBRARY} ${LIBCPPABI_LIBRARY} CACHE INTERNAL "")
    endif()
    if(LIBCPP_FOUND)
        MESSAGE(STATUS "Found libc++: ${LIBCPP_LIBRARY}")
        MESSAGE(STATUS "Found libc++abi: ${LIBCPPABI_LIBRARY}")
    else()
        if(LIBCPP_FIND_REQUIRED)
            MESSAGE(FATAL_ERROR "Could not find libc++")
        endif()
    endif()

endfunction()

_libcpp_find_header_dir()
_libcpp_find_library_dir()