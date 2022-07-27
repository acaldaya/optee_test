# OP-TEE sanity testsuite
This git contains source code for the test suite (xtest) used to test the
OP-TEE project.

All official OP-TEE documentation has moved to http://optee.readthedocs.io. The
information that used to be here in this git can be found under [optee_test].

// OP-TEE core maintainers

[optee_test]: https://optee.readthedocs.io/en/latest/building/gits/optee_test.html

# OpenTEE integration

The idea is to run `xtest` using OpenTEE as backend.

OpenTEE is outdated wrt OPTEE GlobalPlatform TEE spec versions,
therefore there are some tests/features/code that won't work.

This setup builds for x86.
When we collect which tests OpenTEE supports, we can migrate it to RISC-V (Keystone).

## Setup

Expected dir layout:

```
<root_dir>
    openssl-1.1.1n/
    opentee/
        build/
    optee_os/
    optee_test/
        build/
```

### Clone OPTEE OS

xtest build source files assume optee_os sources are
available to grab some includes.
So, we just clone it without building it.

At <root_dir>

git clone https://github.com/OP-TEE/optee_os

### Build OpenSSL 1.1.1n

At <root_dir>

```bash
wget https://www.openssl.org/source/openssl-1.1.1n.tar.gz
tar xf openssl-1.1.1n.tar.gz
cd openssl-1.1.1n
./config no-shared no-threads no-hw
make -j
```

Libraries will be at `openssl-1.1.1n` dir, so no need to install.

### Build OpenTEE

We use a modified Docker container.

**TODO:** document the docker changes

These instructions are based on OpenTEE's README.
Inside the container:

```bash
# Google repo (skip if you already have it)
mkdir -p ~/bin
curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod +x ~/bin/repo

# Clone opentee
mkdir opentee && cd opentee
~/bin/repo init -u https://github.com/Open-TEE/manifest.git
~/bin/repo sync -j10

# Build opentee and install
# Note: Install location is "/opt/OpenTee"
cd opentee
mkdir build && cd build
../autogen.sh
make -j && sudo make install

# Test the installation:
# starts OpenTEE
/opt/OpenTee/bin/opentee-engine -f &
# run sample program (takes a while)
/opt/OpenTee/bin/conn_test
# another (quick)
/opt/OpenTee/bin/example_sha1
# close OpenTEE
fg
# Control+C

# If sample programs run, it means installation is OK
# then we prepare OpenTEE for building OPTEE xtest:
ln -s ../libtee/include/tee_api_types.h ../libtee/include/tee_shared_data_types.h
```

_NOTE:_ there are more samples in `/opt/OpenTee/bin/` but they might not work (eg. `pkcs11_test`).

## Instructions

### Compiling optee_test

**TODO:** make our repo

At <root_dir>:

```bash
git clone https://github.com/OP-TEE/optee_test
# Swithching to our branch
git checkout ac/standalone

cd optee_test
mkdir -p build && cd build
cmake ..
```

For building the `xtest` host application and the TAs run `make`.
`sudo make install` will put the TAs in OpenTEE directory: `/opt/OpenTee/lib/TAs`

Currently, only two TAs are tested: `sha_perf` and `aes_perf`.

If everything goes smooth we can start testing the integration:

```bash
# Lets start OpenTEE
/opt/OpenTee/bin/opentee-engine -f &
# it will collect the TAs in /opt/OpenTee/lib/TAs
# we start it in foreground and send it to bg to close it later easly

# Running xtest
host/xtest/xtest --sha-perf

host/xtest/xtest --aes-perf -m CBC

# Several tests don't work because OpenTEE and OPTEE xtest GP versions differ.
# For instance: `host/xtest/xtest --aes-perf -m ECB` fails as ECB is not implemented in OpenTEE.

# Closing OpenTEE
fg # to bring opentee-engine to foreground then Control+C
```

To reinstall the TAs, we **MUST** close OpenTEE first, then run `sudo make install`.

You can see OpenTEE logs in host environment syslog: `sudo tail -f /var/log/syslog`
