add_executable(mkalteriso main.cpp custom_exec.cpp message.cpp path_lib.cpp build_process.cpp)
target_link_libraries(mkalteriso ssl crypto)