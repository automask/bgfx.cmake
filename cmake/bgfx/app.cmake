include(${CMAKE_CURRENT_LIST_DIR}/3rdparty/dear-imgui.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/3rdparty/meshoptimizer.cmake)

# bgfx.cmake\cmake\bgfx\myapp.cmake
# -----------------------------------------------------
include(CMakeParseArguments)

include(${CMAKE_CURRENT_LIST_DIR}/util/ConfigureDebugging.cmake)

include(${CMAKE_CURRENT_LIST_DIR}/../bgfxToolUtils.cmake)

function(add_bgfx_shader FILE FOLDER)
	get_filename_component(FILENAME "${FILE}" NAME_WE)
	string(SUBSTRING "${FILENAME}" 0 2 TYPE)

	if("${TYPE}" STREQUAL "fs")
		set(TYPE "FRAGMENT")
	elseif("${TYPE}" STREQUAL "vs")
		set(TYPE "VERTEX")
	elseif("${TYPE}" STREQUAL "cs")
		set(TYPE "COMPUTE")
	else()
		set(TYPE "")
	endif()

	set(__my_output_path ${CMAKE_CURRENT_BINARY_DIR}/Debug)

	if(NOT "${TYPE}" STREQUAL "")
		set(COMMON FILE ${FILE} ${TYPE} INCLUDES ${BGFX_DIR}/src)
		set(OUTPUTS "")
		set(OUTPUTS_PRETTY "")

		if(WIN32)
			# dx11
			# set(DX11_OUTPUT ${BGFX_DIR}/examples/runtime/shaders/dx11/${FILENAME}.bin)
			set(DX11_OUTPUT ${__my_output_path}/shaders/dx11/${FILENAME}.bin)

			if(NOT "${TYPE}" STREQUAL "COMPUTE")
				_bgfx_shaderc_parse(
					DX11 ${COMMON} WINDOWS
					PROFILE s_5_0
					O 3
					OUTPUT ${DX11_OUTPUT}
				)
			else()
				_bgfx_shaderc_parse(
					DX11 ${COMMON} WINDOWS
					PROFILE s_5_0
					O 1
					OUTPUT ${DX11_OUTPUT}
				)
			endif()

			list(APPEND OUTPUTS "DX11")
			set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}DX11, ")
		endif()

		# essl
		if(NOT "${TYPE}" STREQUAL "COMPUTE")
			set(ESSL_OUTPUT ${BGFX_DIR}/examples/runtime/shaders/essl/${FILENAME}.bin)
			_bgfx_shaderc_parse(ESSL ${COMMON} ANDROID PROFILE 100_es OUTPUT ${ESSL_OUTPUT})
			list(APPEND OUTPUTS "ESSL")
			set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}ESSL, ")
		endif()

		# glsl
		# set(GLSL_OUTPUT ${BGFX_DIR}/examples/runtime/shaders/glsl/${FILENAME}.bin)
		set(GLSL_OUTPUT ${__my_output_path}/shaders/glsl/${FILENAME}.bin)

		if(NOT "${TYPE}" STREQUAL "COMPUTE")
			_bgfx_shaderc_parse(GLSL ${COMMON} LINUX PROFILE 140 OUTPUT ${GLSL_OUTPUT})
		else()
			_bgfx_shaderc_parse(GLSL ${COMMON} LINUX PROFILE 430 OUTPUT ${GLSL_OUTPUT})
		endif()

		list(APPEND OUTPUTS "GLSL")
		set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}GLSL, ")

		# spirv
		if(NOT "${TYPE}" STREQUAL "COMPUTE")
			# set(SPIRV_OUTPUT ${BGFX_DIR}/examples/runtime/shaders/spirv/${FILENAME}.bin)
			set(SPIRV_OUTPUT ${__my_output_path}/shaders/spirv/${FILENAME}.bin)
			_bgfx_shaderc_parse(SPIRV ${COMMON} LINUX PROFILE spirv OUTPUT ${SPIRV_OUTPUT})
			list(APPEND OUTPUTS "SPIRV")
			set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}SPIRV")
			set(OUTPUT_FILES "")
			set(COMMANDS "")
		endif()

		foreach(OUT ${OUTPUTS})
			list(APPEND OUTPUT_FILES ${${OUT}_OUTPUT})
			list(APPEND COMMANDS COMMAND "bgfx::shaderc" ${${OUT}})
			get_filename_component(OUT_DIR ${${OUT}_OUTPUT} DIRECTORY)
			file(MAKE_DIRECTORY ${OUT_DIR})
		endforeach()

		file(RELATIVE_PATH PRINT_NAME ${BGFX_DIR}/examples ${FILE})
		add_custom_command(
			MAIN_DEPENDENCY ${FILE} OUTPUT ${OUTPUT_FILES} ${COMMANDS}
			COMMENT "Compiling shader ${PRINT_NAME} for ${OUTPUTS_PRETTY}"
		)
	endif()
endfunction()

function(add_common_lib ARG_NAME)
	cmake_parse_arguments(ARG "" "" "DIRECTORIES;SOURCES" ${ARGN})
	set(__name ${ARG_NAME})

	set(SOURCES "")
	set(SHADERS "")

	foreach(DIR ${ARG_DIRECTORIES})
		file(GLOB GLOB_SOURCES ${DIR}/*.c ${DIR}/*.cpp ${DIR}/*.h ${DIR}/*.sc)
		list(APPEND SOURCES ${GLOB_SOURCES})
		file(GLOB GLOB_SHADERS ${DIR}/*.sc)
		list(APPEND SHADERS ${GLOB_SHADERS})
	endforeach()

	# Add target
	# EXCLUDE_FROM_ALL 不显示在 target 列表中
	add_library(
		${__name} STATIC EXCLUDE_FROM_ALL ${SOURCES} ${DEAR_IMGUI_SOURCES} ${MESHOPTIMIZER_SOURCES}
	)
	target_include_directories(
		${__name} PUBLIC ${BGFX_DIR}/examples/common ${DEAR_IMGUI_INCLUDE_DIR}
		${MESHOPTIMIZER_INCLUDE_DIR}
	)
	target_link_libraries(
		${__name} PUBLIC bgfx bx bimg bimg_decode ${DEAR_IMGUI_LIBRARIES} ${MESHOPTIMIZER_LIBRARIES}
	)

	if(BGFX_WITH_GLFW)
		find_package(glfw3 REQUIRED)
		target_link_libraries(${__name} PUBLIC glfw)
		target_compile_definitions(${__name} PUBLIC ENTRY_CONFIG_USE_GLFW)
	elseif(BGFX_WITH_SDL)
		find_package(SDL2 REQUIRED)
		target_link_libraries(${__name} PUBLIC ${SDL2_LIBRARIES})
		target_compile_definitions(${__name} PUBLIC ENTRY_CONFIG_USE_SDL)
	endif()

	target_compile_definitions(
		${__name}
		PRIVATE "-D_CRT_SECURE_NO_WARNINGS" #
		"-D__STDC_FORMAT_MACROS" #
		"-DENTRY_CONFIG_IMPLEMENT_MAIN=1" #
	)
endfunction()

function(add_bgfx_app ARG_NAME)
	set(__name bgfx_${ARG_NAME})

	set(__dir ${BGFX_DIR}/examples/${ARG_NAME})
	file(GLOB __srcs
		${__dir}/*.c
		${__dir}/*.cpp
		${__dir}/*.h
		${__dir}/*.sc
	)
	file(GLOB __shaders
		${__dir}/*.sc
	)

	# Add target
	add_executable(${__name} WIN32 ${__srcs})

	if(NOT BGFX_INSTALL_EXAMPLES)
		set_property(TARGET ${__name} PROPERTY EXCLUDE_FROM_ALL ON)
	endif()

	target_link_libraries(${__name} PUBLIC bgfx_common)

	if(MSVC)
		set_target_properties(${__name} PROPERTIES LINK_FLAGS "/ENTRY:\"mainCRTStartup\"")
	endif()

	target_compile_definitions(
		${__name}
		PRIVATE "-D_CRT_SECURE_NO_WARNINGS"
		"-D__STDC_FORMAT_MACROS"
		"-DENTRY_CONFIG_IMPLEMENT_MAIN=1"
	)

	# add shaders
	foreach(SHADER ${__shaders})
		add_bgfx_shader(${SHADER} ${ARG_NAME})
	endforeach()

	source_group("Shader Files" FILES ${__shaders})
endfunction()

add_common_lib(
	bgfx_common
	DIRECTORIES
	${BGFX_DIR}/examples/common
	${BGFX_DIR}/examples/common/debugdraw
	${BGFX_DIR}/examples/common/entry
	${BGFX_DIR}/examples/common/font
	${BGFX_DIR}/examples/common/imgui
	${BGFX_DIR}/examples/common/nanovg
	${BGFX_DIR}/examples/common/ps
)
