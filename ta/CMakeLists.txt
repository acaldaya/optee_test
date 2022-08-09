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

	set(TEE_INTERNAL_API_INCLUDES
			-I${CMAKE_CURRENT_SOURCE_DIR}/../../optee_os/lib/libutee/include
			-I${CMAKE_CURRENT_SOURCE_DIR}/../../optee_os/lib/libutils/ext/include)

	# Generate ta_properties.c from template
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/ta_properties.c.in ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/ta_properties.c)

	# Grab TA src files
	file(GLOB SRC_FILES CONFIGURE_DEPENDS  "${CMAKE_CURRENT_SOURCE_DIR}/${TA}/*.c")
	list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/mbedtls_taf.c)
	list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/ta_arm_pauth.c)
	list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/test_float_subj.c) # TODO: maybe include it later?
	list(REMOVE_ITEM SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/${TA}/cxx_tests_c.c) # TODO: include if CXX tests

	# Build TA as shared libraries to satisfy OpenTEE
	add_library(${TA} SHARED ${SRC_FILES})

	# We use OPTEE Internal API defs as they should be a superset of OpenTEE's
	target_include_directories(${TA} PRIVATE
		${CMAKE_CURRENT_SOURCE_DIR}/${TA}/include
		${CMAKE_CURRENT_SOURCE_DIR}/../../optee_os/lib/libutee/include
		${CMAKE_CURRENT_SOURCE_DIR}/../../optee_os/lib/libutils/ext/include)

	# Install TAs in OpenTEE default dir
	install(TARGETS ${TA} DESTINATION /opt/OpenTee/lib/TAs)

	# TA specific setups
	if ("${TA}" STREQUAL "os_test")
		target_include_directories(${TA} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/crypt/include)
		target_include_directories(${TA} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/os_test_lib/include)
	endif()

	if ("${TA}" STREQUAL "sims_keepalive")
		target_include_directories(${TA} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/sims/include)
	endif()

	if ("${TA}" STREQUAL "miss")
		target_include_directories(${TA} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/sims/include)
	endif()

	if ("${TA}" STREQUAL "concurrent_large")
		target_include_directories(${TA} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/concurrent/include)
	endif()

	if ("${TA}" STREQUAL "rpc_test")
		target_include_directories(${TA} PRIVATE
			${CMAKE_CURRENT_SOURCE_DIR}/crypt/include
			${CMAKE_CURRENT_SOURCE_DIR}/sims/include)
	endif()

endmacro()

# Preprocessor flags to disable some code
# all disabled by default
# CFG_TA_LIB
# CFG_MEMTAG
# CFG_PTA_CORRUPT_TA
# CFG_TA2TA_MEMREF
# CFG_TEST_PROPERTIES (OpenTee doesn't have properties)
# CFG_ENABLE_TEE_OpenTASession_TO_SELF (see os_tests.c)

# flags treated in sub.mk (TODO: include them here)
# CFG_TA_PAUTH
# cppflags-$(CFG_TA_FLOAT_SUPPORT) += -DCFG_TA_FLOAT_SUPPORT=1
# cppflags-$(WITH_TLS_TESTS) += -DWITH_TLS_TESTS=1
# cppflags-$(WITH_CXX_TESTS) += -DWITH_CXX_TESTS=1
# cflags-y += -Wno-float-equal
# srcs-$(CFG_TA_FLOAT_SUPPORT) += test_float_subj.c

build_ta(aes_perf)
build_ta(sha_perf)
build_ta(crypt)
build_ta(concurrent)
build_ta(concurrent_large)
build_ta(os_test)
build_ta(create_fail_test)
build_ta(sims)
build_ta(sims_keepalive)
build_ta(miss)
build_ta(rpc_test)
build_ta(large)
