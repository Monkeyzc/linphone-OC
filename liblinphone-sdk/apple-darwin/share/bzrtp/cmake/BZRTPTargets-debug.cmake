#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "bzrtp-static" for configuration "Debug"
set_property(TARGET bzrtp-static APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(bzrtp-static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "C"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libbzrtp.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS bzrtp-static )
list(APPEND _IMPORT_CHECK_FILES_FOR_bzrtp-static "${_IMPORT_PREFIX}/lib/libbzrtp.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
