project(test)

find_package(fmt CONFIG REQUIRED)
add_executable(test "main.cpp")

# I deliberately disabled linking to `fmt`, so also headers files should not be found.
# But Nix wrapps clang which adds fmt's include dir.... (I dont want this)
# target_link_libraries(test PUBLIC fmt::fmt)
