cmake_minimum_required (VERSION 3.4)
project (optee_test C)

# Default cross compile settings
# set (CMAKE_TOOLCHAIN_FILE CMakeToolchain.txt)

set (OPENSSL_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../openssl-1.1.1n)

set (OPTEE_TEST_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
################################################################################
# Compiler flags:
#   We want to use the same flags in the entire optee_client git
################################################################################
add_compile_options (
	-Wall -Wbad-function-cast -Wcast-align
	-Werror-implicit-function-declaration -Wextra
	-Wfloat-equal -Wformat-nonliteral -Wformat-security
	-Wformat=2 -Winit-self -Wmissing-declarations
	-Wmissing-format-attribute -Wmissing-include-dirs
	-Wmissing-prototypes -Wnested-externs
	-Wpointer-arith -Wshadow -Wstrict-prototypes
	-Wswitch-default -Wunsafe-loop-optimizations
	-Wwrite-strings -Werror -fPIC
 	-Wno-missing-field-initializers
	-Wno-unused-parameter
)

find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
	set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
	set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif(CCACHE_FOUND)

# Set this define globally
set(CFG_TEST_CORE_ONLY 1)

add_subdirectory (ta)
add_subdirectory (host/xtest)
# add_subdirectory (host/supp_plugin)

# Copy package to overlay
add_custom_target(reset
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/reset.sh
  COMMENT "Rebuilding xtest/TAs and force OpenTEE to reload the TAs"
  VERBATIM
)