### **Technical Proposal: Partitioned Hybrid Runtime for Low-Latency Storage Engine**

**Governance:** Achieve 10x latency/throughput gains via CPU-core isolation, kernel-bypass I/O, and a custom `#[no_std]` Rust runtime on dedicated cores, coexisting with Linux.

---

### **1. Concrete Use Case: Real-Time Market Data Feed Handler**

**Problem:** High-frequency trading (HFT) systems require microsecond-scale processing of market data from NVMe storage. Standard Linux I/O stacks introduce >100μs jitter due to context switches, page-cache mismanagement, and scheduler noise.  
**Solution:**

- **Partitioned Runtime** reads NVMe data directly via user-space driver.
- **Isolated Cores** process packets with a cooperative scheduler.
- **Host OS** handles logging, network telemetry, and UI on non-isolated cores.  
  **Target Metrics:**
- ≤10μs 99th-percentile read latency (vs. 100μs in Linux).
- 2M IOPS for 4KB reads (vs. 500K IOPS in tuned Linux).

---

### **2. Phased Implementation Plan**

#### **Phase 0: System Configuration (Week 1-2)**

- **CPU Isolation:**
  ```bash
  # /etc/default/grub
  GRUB_CMDLINE_LINUX="isolcpus=4,5,6,7 nohz_full=4,5,6,7 rcu_nocbs=4,5,6,7"
  # Assign cores 0-3 to Linux, 4-7 to runtime
  ```
  - Disable hyper-threading on isolated cores.
- **IRQ Affinity:** Redirect all interrupts to cores 0-3:
  ```bash
  for irq in /proc/irq/*; do echo 0f > $irq/smp_affinity; done  # Hex mask for cores 0-3
  ```
- **Cgroups:** Confine Linux to cores 0-3:
  ```bash
  mkdir /sys/fs/cgroup/cpuset/host
  echo 0-3 > /sys/fs/cgroup/cpuset/host/cpuset.cpus
  ```

#### **Phase 1: Hardware Delegation (Week 3-4)**

- **VFIO Setup:**
  ```bash
  # Bind NVMe device to vfio-pci
  echo "8086 0a54" > /sys/bus/pci/drivers/vfio-pci/new_id
  ```
- **IOMMU Validation:** Ensure VT-d isolates device DMA:
  ```bash
  dmesg | grep -i "DMAR: IOMMU enabled"
  ```

#### **Phase 2: Runtime Development (Week 5-10)**

- **`no_std` NVMe Driver:**
  - MMIO register access via `volatile` reads/writes.
  - DMA queue allocation with 2MB huge pages.
- **Cooperative Scheduler:**
  - Single-threaded FIFO task queue (no preemption).
  - Async/await support via `futures` crate (no OS threads).
- **Shared Memory IPC:** Ring buffer between runtime and host for telemetry.

#### **Phase 3: Integration (Week 11-12)**

- **App Logic:** Feed handler parsing market data from NVMe.
- **Benchmarking:** Latency/throughput tests vs. Linux baseline.

---

### **3. Rust Runtime Architecture**

#### **Crate Structure**

```
hybrid-runtime/
├── core-runtime/           # #[no_std] crate
│   ├── src/
│   │   ├── driver/         # NVMe user-space driver
│   │   ├── scheduler/      # Cooperative task scheduler
│   │   ├── dma/            # DMA memory allocator
│   │   └── lib.rs
│   └── Cargo.toml          # no_std, inline asm, volatile
├── host-bridge/            # Linux-host communication
│   └── src/ipc.rs          # Shared-memory ring buffer
├── app/                    # Main binary (uses std)
│   └── src/main.rs         # Configures runtime & IPC
└── Cargo.toml              # Workspace definition
```

#### **Key Dependencies**

| **Crate**   | **Role**                                  |
| ----------- | ----------------------------------------- |
| `volatile`  | Safe MMIO access to NVMe registers        |
| `libc`      | Syscalls for huge-page allocation         |
| `x86_64`    | CPU-specific instructions (e.g., `rdtsc`) |
| `crossbeam` | Lock-free IPC queues                      |

---

### **4. Challenge Solutions**

#### **Debugging & Monitoring**

- **Lightweight Tracing:** FPGA-style probe registers in shared memory.
  - Log events via atomic writes to a fixed address.
  - Host-side tool (`probe-util`) decodes traces.
- **Crash Dumps:** Reserve 64KB in shared memory for panic handler snapshots.
- **Metrics Export:**
  ```rust
  // In core-runtime
  #[repr(C)]
  pub struct RuntimeMetrics {
      pub io_completed: AtomicU64,
      pub max_latency_ns: AtomicU64,
  }
  ```

#### **Error Handling**

- **NVMe Timeouts:** Watchdog task resets hardware queues.
- **DMA Safety:** IOMMU + Rust ownership ensures no wild DMA.
- **Fallback:** Critical errors trigger IPC alert to host for cleanup.

---

### **5. Proof-of-Concept Benchmark**

#### **Design**

- **Baseline:** Linux + `fio` with `io_uring`:
  ```ini
  [global]
  ioengine=io_uring
  direct=1
  rw=randread
  blocksize=4k
  ```
- **Partitioned Runtime:**
  ```rust
  let mut runtime = Runtime::new(isolated_cores);
  runtime.spawn(|| nvme_read_loop()); // 4KB rand reads
  ```

#### **Validation Metrics**

| **Metric**        | **Linux Baseline** | **Partitioned Runtime** | **Target Gain** |
| ----------------- | ------------------ | ----------------------- | --------------- |
| Avg. Latency      | 50μs               | ≤5μs                    | 10x             |
| 99th %ile Latency | 150μs              | ≤10μs                   | 15x             |
| Throughput (IOPS) | 500K               | ≥2M                     | 4x              |
| Latency Jitter    | ±30μs              | ±1μs                    | 30x             |

#### **Measurement Tools**

- **Runtime:** `rdtsc` timestamps for nanosecond accuracy.
- **Host:** `perf stat` for system-level counters (e.g., cache misses).

---

### **Conclusion**

This proposal delivers **10x+ latency/jitter reduction** by fusing Linux’s manageability with bare-metal performance. The hybrid model sidesteps OS noise while leveraging Rust’s safety for user-space drivers. Risks (e.g., VFIO compatibility) are mitigated through phased validation.
