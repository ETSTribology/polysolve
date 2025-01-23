if(TARGET CUDA::cusolver)
    return()
endif()

message(STATUS "Third-party: creating targets 'CUDA::cusolver'")

include(CheckLanguage)
check_language(CUDA)
if(CMAKE_CUDA_COMPILER)
    enable_language(CUDA)

    find_package(CUDAToolkit REQUIRED)
    if(CUDAToolkit_FOUND)
        # Set CUDA architectures explicitly for target
        set(CMAKE_CUDA_ARCHITECTURES "75" CACHE STRING "GPU compute capabilities (e.g., 75 for RTX8000)")

        # Add CUDA source files to specific target
        target_sources(polysolve_linear PRIVATE src/polysolve/linear/CuSolverDN.cu)

        # Configure target-specific CUDA properties
        target_compile_options(polysolve_linear PRIVATE 
            $<$<COMPILE_LANGUAGE:CUDA>: 
            --use_fast_math 
            --expt-relaxed-constexpr
            >
        )

        # Link CUDA libraries to linear solver only
        target_link_libraries(polysolve_linear PRIVATE 
            CUDA::cusolver
            CUDA::cudart
        )

        # Set properties for separable compilation
        set_target_properties(polysolve_linear PROPERTIES
            CUDA_SEPARABLE_COMPILATION ON
            CUDA_RESOLVE_DEVICE_SYMBOLS ON
        )

        # Add CUDA include directories
        target_include_directories(polysolve_linear SYSTEM PRIVATE
            ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
        )

    else()
        message(WARNING "cuSOLVER not found, solver will not be available.")
    endif()
else()
    message(WARNING "CUDA not found, cuSOLVER will not be available.")
endif()
