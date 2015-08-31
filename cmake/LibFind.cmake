include (CMakeParseArguments)
include(FindPackageHandleStandardArgs)

#==============================================================================
#
#  FUNCTIONS TO HELP WITH Find* MODULES
#
#==============================================================================

#______________________________________________________________________________
# - Wrapper for finding static libraries ONLY
#
macro (find_static_library)
    set (_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
    set (CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
    find_library(${ARGN})
    set (CMAKE_FIND_LIBRARY_SUFFIXES ${_CMAKE_FIND_LIBRARY_SUFFIXES})
    unset (_CMAKE_FIND_LIBRARY_SUFFIXES)
endmacro ()


#______________________________________________________________________________
# - Wrapper for finding shared/dynamic libraries ONLY
#
macro (find_shared_library)
    set (_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
    set (CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX})
    find_library(${ARGN})
    set (CMAKE_FIND_LIBRARY_SUFFIXES ${_CMAKE_FIND_LIBRARY_SUFFIXES})
    unset (_CMAKE_FIND_LIBRARY_SUFFIXES)
endmacro ()


#______________________________________________________________________________
# - Function to determine type (SHARED or STATIC) of library
#
#   Input:
#     LIB             (FILE)
#
#   Returns:
#     RETURN_VAR      (BOOL)
#
function (is_shared_library RETURN_VAR LIB)
    get_filename_component(libext ${LIB} EXT)
    if (libext MATCHES ${CMAKE_SHARED_LIBRARY_SUFFIX})
        set (${RETURN_VAR} TRUE PARENT_SCOPE)
    else ()
        set (${RETURN_VAR} FALSE PARENT_SCOPE)
    endif ()
endfunction ()


#______________________________________________________________________________
# - Function to define a valid package component
#
#   Input:
#     ${PKG}_DEFAULT             (BOOL)
#     ${PKG}_COMPONENT           (STRING)
#     ${PKG}_INCLUDE_NAMES       (LIST)
#     ${PKG}_LIBRARY_NAMES       (LIST)
#
#   Returns:
#     ${PKG}_DEFAULT_COMPONENT           (STRING)
#     ${PKG}_VALID_COMPONENTS            (LIST)
#     ${PKG}_${COMPONENT}_INCLUDE_NAMES  (LIST)
#     ${PKG}_${COMPONENT}_LIBRARY_NAMES  (LIST)
#
function (define_package_component PKG)

    # Parse the input arguments
    set (options DEFAULT)
    set (oneValueArgs COMPONENT)
    set (multiValueArgs INCLUDE_NAMES LIBRARY_NAMES)
    cmake_parse_arguments (${PKG} "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    if (${PKG}_COMPONENT)
        set (PKGCOMP ${PKG}_${${PKG}_COMPONENT})
    else ()
        set (PKGCOMP ${PKG})
    endif ()
    
    # Set return values
    if (${PKG}_COMPONENT)
        if (${PKG}_DEFAULT)
            set (${PKG}_DEFAULT_COMPONENT ${${PKG}_COMPONENT} PARENT_SCOPE)
        endif ()
        set (VALID_COMPONENTS ${${PKG}_VALID_COMPONENTS})
        list (APPEND VALID_COMPONENTS ${${PKG}_COMPONENT})
        set (${PKG}_VALID_COMPONENTS ${VALID_COMPONENTS} PARENT_SCOPE)
    endif ()
    set (${PKGCOMP}_INCLUDE_NAMES ${${PKG}_INCLUDE_NAMES} PARENT_SCOPE)
    set (${PKGCOMP}_LIBRARY_NAMES ${${PKG}_LIBRARY_NAMES} PARENT_SCOPE)

endfunction ()


#______________________________________________________________________________
# - Function to find valid package components
#
#   Assumes pre-defined variables: 
#     ${PKG}_FIND_COMPONENTS        (LIST)
#     ${PKG}_DEFAULT_COMPONENT      (STRING)
#     ${PKG}_VALID_COMPONENTS       (LIST)
#
#   Returns:
#     ${PKG}_FIND_VALID_COMPONENTS  (LIST)
#
function (find_valid_components PKG)

    if (NOT ${PKG}_FIND_COMPONENTS)
        set (${PKG}_FIND_COMPONENTS ${${PKG}_DEFAULT_COMPONENT})
    endif ()
    
    set (FIND_VALID_COMPONENTS)
    foreach (comp IN LISTS ${PKG}_FIND_COMPONENTS)
        if (";${${PKG}_VALID_COMPONENTS};" MATCHES ";${comp};")
            list (APPEND FIND_VALID_COMPONENTS ${comp})
        endif ()
    endforeach ()

    set (${PKG}_FIND_VALID_COMPONENTS ${FIND_VALID_COMPONENTS} PARENT_SCOPE)
    
endfunction ()


#______________________________________________________________________________
# - Basic find package macro for a specific component
#
# Assumes pre-defined variables:
#   ${PKG}_${COMP}_INCLUDE_NAMES or ${PKG}_INCLUDE_NAMES
#   ${PKG}_${COMP}_LIBRARY_NAMES or ${PKG}_LIBRARY_NAMES
#
# Input:
#   ${PKG}_COMPONENT
#   ${PKG}_INCLUDE_HINTS
#   ${PKG}_LIBRARY_HINTS
#
function (find_package_component PKG)

    # Parse the input arguments
    set (options)
    set (oneValueArgs COMPONENT)
    set (multiValueArgs INCLUDE_HINTS INCLUDE_PATHS LIBRARY_HINTS LIBRARY_PATHS)
    cmake_parse_arguments (${PKG} "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})    
    set (COMP ${${PKG}_COMPONENT})
    if (COMP)
        set (PKGCOMP ${PKG}_${COMP})
    else ()
        set (PKGCOMP ${PKG})
    endif ()
    string (TOUPPER ${PKG} PKGUP)
    string (TOUPPER ${PKGCOMP} PKGCOMPUP)
    
    # Handle QUIET and REQUIRED arguments
    if (${${PKG}_FIND_QUIETLY})
        set (${PKGCOMP}_FIND_QUIETLY TRUE)
    endif ()
    if (${${PKG}_FIND_REQUIRED})
        set (${PKGCOMP}_FIND_REQUIRED TRUE)
    endif ()
    
    # Determine include dir search order
    set (INCLUDE_HINTS)
    if (${PKG}_INCLUDE_HINTS)
        list (APPEND INCLUDE_HINTS ${${PKG}_INCLUDE_HINTS})
    endif ()
    if (${PKGCOMP}_PATH)
        list (APPEND INCLUDE_HINTS ${${PKGCOMP}_PATH}/include)
    endif ()
    if (${PKG}_PATH)
        list (APPEND INCLUDE_HINTS ${${PKG}_PATH}/include)
    endif ()
    if (DEFINED ENV{${PKGCOMPUP}})
        list (APPEND INCLUDE_HINTS $ENV{${PKGCOMPUP}}/include)
    endif ()
    if (DEFINED ENV{${PKGUP}})
        list (APPEND INCLUDE_HINTS $ENV{${PKGUP}}/include)
    endif ()
    
    # Search for include file
    find_path (${PKGCOMP}_INCLUDE_DIR
               NAMES ${${PKGCOMP}_INCLUDE_NAMES}
               HINTS ${INCLUDE_HINTS}
               PATHS ${${PKG}_INCLUDE_PATHS})
               
    # Unset include search variables
    unset (INCLUDE_HINTS)
    
    # Determine library dir search order
    set (LIBRARY_HINTS)
    if (${PKG}_LIBRARY_HINTS)
        list (APPEND LIBRARY_HINTS ${${PKG}_LIBRARY_HINTS})
    endif ()
    if (${PKGCOMP}_PATH)
        list (APPEND LIBRARY_HINTS ${${PKGCOMP}_PATH}/lib)
    endif ()
    if (${PKG}_PATH)
        list (APPEND LIBRARY_HINTS ${${PKG}_PATH}/lib)
    endif ()
    if (DEFINED ENV{${PKGCOMPUP}})
        list (APPEND LIBRARY_HINTS $ENV{${PKGCOMPUP}}/lib)
    endif ()
    if (DEFINED ENV{${PKGUP}})
        list (APPEND LIBRARY_HINTS $ENV{${PKGUP}}/lib)
    endif ()
    
    # Search for library file
    find_library (${PKGCOMP}_LIBRARY
                  NAMES ${${PKGCOMP}_LIBRARY_NAMES}
                  HINTS ${LIBRARY_HINTS}
                  PATHS ${${PKG}_LIBRARY_PATHS})
    if (${PKGCOMP}_LIBRARY)
        is_shared_library (${PKGCOMP}_IS_SHARED ${${PKGCOMP}_LIBRARY})
        
        if (PREFER_SHARED AND NOT ${PKGCOMP}_IS_SHARED)
            find_shared_library (${PKGCOMP}_SHARED_LIBRARY
                                 NAMES ${${PKGCOMP}_LIBRARY_NAMES}
                                 HINTS ${LIBRARY_HINTS})
            if (${PKGCOMP}_SHARED_LIBRARY)
                set (${PKGCOMP}_LIBRARY ${${PKGCOMP}_SHARED_LIBRARY})
                set (${PKGCOMP}_IS_SHARED TRUE)
            endif ()
        elseif (PREFER_STATIC AND ${PKGCOMP}_IS_SHARED)
            find_static_library (${PKGCOMP}_STATIC_LIBRARY
                                 NAMES ${${PKGCOMP}_LIBRARY_NAMES}
                                 HINTS ${LIBRARY_HINTS})
            if (${PKGCOMP}_STATIC_LIBRARY)
                set (${PKGCOMP}_LIBRARY ${${PKGCOMP}_STATIC_LIBRARY})
                set (${PKGCOMP}_IS_SHARED FALSE)
            endif ()
        endif ()
        
    endif ()

    # Unset include search variables
    unset (LIBRARY_HINTS)

    # handle the QUIETLY and REQUIRED arguments and 
    # set NetCDF_C_FOUND to TRUE if all listed variables are TRUE
    find_package_handle_standard_args (${PKGCOMP} DEFAULT_MSG
                                       ${PKGCOMP}_LIBRARY 
                                       ${PKGCOMP}_INCLUDE_DIR)
    mark_as_advanced (${PKGCOMP}_INCLUDE_DIR ${PKGCOMP}_LIBRARY)
    
    # HACK For bug in CMake v3.0:
    set (${PKGCOMP}_FOUND ${${PKGCOMPUP}_FOUND})

    # Set return variables
    if (${PKGCOMP}_FOUND)
        set (${PKGCOMP}_INCLUDE_DIRS ${${PKGCOMP}_INCLUDE_DIR})
        set (${PKGCOMP}_LIBRARIES ${${PKGCOMP}_LIBRARY})
        set (${PKGCOMP}_DEFINITIONS)
        set (${PKGCOMP}_OPTIONS)
    endif ()
    
    # Return all variables to the parent scope
    set (${PKGCOMP}_FOUND        ${${PKGCOMP}_FOUND}        PARENT_SCOPE) 
    set (${PKGCOMP}_INCLUDE_DIR  ${${PKGCOMP}_INCLUDE_DIR}  PARENT_SCOPE) 
    set (${PKGCOMP}_INCLUDE_DIRS ${${PKGCOMP}_INCLUDE_DIRS} PARENT_SCOPE)
    set (${PKGCOMP}_LIBRARY      ${${PKGCOMP}_LIBRARY}      PARENT_SCOPE)
    set (${PKGCOMP}_LIBRARIES    ${${PKGCOMP}_LIBRARIES}    PARENT_SCOPE)
    set (${PKGCOMP}_DEFINITIONS  ${${PKGCOMP}_DEFINITIONS}  PARENT_SCOPE)
    set (${PKGCOMP}_OPTIONS      ${${PKGCOMP}_OPTIONS}      PARENT_SCOPE)
    set (${PKGCOMP}_IS_SHARED    ${${PKGCOMP}_IS_SHARED}    PARENT_SCOPE)

endfunction ()


