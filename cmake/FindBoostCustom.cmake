#[[
    - Try to find boost
    Once done, this will define

    BOOSTC_FOUND - system has boost
    BOOSTC_ROOT - base directory of boost
    BOOSTC_INCLUDE_DIR - the boost include directories
    BOOSTC_LIBRARIES - link these to use boost

    This module will only work on unix-like systems.
]]

function(_boostc_number_two_digits NUMBER VAL_OUT)
    if(NUMBER LESS 10)
        set(${VAL_OUT} "0${NUMBER}" PARENT_SCOPE)
    else()
        set(${VAL_OUT} "${NUMBER}" PARENT_SCOPE)
    endif()
endfunction()

function(_boostc_get_version_code VERSION)
    _boostc_number_two_digits(${BoostCustom_FIND_VERSION_MINOR} _BOOSTC_MINOR)
    _boostc_number_two_digits(${BoostCustom_FIND_VERSION_PATCH} _BOOSTC_PATCH)
    set(${VERSION} "${BoostCustom_FIND_VERSION_MAJOR}0${_BOOSTC_MINOR}${_BOOSTC_PATCH}" PARENT_SCOPE)
endfunction()

function(_boostc_reset_cache)
    unset(BOOSTC_INCLUDE_DIR CACHE)
    unset(BOOSTC_LIBRARIES CACHE)
endfunction()

function(_boostc_find_header_dir)

    if (NOT "${BOOSTC_INCLUDE_DIR}" STREQUAL "")
        return()
    endif()

    set(BOOSTC_SEARCH_FILE "version.hpp")
    if ("$ENV{BOOSTC_ROOT}" STREQUAL "")
        file(GLOB_RECURSE BOOSTC_INCLUDE_DIR
            "/usr/include/*${BOOSTC_SEARCH_FILE}"
            "/usr/local/include/*${BOOSTC_SEARCH_FILE}"
            "/opt/local/include/*${BOOSTC_SEARCH_FILE}"
            "${CMAKE_SOURCE_DIR}/includes/*${BOOSTC_SEARCH_FILE}"
            )
    else()
        file(GLOB_RECURSE BOOSTC_INCLUDE_DIR
            "$ENV{BOOSTC_ROOT}/include/*${BOOSTC_SEARCH_FILE}"
            "$ENV{BOOSTC_ROOT}/local/include/*${BOOSTC_SEARCH_FILE}"
            "${CMAKE_SOURCE_DIR}/includes/*${BOOSTC_SEARCH_FILE}"
            )
    endif()

    _boostc_get_version_code(BOOSTC_VERSION)
    foreach(VFILE ${BOOSTC_INCLUDE_DIR})
        # Read file and search for version
        file(READ ${VFILE} VFILE_TEXT)
        string(FIND "${VFILE_TEXT}" "${BOOSTC_VERSION}" STR_FOUND)
        if (NOT "${STR_FOUND}" STREQUAL "-1")
            # Check filename
            string(FIND "${VFILE}" "boost/${BOOSTC_SEARCH_FILE}" STR_FOUND)
            if (NOT "${STR_FOUND}" STREQUAL "-1")
                string(REPLACE "/boost/${BOOSTC_SEARCH_FILE}" "" BOOSTC_INCLUDE_DIR "${VFILE}")
                set(BOOSTC_INCLUDE_DIR "${BOOSTC_INCLUDE_DIR}" CACHE INTERNAL "")
                break()
            endif()
        endif()
    endforeach()

    if ("${BOOSTC_INCLUDE_DIR}" STREQUAL "")
        message(FATAL "ERROR: include directory not found.")
    endif()

endfunction()

function(_boostc_find_libraries)

    if (NOT "${BOOSTC_LIBRARIES}" STREQUAL "")
        return()
    endif()

    # Check components and get the first one
    if ("${BoostCustom_FIND_COMPONENTS}" STREQUAL "")
        message(FATAL "ERROR: No components defined.")
        return()
    endif()
    list(GET BoostCustom_FIND_COMPONENTS 0 BOOSTC_SEARCH_FILE)
    set(BOOSTC_SEARCH_FILE "libboost_${BOOSTC_SEARCH_FILE}.so.${BoostCustom_FIND_VERSION_MAJOR}.${BoostCustom_FIND_VERSION_MINOR}")

    if ("$ENV{BOOSTC_ROOT}" STREQUAL "")
        file(GLOB_RECURSE BOOSTC_FILES
            "/usr/lib64/*${BOOSTC_SEARCH_FILE}"
            "/usr/lib/*${BOOSTC_SEARCH_FILE}"
            "/usr/local/lib/*${BOOSTC_SEARCH_FILE}"
            "/opt/local/lib/*${BOOSTC_SEARCH_FILE}"
            "${CMAKE_SOURCE_DIR}/includes/*${BOOSTC_SEARCH_FILE}"
            )
    else()
        file(GLOB_RECURSE BOOSTC_FILES
            "$ENV{BOOSTC_ROOT}/lib64/*${BOOSTC_SEARCH_FILE}"
            "$ENV{BOOSTC_ROOT}/lib/*${BOOSTC_SEARCH_FILE}"
            "${CMAKE_SOURCE_DIR}/lib/*${BOOSTC_SEARCH_FILE}"
            )
    endif()

    # Get directory with the shortest path
    set(SHORTEST_SIZE 255)
    set(PREF_FILE "")
    foreach(VFILE ${BOOSTC_FILES})
        string(LENGTH "${VFILE}" STR_SIZE)
        if (${STR_SIZE} LESS ${SHORTEST_SIZE})
            set(SHORTEST_SIZE ${STR_SIZE})
            set(PREF_FILE "${VFILE}")
        endif()
    endforeach()
    get_filename_component(FILE_DIR "${PREF_FILE}" DIRECTORY)

    # Create file paths
    if (LIBCPP_USE_STATIC)
        foreach(COMPONENT ${BoostCustom_FIND_COMPONENTS})
            list(APPEND BOOSTC_LIBRARIES "${FILE_DIR}/libboost_${COMPONENT}.a")
        endforeach()
    else()
        foreach(COMPONENT ${BoostCustom_FIND_COMPONENTS})
            list(APPEND BOOSTC_LIBRARIES "${FILE_DIR}/libboost_${COMPONENT}.so")
        endforeach()
    endif()

    # Check paths
    foreach(VFILE ${BOOSTC_LIBRARIES})
        if (NOT EXISTS "${VFILE}")
            message(FATAL "ERROR: File not found ${VFILE}")
            set(BOOSTC_INCLUDE_DIR "" CACHE INTERNAL "")
            set(BOOSTC_LIBRARIES "" CACHE INTERNAL "")
            return()
        endif()
    endforeach()

    # Cache variables
    set(BOOSTC_LIBRARIES "${BOOSTC_LIBRARIES}" CACHE INTERNAL "")
    set(BOOSTC_FOUND TRUE CACHE INTERNAL "")
    MESSAGE(STATUS "Found Boost:\n\tLibraries: ${FILE_DIR}\n\tInclude: ${BOOSTC_INCLUDE_DIR}")

endfunction()

#[[
get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
    string(TOLOWER "${_variableName}" VAR_LOWER)
    string(FIND "${VAR_LOWER}" "boostcustom" STR_FOUND)
    if (NOT "${STR_FOUND}" STREQUAL "-1")
        message(STATUS "______________ ${_variableName}=${${_variableName}}")
    endif()
endforeach()
]]

_boostc_find_header_dir()
_boostc_find_libraries()