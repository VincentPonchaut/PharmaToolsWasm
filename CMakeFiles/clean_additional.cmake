# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Release")
  file(REMOVE_RECURSE
  "CMakeFiles/appPharmaToolsApp_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/appPharmaToolsApp_autogen.dir/ParseCache.txt"
  "appPharmaToolsApp_autogen"
  )
endif()
