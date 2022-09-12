#========================== MANTA PROJECT ==============================//
#============== Dockerfile to build a full MANTA container =============//
# Stage 1. Compile and install LLVM, Linux kernel bitcode, and MANTA.
FROM ubuntu:focal as builder
LABEL maintainer "watchd0g"
WORKDIR project-dir
ARG DEBIAN_FRONTEND=noninteractive
# Install build dependencies of llvm and Linux kernel.
# Install compiler, python and subversion.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates gnupg python3-pip \
           build-essential python python3 wget subversion unzip ninja-build \
           cmake libncurses-dev gawk flex bison openssl libssl-dev dkms \
           libelf-dev libudev-dev libpci-dev libiberty-dev autoconf file bc && \
    rm -rf /var/lib/apt/lists/*
RUN pip install wllvm
# Install a newer ninja release.
RUN wget "https://github.com/ninja-build/ninja/releases/download/v1.11.0/ninja-linux.zip" && \
    unzip ninja-linux.zip -d /usr/local/bin && \
    rm ninja-linux.zip

RUN mkdir llvm-project linux-kernel manta build z3
RUN wget "https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-12.0.0.tar.gz" && \
    tar -zxvf llvmorg-12.0.0.tar.gz --strip-components=1 -C llvm-project && \
    rm llvmorg-12.0.0.tar.gz

RUN wget "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.19.tar.xz" && \
    tar -xvf linux-5.10.19.tar.xz --strip-components=1 -C linux-kernel && \
    rm linux-5.10.19.tar.xz

RUN wget "https://github.com/Z3Prover/z3/archive/refs/tags/z3-4.10.0.tar.gz" && \
    tar -zxvf z3-4.10.0.tar.gz --strip-components=1 -C z3 && \
    rm z3-4.10.0.tar.gz

RUN pip install wllvm

# Copy manta source code and decompress.
COPY manta-src.tar.gz .
RUN tar -zxvf manta-src.tar.gz --strip-components=2 -C manta && \
    rm manta-src.tar.gz

COPY Makefile .
# Start build process.
RUN make llvm
RUN make z3
RUN make manta
# Copy Linux kernel config.
COPY memcg_defconfig linux-kernel/arch/x86/configs/memcg_defconfig
RUN make kernel-bitcode

# Stage 2. Build a minimal runtime environment for MANTA.
FROM ubuntu:focal
LABEL maintainer "watchd0g"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates gnupg \
           build-essential python python3 subversion unzip && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /project-dir/build/output/bin /usr/local/bin
COPY --from=builder /project-dir/build/output/include /usr/local/include
COPY --from=builder /project-dir/build/output/lib /usr/local/lib
COPY --from=builder /project-dir/build/output/libexec /usr/local/libexec
COPY --from=builder /project-dir/build/output/share /usr/local/share
COPY --from=builder /project-dir/build/kernel-bitcode/vmlinux.bc /

RUN printf "#!/bin/sh\nopt -analyze -load=/usr/local/lib/libmemcg_bughunt.so -mergereturn -memcg-bughunt -o /dev/null vmlinux.bc" > run-manta.sh
RUN chmod +x run-manta.sh
COPY format-result.py /
