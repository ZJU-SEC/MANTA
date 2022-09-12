################### MANTA PROJECT ########################
################ Written by watchd0g #####################

LLVM_SRC := $(CURDIR)/llvm-project/llvm
KERNEL_SRC := $(CURDIR)/linux-kernel
Z3_SRC := $(CURDIR)/z3
MEMCG_CHK_SRC := $(CURDIR)/manta

BUILD_DIR := $(CURDIR)/build

LLVM_T := $(BUILD_DIR)/llvm
Z3_T := $(BUILD_DIR)/z3
KERNEL_BC_T := $(BUILD_DIR)/kernel-bitcode
KERNEL_EXE_T := $(BUILD_DIR)/kernel-exe
MEMCG_CHK_T := $(BUILD_DIR)/manta
KERNEL_HEADER_T := $(BUILD_DIR)/kernel-header

OUTPUT_T := $(BUILD_DIR)/output
LLVM_COMPILER = clang
LLVM_COMPILER_PATH = $(OUTPUT_T)/bin

export LLVM_COMPILER LLVM_COMPILER_PATH

prepare:
	mkdir -p $(OUTPUT_T)

llvm: prepare
	mkdir -p $(LLVM_T)
	cd $(LLVM_T) && cmake -DCMAKE_BUILD_TYPE="Release" \
		-DCMAKE_INSTALL_PREFIX=$(OUTPUT_T) \
		-DLLVM_ENABLE_PROJECTS=clang \
		-DLLVM_INSTALL_UTILS=true \
		$(LLVM_SRC)
	cmake --build $(LLVM_T) -j8 --target install

z3: prepare
	mkdir -p $(Z3_T)
	cd $(Z3_T) && cmake -DCMAKE_BUILD_TYPE="Release" \
		-DCMAKE_INSTALL_PREFIX=$(OUTPUT_T) \
		$(Z3_SRC)
	cmake --build $(Z3_T) -j8 --target install

manta: prepare
	mkdir -p $(MEMCG_CHK_T)
	cd $(MEMCG_CHK_T) && cmake -DCMAKE_INSTALL_PREFIX=$(OUTPUT_T) \
		-DCMAKE_BUILD_TYPE:STRING="Release" \
		-DLLVM_DIR=$(LLVM_T)/lib/cmake/llvm \
		-DZ3_DIR=$(OUTPUT_T)/lib/cmake/z3 \
		$(MEMCG_CHK_SRC)
	cmake --build $(MEMCG_CHK_T) -j8 --target install

kernel-bitcode: llvm
	mkdir -p $(KERNEL_BC_T)
		$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_BC_T) CC=wllvm LD=/usr/bin/ld memcg_defconfig
		$(MAKE) -C $(KERNEL_SRC) O=$(KERNEL_BC_T) CC=wllvm LD=/usr/bin/ld -j8
	extract-bc $(KERNEL_BC_T)/vmlinux



PHONY += prepare llvm manta kernel

all-clean:
	rm -rf $(BUILD_DIR)

llvm-clean:
	rm -rf $(LLVM_T)

manta-clean:
	rm -rf $(MEMCG_CHK_T)

kernel-clean:
	rm -rf $(KERNEL_HIKEY_T)

PHONY += all-clean llvm-clean manta-clean kernel-clean

.PHONY: $(PHONY)
