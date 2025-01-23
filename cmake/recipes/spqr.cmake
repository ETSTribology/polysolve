# SPQR solver configuration
if(TARGET SuiteSparse::SPQR)
    return()
endif()

message(STATUS "Third-party: creating target 'SuiteSparse::SPQR'")

# 1. Find OpenMP (with modern CMake target approach)
find_package(OpenMP COMPONENTS CXX)
if(OpenMP_CXX_FOUND)
    message(STATUS "Found OpenMP: ${OpenMP_CXX_VERSION}")
    add_library(OpenMP::OpenMP_CXX IMPORTED INTERFACE)
    set_property(TARGET OpenMP::OpenMP_CXX PROPERTY
        INTERFACE_COMPILE_OPTIONS ${OpenMP_CXX_COMPILE_OPTIONS}
    )
    set_property(TARGET OpenMP::OpenMP_CXX PROPERTY
        INTERFACE_LINK_LIBRARIES ${OpenMP_CXX_LINK_LIBRARIES}
    )
else()
    message(WARNING "OpenMP not found - performance may be limited")
endif()

# 2. Find SuiteSparse components using modern CMake conventions
find_package(SuiteSparse_config QUIET)
if(NOT SuiteSparse_config_FOUND)
    message(STATUS "SuiteSparse_config not found, attempting to find package")
    find_package(SuiteSparse COMPONENTS config QUIET)
endif()

if(NOT SuiteSparse_config_FOUND)
    # Provide installation instructions for different platforms
    include(CMakePrintHelpers)
    cmake_print_properties(
        PROPERTIES
        CMAKE_HOST_SYSTEM_NAME
        CMAKE_HOST_SYSTEM_VERSION
    )

    message(FATAL_ERROR "SuiteSparse_config not found! Install with:\n"
        "  Linux (Debian/Ubuntu): sudo apt-get install libsuitesparse-dev\n"
        "  macOS (Homebrew): brew install suite-sparse\n"
        "  Windows (vcpkg): vcpkg install suitesparse\n"
        "  From source: https://github.com/DrTimothyAldenDavis/SuiteSparse"
    )
endif()

# 3. Find SPQR with improved cross-platform support
find_package(SPQR QUIET)
if(NOT SPQR_FOUND)
    # Try alternative naming conventions
    find_package(SuiteSparse COMPONENTS SPQR QUIET)
endif()

if(SPQR_FOUND AND TARGET SuiteSparse::SPQR)
    message(STATUS "Found SPQR: ${SPQR_LIBRARIES}")
    
    # Verify and link dependencies
    if(TARGET SuiteSparse::SuiteSparse_config AND TARGET OpenMP::OpenMP_CXX)
        target_link_libraries(SuiteSparse::SPQR 
            INTERFACE 
            SuiteSparse::SuiteSparse_config
            OpenMP::OpenMP_CXX
            ${CMAKE_DL_LIBS}  # For dynamic loading
            m  # Math library
        )
    endif()
else()
    # Enhanced error reporting
    include(FeatureSummary)
    set_package_properties(SPQR PROPERTIES
        URL "https://people.engr.tamu.edu/davis/suitesparse.html"
        DESCRIPTION "Sparse QR factorization library"
        TYPE RECOMMENDED
    )
    
    message(FATAL_ERROR "SPQR not found! Required for sparse QR factorization.\n"
        "Installation options:\n"
        "  - System package:\n"
        "    Linux: libsuitesparse-dev or libspqr-dev\n"
        "    macOS: suite-sparse via Homebrew\n"
        "  - Build from source:\n"
        "    https://github.com/DrTimothyAldenDavis/SuiteSparse\n"
        "  - Set SuiteSparse_DIR to installation prefix\n"
        "Current search paths: ${CMAKE_PREFIX_PATH}"
    )
endif()

# 4. Add version compatibility check
if(SPQR_VERSION VERSION_LESS 2.0.0)
    message(WARNING "SPQR version ${SPQR_VERSION} is older than recommended 2.0.0+")
endif()

# 5. Handle Windows-specific requirements
if(WIN32)
    # Add required Windows libraries
    target_link_libraries(SuiteSparse::SPQR INTERFACE ws2_32)
endif()
