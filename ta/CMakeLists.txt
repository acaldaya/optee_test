project (xtest-ta-headers C)

add_library(${PROJECT_NAME} INTERFACE)

target_include_directories(${PROJECT_NAME}
	INTERFACE include
	INTERFACE aes_perf/include
	INTERFACE concurrent/include
	INTERFACE concurrent_large/include
	INTERFACE create_fail_test/include
	INTERFACE crypt/include
	INTERFACE enc_fs/include
	INTERFACE os_test/include
	INTERFACE rpc_test/include
	INTERFACE sdp_basic/include
	INTERFACE sha_perf/include
	INTERFACE sims/include
	INTERFACE miss/include
	INTERFACE sims_keepalive/include
	INTERFACE socket/include
	INTERFACE storage_benchmark/include
	INTERFACE tpm_log_test/include
	INTERFACE bti_test/include
	INTERFACE supp_plugin/include
	INTERFACE large/include
)

macro(build_ta TA)
    execute_process(
        COMMAND grep BINARY ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/Makefile
        OUTPUT_VARIABLE TA_UUID
        RESULT_VARIABLE ERROR)

    if (NOT "${ERROR}" STREQUAL 0)
        message(FATAL_ERROR "Error parsing the UUID")
    endif()

    string(REPLACE "BINARY" "" TA_UUID ${TA_UUID})
    string(REPLACE "=" "" TA_UUID ${TA_UUID})
	string(STRIP ${TA_UUID} TA_UUID)

    message(STATUS "Building TA ${TA} with UUID: ${TA_UUID}")

	# Split UUID to init a TEE_UUID C data type
	#e626662e-c0e2-485c-b8c8-09fbce6edf3d
	string(SUBSTRING ${TA_UUID} 0  8 UUID_0)
	string(SUBSTRING ${TA_UUID} 9  4 UUID_1)
	string(SUBSTRING ${TA_UUID} 14 4 UUID_2)
	string(SUBSTRING ${TA_UUID} 19 2 UUID_3_1)
	string(SUBSTRING ${TA_UUID} 21 2 UUID_3_2)

	string(SUBSTRING ${TA_UUID} 24 2 UUID_4)
	string(SUBSTRING ${TA_UUID} 26 2 UUID_5)
	string(SUBSTRING ${TA_UUID} 28 2 UUID_6)
	string(SUBSTRING ${TA_UUID} 30 2 UUID_7)
	string(SUBSTRING ${TA_UUID} 32 2 UUID_8)
	string(SUBSTRING ${TA_UUID} 34 2 UUID_9)

	# { 0x12345678, 0x8765, 0x4321, { 'D', 'I', 'G', 'E', 'S', 'T', '0', '0'} }, /* UUID */
	set(C_UUID "{0x${UUID_0}, 0x${UUID_1}, 0x${UUID_2}, { 0x${UUID_3_1}, 0x${UUID_3_2}, 0x${UUID_4}, 0x${UUID_5}, 0x${UUID_6}, 0x${UUID_7}, 0x${UUID_8}, 0x${UUID_9}} },")

	set(TEE_INTERNAL_API_INCLUDES
			-I${CMAKE_CURRENT_SOURCE_DIR}/../../optee_os/lib/libutee/include
			-I${CMAKE_CURRENT_SOURCE_DIR}/../../optee_os/lib/libutils/ext/include)

	# This replaces TA_TEE_UUID by the TEE_UUID initialization in ${TA}/ta_properties.c
	set(TA_TEE_UUID ${C_UUID})
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/ta_properties.c.in ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/ta_properties.c @ONLY)

	# TODO: we add ta_entry.c and ta_$TA.c, however it might be others, or eg. ta_$TA.c doesn't exist
	set(SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/ta_properties.c ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/ta_entry.c  ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/ta_${TA}.c)

	# TODO: make this part of the build process instead of cmake, spliting build from install (it is causing a race condition in the OpenTEE manager)
	execute_process(
        COMMAND sudo gcc ${SRC_FILES} -I${CMAKE_CURRENT_SOURCE_DIR}/${TA}/include ${TEE_INTERNAL_API_INCLUDES} -shared -fPIC -o /opt/OpenTee/lib/TAs/lib${TA}.so
        OUTPUT_VARIABLE GCC_ERRORS
        RESULT_VARIABLE ERROR)

	if (NOT "${ERROR}" STREQUAL 0)
        message(FATAL_ERROR "Build ${TA} failed:")
		message(FATAL_ERROR ${GCC_ERRORS})
    endif()

endmacro()

build_ta(aes_perf)
build_ta(sha_perf)