.. meta::
    :description: HIP programming guide
    :keywords: CU, CUs, number of CUs, compute units

.. _hip-programming-guide:

********************************************************************************
HIP programming guide
********************************************************************************

ROCm provides a robust environment for heterogeneous programs running on CPUs
and AMD GPUs. ROCm supports a variety of programming languages and frameworks to
help developers utilize the power of AMD GPUs. Currently supported programming
languages include HIP (Heterogeneous-Compute Interface for Portability), OpenCL,
Python, C++, as well as others. 

HIP is a C++-like language that provides a runtime, library APIs for GPU
programming, and is the key programming language in ROCm. HIP is also designed
to be a marshalling language, allowing code written for NVIDIA's CUDA to be
easily ported to run on AMD GPUs. Developers can use HIP to write kernels that
execute on AMD GPUs while maintaining compatibility with CUDA-based systems
through minor modifications.

OpenCL (Open Computing Language) is an open standard for cross-platform,
parallel programming of diverse processors. ROCm supports OpenCL for developers
who want to use standard frameworks across different hardware platforms,
including CPUs, GPUs, and other accelerators. Refer to XXX for more information
on OpenCL. 

ROCm also supports Python through various machine learning frameworks and
libraries like TensorFlow and PyTorch, which can leverage ROCm's GPU
acceleration. The ROCm ecosystem includes tools like ROCm MIOpen for deep
learning libraries. Python is extensively used in data science, AI, and deep
learning. Developers can write Python code that calls GPU-accelerated libraries
under the hood, abstracting much of the complexity of parallel GPU programming.
In modern use cases, Python with TensorFlow and PyTorch is popular due to its
role in AI/ML, but HIP and C++ are vital for performance-focused applications in
scientific and engineering domains.

Programming in HIP
================================================================================

When programming a heterogeneous application to run on a host CPU and offload
kernels to GPUs, especially within a framework like ROCm or using HIP, the
following are key steps and considerations to ensure efficient execution and
performance:

#. Install ROCm and HIP and setup the development environment: Get the
   appropriate toolchains, libraries, and runtime environments set up to program
   and run applications in a heterogeneous setup. For more information, see :doc:`Install ROCm on Linux <rocm-install-on-linux:index>`.

#. Understand the Target Architecture (CPU + GPU): CPUs are designed to excel at
   executing a sequence of operations and control logic as fast as possible,
   while GPUs excel at parallel execution of large workloads across many threads.
   You must target specific tasks to the appropriate architecture to optimize
   your application performance. Target computationally intensive,
   parallelizable parts to the GPU, while running control-heavy and sequential
   logic on the CPU. For more information, see :doc:`Hardware Implementation <hip:understand/hardware_implementation.html>`.

#. Write GPU Kernels for Parallel Execution: Efficient GPU kernels can greatly
   speed up computation by leveraging massive parallelism. Write kernels that
   can take advantage of GPU SIMD (Single Instruction, Multiple Data)
   architecture. Structure your code so that each thread performs independent
   tasks on different pieces of data. Ensure that each thread operates on
   independent memory locations to avoid memory contention. Avoid branching
   (e.g., if-else statements) inside kernels as much as possible, since it can
   lead to divergence, which slows down parallel execution. For more
   information, see :doc:`Programming Model <hip:understand/programming_model>`.

#. Optimize Thread Hierarchies and Block Sizes: Correctly configuring the thread
   hierarchy (e.g., threads per block, blocks per grid) is crucial for
   maximizing GPU performance. Choose an optimal number of threads per block and
   blocks per grid based on the specific hardware capabilities (e.g., the number
   of streaming multiprocessors (SMs) and cores on the GPU). Ensure that the
   number of threads per block is a multiple of the warp size (typically 32 for
   most GPUs) for efficient execution. Test different configurations, as the
   best combination can vary depending on the specific problem size and hardware.

#. Data Management and Transfer Between CPU and GPU: GPUs have their own memory
   (device memory), separate from CPU memory (host memory). Transferring data
   between the host CPU and the device GPU is one of the most expensive
   operations. Managing data movement is crucial to optimize performance.
   Minimize data transfers between the CPU and GPU by keeping data on the GPU
   for as long as possible. Use asynchronous data transfer functions where
   available, like ``hipMemcpyAsync()``, to overlap data transfer with kernel
   execution. For more information, see :doc:`HIP Programming Manual <hip:how-to/hip_runtime_api/memory_management>`.

#. Memory Management on the GPU: GPU memory accesses can be a performance
   bottleneck if not handled correctly. Use the different GPU memory types
   effectively (e.g., global, shared, constant, and local memory). Shared memory
   is faster than global memory but limited in size. Shared memory is ideal for
   reusing data across threads in a block. Ensure memory accesses are coalesced
   (i.e., threads in a warp access consecutive memory locations), as uncoalesced
   memory access patterns can significantly degrade performance.

#. Synchronize CPU and GPU Workloads: Host (CPU) and device (GPU) execute tasks
   run asynchronously, but proper synchronization is needed to ensure correct
   results. Use synchronization functions like  ``hipDeviceSynchronize()`` or
   ``hipStreamSynchronize()`` to ensure that kernels have completed execution
   before using their results. Take advantage of asynchronous execution to
   overlap data transfers, kernel execution, and CPU tasks where possible.

#. Profile and Optimize: Optimizing performance on heterogeneous systems often
   requires profiling to identify bottlenecks. Use profiling tools like
   **ROCProfiler** and **ROCTracer** to measure kernel execution time, memory
   bandwidth, and data transfer times. Identify and optimize any bottlenecks in
   the code, such as inefficient kernels, non-coalesced memory accesses, or
   excessive CPU-GPU synchronization points. Efficient heterogeneous programming
   requires a balance between high-level architecture design and low-level
   optimizations. It is essential to test, profile, and fine-tune every aspect
   of the application to achieve optimal performance. For more information, see
   :doc:`ROCProfiler <rocprofiler:index>` and :doc:`ROCTracer <roctracer:index>`.

#. Error Handling: GPU kernels and memory operations can fail, and these
   failures need to be properly handled. Check for errors after memory transfers
   and kernel launches, for example ``hipGetLastError()``. For more information,
   see `Error Handling <https://rocm.docs.amd.com/projects/HIP/en/latest/how-to/error_handling.html>`_.

#. Multi-GPU and Load Balancing: Large-scale applications that need more compute
   power can use multiple GPUs in the system. This requires distributing
   workloads across multiple GPUs to balance the load to prevent some GPUs from
   being overutilized while others are idle. Refer to XXX for more information.

For a complete description of the HIP programming language, see the :doc:`HIP documentation <hip:index>`.
