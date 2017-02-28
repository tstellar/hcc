// REQUIRES: x86-registered-target
// REQUIRES: nvptx-registered-target

// RUN: %clang_cc1 -triple nvptx64-nvidia-cuda -fcuda-is-device -emit-llvm \
// RUN:   -o - %s | FileCheck -check-prefixes=CHECK,NVPTX %s

// RUN: %clang_cc1 -triple amdgcn-amd-amdhsa -fcuda-is-device -emit-llvm \
// RUN:   -o - %s | FileCheck -check-prefixes=CHECK,AMDGCN %s

#include "Inputs/cuda.h"

extern "C" __device__ int vprintf(const char*, const char*);

// Check a simple call to printf end-to-end.
// CHECK: [[SIMPLE_PRINTF_TY:%[a-zA-Z0-9_]+]] = type { i32, i64, double }
// CHECK-LABEL: define i32 @_Z11CheckSimplev()
__device__ int CheckSimple() {
  // NVPTX: [[BUF:%[a-zA-Z0-9_]+]] = alloca [[SIMPLE_PRINTF_TY]]
  // AMDGCN: [[ALLOCA:%[a-zA-Z0-9_]+]] = alloca [[SIMPLE_PRINTF_TY]]
  // AMDGCN: [[BUF:%[a-zA-Z0-9_]+]] = addrspacecast %printf_args* [[ALLOCA]] to %printf_args addrspace(4)*
  // CHECK: [[FMT:%[0-9]+]] = load{{.*}}%fmt
  const char* fmt = "%d %lld %f";
  // CHECK: [[PTR0:%[0-9]+]] = getelementptr inbounds [[SIMPLE_PRINTF_TY]], [[SIMPLE_PRINTF_TY]]{{.*}}* [[BUF]], i32 0, i32 0
  // CHECK: store i32 1, i32{{.*}}* [[PTR0]], align 4
  // CHECK: [[PTR1:%[0-9]+]] = getelementptr inbounds [[SIMPLE_PRINTF_TY]], [[SIMPLE_PRINTF_TY]]{{.*}}* [[BUF]], i32 0, i32 1
  // CHECK: store i64 2, i64{{.*}}* [[PTR1]], align 8
  // CHECK: [[PTR2:%[0-9]+]] = getelementptr inbounds [[SIMPLE_PRINTF_TY]], [[SIMPLE_PRINTF_TY]]{{.*}}* [[BUF]], i32 0, i32 2
  // CHECK: store double 3.0{{[^,]*}}, double{{.*}}* [[PTR2]], align 8
  // CHECK: [[BUF_CAST:%[0-9]+]] = bitcast [[SIMPLE_PRINTF_TY]]{{.*}}* [[BUF]] to i8{{.*}}*
  // CHECK: [[RET:%[0-9]+]] = call i32 @vprintf(i8{{.*}}* [[FMT]], i8{{.*}}* [[BUF_CAST]])
  // CHECK: ret i32 [[RET]]
  return printf(fmt, 1, 2ll, 3.0);
}

// CHECK-LABEL: define void @_Z11CheckNoArgsv()
__device__ void CheckNoArgs() {
  // CHECK: call i32 @vprintf({{.*}}, i8{{.*}}* null){{$}}
  printf("hello, world!");
}

// Check that printf's alloca happens in the entry block, not inside the if
// statement.
__device__ bool foo();
// CHECK-LABEL: define void @_Z25CheckAllocaIsInEntryBlockv()
__device__ void CheckAllocaIsInEntryBlock() {
  // CHECK: alloca %printf_args
  // CHECK: call {{.*}} @_Z3foov()
  if (foo()) {
    printf("%d", 42);
  }
}
