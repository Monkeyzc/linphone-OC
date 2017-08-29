#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "linphone" for configuration "Debug"
set_property(TARGET linphone APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(linphone PROPERTIES
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/Frameworks/linphone.framework/linphone"
  IMPORTED_SONAME_DEBUG "@rpath/linphone.framework/linphone"
  )

list(APPEND _IMPORT_CHECK_TARGETS linphone )
list(APPEND _IMPORT_CHECK_FILES_FOR_linphone "${_IMPORT_PREFIX}/Frameworks/linphone.framework/linphone" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
