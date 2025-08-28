# Situation till 202508

We said we want to rewrite software in Rust because it offers fearless concurrency, memory safety, and zero-cost abstraction

So we started with thinking of writing applications or libraries which
- were rewrites of existing proven libraries or applications
- were new Rust implementations of a gap in the Rust ecosystem

But we realized that the linux kernel itself is a big hindrance to leveraging the maximal capabilities of Rust because it has jitter which takes away the advantage of fearless concurrency

This was shocking because we thought Linux is optimized, but the big picture is that all software written for single core by default is not optimal for multi-core performance

And thus we thought can we rewrite an OS in Rust such that we can leverage the maximum capabilities of Rust

Our exploration suggests that
- Driver ecosystem is complex, fragmented and getting people to like a new OS is going to be hard, very difficult for adoption as well as needs a long time to build everything from scratch
- Easiest adoption is a binary which is a Real Time Operating System customized to a specific App which opens a terminal to the host linux, allocating specific CPU Cores and RAM to the RTOS and having a scheduler which is optimized for the app we intend to run on it
    - Why app specific RTOS?
        - Minimal Jitter or interference from other applicatins or processes
        - Maximal predictability of availability of CPU Cores and resources
        - Improved P99.99 percentile latency because predictability of resources

# Precedence 

### Microkernel & DDE case studies: Genode 90% disk throughput, MINIX recovery demo

An alternative approach, pioneered by microkernel operating systems, is to run drivers as isolated user-space processes. This provides exceptional security and reliability.

* **Genode OS Framework**: Genode uses **Device Driver Environments (DDEs)** to run unmodified Linux drivers as sandboxed user-space components [technical_solution_cross_os_reuse_strategies.2.technical_mechanism[0]][19]. While this involves a significant porting effort (**1-3 person-months** per driver), it achieves impressive performance, reaching **90%** of native Linux disk throughput [technical_solution_cross_os_reuse_strategies.2.maintenance_and_performance_tradeoffs[0]][19].
* **MINIX 3**: This OS was designed from the ground up with driver isolation in mind. All drivers run as separate, unprivileged server processes. A "reincarnation server" monitors these processes and can automatically restart a crashed driver in milliseconds, allowing the system to self-heal from driver failures without rebooting [technical_solution_cross_os_reuse_strategies.2.technical_mechanism[1]][39].

These examples prove that user-space driver architectures are not only viable but can provide levels of security and resilience that are impossible to achieve in a monolithic kernel.

### Framework pick-list: FUSE, VFIO, SPDK, DPDK—when to use which

For a new OS, a hybrid approach using a mix of user-space frameworks is recommended, depending on the device class and requirements.

| Framework | Primary Use Case | Key Benefit | Major Trade-off | Cross-OS Support |
| :--- | :--- | :--- | :--- | :--- |
| **FUSE** | Filesystems | High portability, easy development | Performance overhead (up to 80% slower) [technical_solution_user_space_frameworks.1[0]][40] | Excellent (Linux, macOS, Windows, BSDs) |
| **VFIO** | Secure device passthrough | IOMMU-enforced security | Linux-only; requires hardware support | None (Linux-specific) |
| **SPDK** | High-performance storage | Kernel bypass, extreme IOPS | Polling model consumes CPU cores | Good (Linux, FreeBSD) |
| **DPDK** | High-performance networking | Kernel bypass, low latency | Polling model consumes CPU cores | Good (Linux, FreeBSD, Windows) |

A new OS should prioritize implementing a FUSE-compatible layer for filesystem flexibility and a VFIO-like interface to enable high-performance frameworks like SPDK and DPDK.

## 6. Technical Pillar 3: Memory-Safe Drivers & CHERI Future — Security dividends

A foundational principle of Project Unidriver must be a commitment to memory safety. The vast majority of critical security vulnerabilities in system software are caused by memory management errors in languages like C and C++. By adopting modern, memory-safe languages and hardware architectures, we can eliminate entire classes of bugs by design.


## Next Steps






