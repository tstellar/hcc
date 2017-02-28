// RUN: %clang_cc1 -emit-llvm %s -o - -fcuda-is-device -triple nvptx64-unknown-unknown | FileCheck -check-prefix=NVPTX %s
// RUN: %clang_cc1 -emit-llvm %s -o - -fcuda-is-device -triple amdgcn-amd-amdhsa | FileCheck -check-prefix=AMDGCN %s


// Make sure we emit the proper addrspacecast for llvm.used.  PR22383 exposed an
// issue where we were generating a bitcast instead of an addrspacecast.

// NVPTX: @llvm.used = appending global [1 x i8*] [i8* addrspacecast (i8 addrspace(1)* bitcast ([0 x i32] addrspace(1)* @a to i8 addrspace(1)*) to i8*)], section "llvm.metadata"
// AMDGCN: @llvm.used = appending global [1 x i8 addrspace(4)*] [i8 addrspace(4)* addrspacecast (i8 addrspace(1)* bitcast ([0 x i32] addrspace(1)* @a to i8 addrspace(1)*) to i8 addrspace(4)*)], section "llvm.metadata"
__attribute__((device)) __attribute__((__used__)) int a[] = {};
