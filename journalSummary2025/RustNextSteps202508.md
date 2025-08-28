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

## User-Space & Virtualization Layers — Isolation with near-native speed

While the DSL and synthesis pipeline represent the long-term vision, a new OS needs a pragmatic strategy to achieve broad hardware support *today*. The most effective, lowest-effort approach is to leverage virtualization and user-space driver frameworks. By treating the hardware as a set of standardized virtual devices, an OS can abstract away the complexity of thousands of physical drivers.

### VirtIO/vDPA performance table vs. SR-IOV & emulation

The **VirtIO** standard is the key to this strategy [technical_solution_virtualization_layer[11]][37]. It is a mature, open standard that defines a set of paravirtualized devices for networking, storage, graphics, and more. Its performance is excellent, and its cross-platform support is unmatched.

| I/O Virtualization Technology | Mechanism | Performance (10G NIC) | GPU Efficiency | Security/Isolation | Key Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Full Emulation (QEMU)** | Software simulates real hardware (e.g., an Intel e1000 NIC). | Low (~1-2 Gbps) | Very Low | High (Full VM isolation) | Legacy OS support. |
| **VirtIO (Paravirtualization)** | Guest-aware drivers talk to a standard virtual device. | High (**9.4 Gbps**) [technical_solution_virtualization_layer[2]][8] | Medium (~43%) | High (Full VM isolation) | Standard for cloud VMs; high-performance general I/O. |
| **vDPA (VirtIO Datapath Accel.)** | VirtIO control plane, hardware datapath. | Very High (Near-native) | N/A | High (Full VM isolation) | High-performance networking/storage in VMs. [technical_solution_virtualization_layer[12]][38] |
| **SR-IOV / Passthrough** | Hardware is partitioned and assigned directly to guest. | Native (**9.4 Gbps**) [technical_solution_virtualization_layer[2]][8] | Near-Native (**99%**) | Medium (Hardware-level) | Bare-metal performance for latency-sensitive workloads. |

This data shows that VirtIO, especially when combined with vDPA, offers performance that is competitive with direct hardware access, while providing the immense benefit of a stable, universal driver interface.


## Next Steps






