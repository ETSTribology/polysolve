# SuperLU solver configuration
if(TARGET SuperLU::SuperLU)
    return()
endif()

message(STATUS "Third-party: creating target 'SuperLU::SuperLU'")

# 1. Modern package search with multiple fallbacks
find_package(SuperLU CONFIG QUIET
    NAMES SuperLU superlu
    HINTS ${SuperLU_DIR} ${CMAKE_PREFIX_PATH}
    PATH_SUFFIXES 
        lib/cmake/SuperLU
        lib/cmake/superlu
        lib64/cmake/SuperLU
        share/superlu
)

if(NOT SuperLU_FOUND)
    # Fallback to module mode with improved search paths
    find_package(SUPERLU QUIET
        HINTS ${SuperLU_DIR} ${CMAKE_PREFIX_PATH}
        PATH_SUFFIXES
            lib
            lib64
            lib32
            include
            SuperLU
            superlu
    )
endif()

# 2. Unified target creation with modern CMake practices
if(SuperLU_FOUND AND TARGET SuperLU::SuperLU)
    message(STATUS "Found SuperLU (Config): ${SuperLU_DIR}")
    
    # Verify target properties
    get_target_property(_superlu_incs SuperLU::SuperLU INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(_superlu_libs SuperLU::SuperLU INTERFACE_LINK_LIBRARIES)
    
    message(VERBOSE "SuperLU includes: ${_superlu_incs}")
    message(VERBOSE "SuperLU libraries: ${_superlu_libs}")
    
elseif(SUPERLU_FOUND)
    # Legacy module mode setup with enhanced validation
    message(STATUS "Found SuperLU via legacy FindSUPERLU")
    
    add_library(SuperLU::SuperLU INTERFACE IMPORTED)
    
    # Validate and set include directories
    if(SUPERLU_INCLUDE_DIR)
        message(STATUS "SuperLU includes: ${SUPERLU_INCLUDE_DIR}")
        target_include_directories(SuperLU::SuperLU INTERFACE ${SUPERLU_INCLUDE_DIR})
    else()
        message(WARNING "SUPERLU_INCLUDE_DIR not set!")
    endif()

    # Validate and set libraries
    if(SUPERLU_LIBRARIES)
        message(STATUS "SuperLU libraries: ${SUPERLU_LIBRARIES}")
        target_link_libraries(SuperLU::SuperLU INTERFACE ${SUPERLU_LIBRARIES})
    else()
        message(WARNING "SUPERLU_LIBRARIES not set!")
    endif()

    # 3. Handle dependencies
    find_package(OpenMP COMPONENTS CXX)
    if(OpenMP_CXX_FOUND)
        target_link_libraries(SuperLU::SuperLU INTERFACE OpenMP::OpenMP_CXX)
    endif()

    # Check for METIS support
    if(SUPERLU_WITH_METIS)
        find_package(METIS REQUIRED)
        target_link_libraries(SuperLU::SuperLU INTERFACE METIS::METIS)
    elseif(EXISTS "${SUPERLU_INCLUDE_DIR}/slu_ddefs.h")
        file(STRINGS "${SUPERLU_INCLUDE_DIR}/slu_ddefs.h" SUPERLU_METIS_VER 
            REGEX "#define HAVE_METIS")
        if(SUPERLU_METIS_VER)
            message(STATUS "SuperLU built with METIS support")
            find_package(METIS QUIET)
            if(METIS_FOUND)
                target_link_libraries(SuperLU::SuperLU INTERFACE METIS::METIS)
            else()
                message(WARNING "METIS not found but required by SuperLU")
            endif()
        endif()
    endif()
    
    # Link math library
    if(UNIX AND NOT APPLE)
        target_link_libraries(SuperLU::SuperLU INTERFACE m)
    endif()

else()
    # 4. Cross-platform installation instructions
    include(CMakePrintHelpers)
    cmake_print_properties(
        PROPERTIES
        CMAKE_HOST_SYSTEM_NAME
        CMAKE_HOST_SYSTEM_VERSION
    )

    message(FATAL_ERROR "SuperLU not found! Installation options:\n"
        "  Linux (Debian/Ubuntu):   sudo apt-get install libsuperlu-dev\n"
        "  macOS (Homebrew):        brew install superlu\n"
        "  Windows (vcpkg):         vcpkg install superlu\n"
        "  From source:\n"
        "    1. git clone https://github.com/xiaoyeli/superlu.git\n"
        "    2. mkdir build && cd build\n"
        "    3. cmake .. -DCMAKE_INSTALL_PREFIX=<install-path> \\\n"
        "       -Denable_openmp=ON \\\n"
        "       -Denable_metis=ON \\\n"
        "       -DBUILD_SHARED_LIBS=ON\n"
        "    4. cmake --build . --target install\n"
        "Set SuperLU_DIR to <install-path> if using custom location\n"
        "Current search paths: ${CMAKE_PREFIX_PATH}"
    )
endif()

# 5. Version compatibility check
if(SuperLU_VERSION VERSION_LESS 5.3.0)
    message(WARNING "SuperLU version ${SuperLU_VERSION} is older than recommended 5.3.0+")
endif()

# 6. Cross-platform verification
add_custom_target(check_superlu_config
    COMMAND ${CMAKE_COMMAND} -E echo "Checking SuperLU configuration..."
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/superlu_check"
    COMMAND ${CMAKE_COMMAND} -E touch "${CMAKE_BINARY_DIR}/superlu_check/test_superlu.cpp"
    COMMAND ${CMAKE_CXX_COMPILER} 
        -std=c++11 
        -I$<TARGET_PROPERTY:SuperLU::SuperLU,INTERFACE_INCLUDE_DIRECTORIES>
        -L$<TARGET_PROPERTY:SuperLU::SuperLU,INTERFACE_LINK_DIRECTORIES>
        -o "${CMAKE_BINARY_DIR}/superlu_check/test_superlu" 
        "${CMAKE_BINARY_DIR}/superlu_check/test_superlu.cpp" 
        $<TARGET_PROPERTY:SuperLU::SuperLU,INTERFACE_LINK_LIBRARIES>
    COMMENT "Verifying SuperLU configuration"
    VERBATIM
)
