cmake_minimum_required(VERSION 3.20)
project(warbeast_navigation_m99 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT M99_GODOT_CPP_DIR OR NOT EXISTS "${M99_GODOT_CPP_DIR}/gdextension/extension_api.json"
    OR NOT M99_GODOT_CPP_ARCHIVE OR NOT EXISTS "${M99_GODOT_CPP_ARCHIVE}"
    OR NOT M99_GODOT_CPP_GENERATED_DIR OR NOT EXISTS "${M99_GODOT_CPP_GENERATED_DIR}/include")
  message(FATAL_ERROR "Supply the reviewed M92 vendor, generated headers and existing archive explicitly; this experiment never downloads or builds godot-cpp")
endif()
file(SHA256 "${M99_GODOT_CPP_DIR}/gdextension/extension_api.json" api_sha)
file(SHA256 "${M99_GODOT_CPP_DIR}/gdextension/gdextension_interface.h" interface_sha)
if(NOT api_sha STREQUAL "23d807e3f914f7a91b152a8a7b03638d4853f8e642b79f10ce85a43b44340bfd"
    OR NOT interface_sha STREQUAL "a40ac4fca0f526910bd0e6afc6da6c169f50801c84d4e29c4ce2891cadc7b550")
  message(FATAL_ERROR "M99 requires the exact previously reviewed godot-cpp API/interface")
endif()
add_library(warbeast_navigation_m99 SHARED navigation_graph_binding.cpp)
target_include_directories(warbeast_navigation_m99 SYSTEM PRIVATE "${M99_GODOT_CPP_DIR}/include"
  "${M99_GODOT_CPP_GENERATED_DIR}/include" "${M99_GODOT_CPP_DIR}/gdextension")
target_link_libraries(warbeast_navigation_m99 PRIVATE "${M99_GODOT_CPP_ARCHIVE}")
target_compile_definitions(warbeast_navigation_m99 PRIVATE GDEXTENSION THREADS_ENABLED)
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  target_compile_definitions(warbeast_navigation_m99 PRIVATE MACOS_ENABLED UNIX_ENABLED)
endif()
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(warbeast_navigation_m99 PRIVATE -Wall -Wextra -Werror -fno-fast-math -ffp-contract=off -fno-exceptions)
endif()
set_target_properties(warbeast_navigation_m99 PROPERTIES
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
  PREFIX "lib" OUTPUT_NAME "warbeast_navigation_m99")
