cmake_minimum_required(VERSION 3.27)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# # use, i.e. don't skip the full RPATH for the build tree
# set(CMAKE_SKIP_BUILD_RPATH FALSE)
#
# # when building, don't use the install RPATH already
# # (but later on when installing)
# set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
# set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
#
# # add the automatically determined parts of the RPATH
# # which point to directories outside the build tree to the install RPATH
# set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# project(test VERSION 1.0 LANGUAGES CXX)
project(test VERSION 1.0 LANGUAGES CXX)

find_package(fmt CONFIG REQUIRED)

add_executable(test "main.cpp")
target_compile_options(test PRIVATE -stdlib=libstdc++ -fcolor-diagnostics -Wno-unused-command-line-argument)
target_link_options(test PRIVATE -fuse-ld=lld -stdlib=libstdc++)

# I deliberately disabled linking to `fmt`, so also headers files should not be found.
# But Nix wrapps clang which adds fmt's include dir.... (I dont want this)
target_link_libraries(test PUBLIC fmt::fmt)

install(TARGETS test)
