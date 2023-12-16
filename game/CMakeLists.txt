# -----------------------------------------------------------------------------

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug") # if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
endif()

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# 注意点|需要复制依赖资源|修改shader引用
# 先构建bgfx_common.lib|然后使用编译后的静态库
set(__static_lib_path ${CMAKE_SOURCE_DIR}/build/_lib)
set(__use_bgfx_common_static FALSE)
set(__use_bgfx_common_static TRUE)
set(__build_output_path ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_BUILD_TYPE})

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
include(${CMAKE_SOURCE_DIR}/cmake/bgfx/app.cmake)

add_bgfx_app(render_mesh ${CMAKE_CURRENT_SOURCE_DIR}/render_mesh)
add_bgfx_app(render_instancing ${CMAKE_CURRENT_SOURCE_DIR}/render_instancing)
add_bgfx_app(render_metaballs ${CMAKE_CURRENT_SOURCE_DIR}/render_metaballs)

copy_example_asset(bunny.bin meshes)

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
