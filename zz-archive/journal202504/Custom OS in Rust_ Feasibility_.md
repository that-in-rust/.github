

# **Architecting a Specialized Rust-Based Operating System for x86-64: A Feasibility and Implementation Analysis for the Lenovo Legion Y540-15IRH Platform**

## **Part I: Foundational Analysis**

### **Section 1: Introduction and Overall Difficulty Assessment**

#### **1.1. Executive Summary**

The endeavor to construct a custom, use-case-optimized operating system (OS) from scratch in Rust for a modern hardware platform, such as the Lenovo Legion Y540-15IRH, represents a formidable challenge in software engineering and computer science. The complexity of this task is an order of magnitude greater than that of conventional application development, placing it in a category of difficulty comparable to the ground-up design of a high-performance relational database engine, a modern compiler, or a hypervisor. The project's success is contingent not merely on prolific coding but on a profound, multi-disciplinary mastery of subjects spanning x86-64 hardware architecture, low-level systems programming, peripheral device interaction, memory management theory, and advanced concurrency models. This report provides a comprehensive analysis of the project's feasibility, dissects the specific hardware challenges presented by the target platform, evaluates the strategic implications of using Rust, and presents a detailed roadmap for development. It culminates in a comparative analysis of several specialized use-case architectures, offering a blueprint for tailoring the OS to achieve maximum performance for a designated task.

#### **1.2. A Multi-Axis Difficulty Framework**

The difficulty of this undertaking is not a monolithic value but a complex function of several independent variables. A nuanced assessment requires evaluating the project along three primary axes of ambition, each of which dramatically alters the scope and required expertise.

* **Architectural Ambition**: The spectrum of OS design ranges from the academically tractable to the institutionally monumental. At one end, creating a minimal "Hello, World" kernel that boots within an emulator like QEMU and prints a message to a serial console is a well-understood, albeit challenging, project often used as a pedagogical tool.1 At the opposite extreme lies the development of a full-featured, general-purpose, POSIX-compliant operating system. Such systems, exemplified by Linux or the BSDs, are the product of decades of collaborative effort by global teams of developers. Projects like Redox OS, despite being one of the most advanced efforts in the Rust OS space, demonstrate the immense, multi-year commitment required to even approach this level of functionality.3  
* **Hardware Scope**: The complexity of driver development scales exponentially with the modernity and variety of the hardware peripherals that must be supported. Writing a driver for a simple, well-documented legacy device like a 16550 UART (serial port) is a relatively contained task. In stark contrast, supporting the full suite of peripherals on the Lenovo Legion Y540—including the NVMe storage controller, the Intel Wi-Fi/Bluetooth combo card, the ACPI power management interface, and multiple USB controllers—presents a "driver gauntlet".5 Many of these devices have complex programming interfaces, require proprietary firmware blobs, and may have sparse or non-existent public documentation, necessitating arduous reverse-engineering of existing drivers.  
* **Use-Case Specialization**: The intended application of the OS is the most critical factor in defining its feature set and, consequently, its complexity. A single-purpose **unikernel**, which statically links the application with a minimal set of required kernel libraries to create a single, bootable image, is vastly less complex than a multi-user, self-hosting development environment.6 The former can dispense with entire subsystems like multi-process isolation, complex filesystems, and dynamic linking, while the latter must implement them robustly and securely.

#### **1.3. Impact of the "No GPU" Constraint**

The user's directive to exclude support for both the discrete NVIDIA GeForce GTX 1650 and the integrated Intel UHD Graphics 630 8 constitutes a significant and strategic simplification of the project. Graphics driver development is notoriously difficult, often considered the most complex aspect of modern OS development. It involves managing intricate hardware state machines, programming complex memory management units (IOMMUs or GARTs) for DMA, and navigating proprietary, frequently undocumented command submission interfaces. Eliminating this requirement removes a massive source of complexity and development effort.

However, this simplification is substantially offset by the presence of other modern, complex peripherals. The Intel Wireless-AC 9560 card, in particular, re-introduces a level of difficulty that rivals that of a basic graphics driver. Modern Wi-Fi controllers are not simple devices controlled by poking registers; they are sophisticated systems-on-a-chip (SoCs) that require the OS driver to load and manage large, proprietary firmware binaries at runtime.11 The driver must then communicate with this firmware through complex, asynchronous message-passing interfaces to handle operations like network scanning, authentication (WPA2/WPA3), and advanced power-saving modes. The complexity of this single driver effectively negates a large portion of the simplification gained by ignoring the GPUs.

#### **1.4. Estimated Effort**

Based on the multi-axis framework, the estimated effort for a single, expert-level developer is as follows:

* **Minimal Kernel**: A kernel that boots in the QEMU emulator, sets up basic paging, and prints to a serial console. **Estimated Effort: 1-3 person-months.**  
* **Targeted Unikernel**: A specialized OS, such as the dedicated Kafka host analyzed later in this report, including drivers for NVMe and Ethernet. **Estimated Effort: 12-24 person-months.**  
* **Self-Hosting System**: A general-purpose OS capable of compiling its own source code, requiring a full POSIX-like environment, multiple complex drivers, and a ported toolchain. **Estimated Effort: 5-10+ person-years**, realistically requiring a small, dedicated team.

### **Section 2: The Target Platform: A Hardware-Software Contract**

The hardware components of the Lenovo Legion Y540-15IRH do not merely represent a list of parts; they collectively define a strict, low-level "contract" that the operating system must fulfill. Each component exposes a specific programming interface, and the OS's primary function is to manage these interfaces to provide higher-level abstractions to applications. A failure to correctly implement any part of this contract will result in system instability, data corruption, or complete hardware unresponsiveness.

#### **2.1. CPU: Intel® Core™ i7-9750H (Coffee Lake-HR)**

* **Core Architecture**: The central processing unit is an Intel Core i7-9750H, a high-performance mobile processor from the Coffee Lake-HR family, manufactured on a 14nm++ process.9 It features 6 physical cores and supports Hyper-Threading, presenting a total of 12 logical processors to the OS.8 The immediate consequence of this multi-core design is that the OS scheduler cannot be a simple round-robin loop; it must be a true symmetric multiprocessing (SMP) scheduler, capable of managing thread affinity, load balancing across cores, and handling inter-processor interrupts (IPIs) for synchronization. The CPU operates on the standard  
  **x86-64** instruction set architecture (ISA), which dictates the fundamental programming model for the kernel.14  
* **Operating Modes**: The kernel's very first task upon receiving control from a bootloader is to ensure the CPU is in the correct operating mode. While the CPU can operate in legacy 16-bit Real Mode and 32-bit Protected Mode, all modern OS functionality will be implemented in **64-bit Long Mode**. This mode provides access to 64-bit general-purpose registers (RAX, RBX, etc.), a flat 64-bit virtual address space, and a new instruction pointer-relative addressing mode, all of which are foundational to the kernel's design.14  
* **Memory Hierarchy**: The i7-9750H is equipped with a 12 MB L3 cache, which is shared among all cores.8 While the hardware manages cache coherency automatically (via protocols like MESI), the OS design can have a profound impact on performance. For I/O-intensive workloads like the Kafka use case, designing data structures and memory access patterns to maximize cache hits and minimize cache-line "false sharing" between cores is a critical micro-optimization.  
* **Instruction Set Extensions**: The processor supports modern instruction set extensions, including Advanced Vector Extensions 2 (AVX2).13 A specialized OS could leverage these instructions to accelerate specific workloads. For example, a custom application running on the OS could use AVX2 for high-performance scientific computing, or the kernel itself could use them for optimized operations like checksum calculations in the networking stack or high-speed memory copies.

#### **2.2. Chipset and Motherboard: Intel HM370**

The Intel HM370 Chipset serves as the central nervous system of the platform, mediating all communication between the CPU and the vast majority of peripheral devices.17 It houses the controllers for the PCI Express (PCIe) bus, USB ports, and SATA ports. One of the earliest and most critical tasks for the kernel, after establishing basic memory management, is to write a PCIe bus driver. This driver must recursively scan the PCIe bus hierarchy, discovering each connected device by reading its Configuration Space. This space contains vital information, including the device's Vendor ID (VID) and Device ID (DID), which the OS uses to identify the device and load the appropriate driver.

#### **2.3. Memory Subsystem: DDR4-2666**

The system is equipped with 16 GB of DDR4 SDRAM, operating at a speed of 2666 MT/s, and is expandable to a maximum of 32 GB.17 The OS must include a robust physical memory manager, often called a

**frame allocator**, to manage this resource. The frame allocator's first task is to parse the memory map provided by the bootloader, which identifies which physical address ranges are usable RAM versus which are reserved for hardware (Memory-Mapped I/O). It must then implement a strategy, such as a bitmap or a linked list of free frames, to track, allocate, and deallocate physical memory pages on demand for the rest of the kernel.

#### **2.4. Storage Controllers: NVMe and SATA (AHCI)**

The presence of two distinct types of storage controllers necessitates the development of two separate, complex driver stacks.

* **Primary Storage**: The main storage device is a high-speed Non-Volatile Memory Express (NVMe) Solid-State Drive (SSD), connected directly to the CPU's PCIe lanes.17 Writing an  
  **NVMe driver** is a primary and non-trivial task. The NVMe protocol is designed for parallelism and low latency, and its programming interface reflects this. The driver must communicate with the controller by creating and managing multiple pairs of "Submission Queues" and "Completion Queues" in physical memory. Commands are submitted by placing them in a submission queue and "ringing a doorbell" (writing to a specific controller register). The controller processes these commands asynchronously and places completion entries in the corresponding completion queue, typically signaling the CPU via an interrupt. This highly asynchronous model is powerful but complex to implement correctly.20  
* **Secondary Storage**: The laptop also contains a 1 TB mechanical Hard Disk Drive (HDD) connected via a Serial ATA (SATA) interface.19 The SATA controller on the HM370 chipset operates in Advanced Host Controller Interface (AHCI) mode. This requires an entirely different  
  **AHCI driver**. The AHCI programming model involves setting up a command list in memory, where each entry points to a command table. The driver constructs command details in a structure known as a Frame Information Structure (FIS) and uses these tables to issue commands like READ DMA EXT or WRITE DMA EXT to the drive.21

#### **2.5. Networking Peripherals: Ethernet and Wi-Fi**

* **Wired Networking**: The laptop includes a Gigabit Ethernet port, which provides a reliable, high-speed network interface.19 On consumer motherboards of this era, this port is typically driven by a Realtek PCIe GBE Family Controller (e.g., a chip from the RTL8111/8168 family). Writing a driver for this device is a relatively straightforward (by OS development standards) task. It involves allocating DMA-capable memory for transmit and receive descriptor rings, programming the controller's registers to point to these rings, and handling interrupts to process incoming packets and signal transmit completions.23 This would be the recommended starting point for networking support.  
* **Wireless Networking**: The machine is equipped with an Intel Wireless-AC 9560 module, which provides both Wi-Fi 5 (802.11ac) and Bluetooth 5.0 capabilities.11 As noted previously,  
  **this is a major point of difficulty**. The driver for this device cannot be written simply by referencing a hardware datasheet. It must be developed by studying the existing Linux iwlwifi driver as a reference.12 The driver's responsibilities include locating and loading a large, proprietary firmware file from a filesystem into the card's internal memory at initialization. All subsequent operations—from scanning for networks to handling WPA2/WPA3 cryptographic handshakes—are performed by sending commands to this firmware and processing its responses. This introduces a dependency on a filesystem early in the boot process and involves a level of software complexity far exceeding that of the Ethernet driver. The initial path of least resistance would be to scope out Wi-Fi support entirely and focus on the wired connection.

#### **2.6. Human Interface and Other Peripherals**

To be minimally interactive, the OS will require drivers for several other essential devices. The internal keyboard and touchpad typically communicate over a PS/2 or I2C interface. External devices would require a full USB controller stack (XHCI). The fundamental unit of time for the OS, used for process scheduling, is provided by a hardware timer. On modern systems, this is either the High Precision Event Timer (HPET) or the local APIC timer present on each CPU core.5 The kernel must program one of these timers to fire interrupts at a regular interval (e.g., every 10 milliseconds) to trigger the scheduler.

### **Section 3: Rust as the Implementation Language: A Double-Edged Sword**

The choice of Rust as the implementation language for an operating system is a strategic one, offering revolutionary advantages in safety and expressiveness while also presenting unique challenges related to low-level systems programming. It represents a fundamental departure from the C-based tradition that has dominated kernel development for half a century.

#### **3.1. The Promise of Safety and Performance**

* **Memory Safety at the Core**: Rust's paramount feature is its ownership and borrowing system, which provides compile-time guarantees of memory safety.24 This system eliminates, by design, entire categories of devastating bugs that have historically plagued C-based kernels, such as use-after-free, double-free, dangling pointers, and buffer overflows. In the context of an OS kernel, where a single memory error can lead to an immediate system crash or a subtle, exploitable security vulnerability, this is a transformative benefit. The compiler acts as a rigorous, automated proof-checker for memory management logic.  
* **Fearless Concurrency**: Building on the ownership model, Rust's type system includes the Send and Sync marker traits. These traits allow the compiler to statically verify whether a type can be safely transferred across threads (Send) or accessed by multiple threads simultaneously (Sync). This "fearless concurrency" is invaluable for OS development, particularly in an SMP environment like the target i7-9750H. It makes it possible to write complex, multi-core schedulers, interrupt handlers, and locking primitives with a high degree of confidence that data races have been prevented at the language level.  
* **Zero-Cost Abstractions**: A core design principle of Rust is that abstractions should not impose a runtime performance penalty.24 High-level language features like iterators, closures, pattern matching, and generic types are compiled down into highly efficient, specialized machine code that is often as fast as or faster than equivalent handwritten C code. This allows the OS developer to write expressive, maintainable, high-level code for complex subsystems without sacrificing the raw performance necessary for kernel-level operations. The absence of a mandatory garbage collector or a large runtime makes Rust suitable for the most performance-critical, bare-metal environments.

#### **3.2. The Reality of unsafe and Low-Level Development**

* **The unsafe Escape Hatch**: Rust's safety guarantees are not magic; they are enforced by a set of rules that can be too restrictive for the low-level operations required in an OS. To accommodate this, Rust provides the unsafe keyword. Any code that performs operations the compiler cannot verify as safe—such as dereferencing raw pointers, calling functions across a Foreign Function Interface (FFI), or accessing memory-mapped I/O (MMIO) registers—must be placed within an unsafe block or function. The fundamental challenge of Rust OS development is not to *avoid* unsafe code, which is impossible, but to *architect* the system in a way that minimizes its surface area. The idiomatic approach is to write small, heavily scrutinized unsafe blocks that perform the necessary low-level work, and then wrap these blocks in safe, high-level APIs that provide invariants the rest of the kernel can rely on. This encapsulates the danger and makes the system as a whole verifiable.1  
* **The Ecosystem and no\_std**: All OS kernel development in Rust takes place in a no\_std environment.1 This means the Rust standard library, which depends on underlying OS services like threads and files, is unavailable. The developer is limited to using the  
  core library (which provides fundamental types like Option and Result) and the alloc library (which provides heap-based data structures like Box and Vec once a kernel heap allocator is created). While the Rust embedded and OS development ecosystem is vibrant and growing, it is less mature than that of C. Essential resources include the "Writing an OS in Rust" blog series by Philipp Oppermann 1, the OSDev.org wiki 5, and the source code of existing Rust-based OS projects like Redox 3 and Hermit.6 However, it is highly unlikely that pre-built, production-ready driver crates will exist for all the specific hardware on the target laptop. The developer must be prepared to write most drivers from scratch, using these resources and existing Linux drivers as guides.  
* **ABI and Toolchain Management**: The OS must define its own Application Binary Interface (ABI) if it is to support userspace applications. Even within the kernel, interfacing with handwritten assembly code—which is necessary for critical operations like handling the initial boot jump, context switching, and servicing interrupt entry points—requires meticulous management of calling conventions and register usage. The entire development workflow relies on a properly configured Rust toolchain capable of cross-compiling for a custom, bare-metal target.

## **Part II: The Development Roadmap: A Phased Approach**

### **Section 4: Stage 1 \- The Bare Bones Kernel**

This initial stage focuses on creating the absolute minimum viable kernel that can be booted on the target architecture. The goal is not functionality but to establish the foundational scaffolding upon which all future development will be built. All work in this stage is typically performed within an emulator like QEMU for rapid iteration and debugging.

#### **4.1. The Boot Process**

An operating system kernel does not run from a cold boot. It relies on a piece of firmware (BIOS or UEFI) to initialize the basic hardware and then pass control to a **bootloader**. For this project, a pre-existing bootloader like Limine or GRUB is essential.5 The bootloader's responsibilities include:

1. Loading the compiled kernel executable file from a disk into a known location in physical memory.  
2. Probing the system's physical memory layout and creating a memory map that details which address ranges are available RAM, which are reserved by the ACPI/firmware, and which are memory-mapped I/O regions.  
3. Switching the CPU into the required 64-bit Long Mode.  
4. Placing the memory map and other boot information in a known memory location and finally, jumping to the kernel's entry point.

The very first code in the kernel to execute will be a small assembly stub. Its sole purpose is to set up a temporary stack so that Rust code can execute, and then to call the main Rust function, conventionally named kmain.

#### **4.2. Entering the 64-bit World**

The bootloader handles the complex state transitions required to move the CPU from its initial 16-bit real mode into the 64-bit long mode required by a modern kernel.14 The kernel's code must be compiled to run in this environment from the outset. This means it can assume access to the full set of 64-bit general-purpose registers (r8-r15, and the 64-bit extensions of legacy registers like rax, rbx), a linear 64-bit virtual address space, and the ability to use RIP-relative addressing for position-independent code.

#### **4.3. Foundational Memory Management: Paging**

The most critical task of the early kernel is to take control of memory management from the bootloader by setting up its own set of **page tables**. On the x86-64 architecture, this is a four-level hierarchical structure consisting of the Page Map Level 4 (PML4), Page Directory Pointer Table (PDPT), Page Directory (PD), and Page Table (PT).1 The process involves:

1. Allocating physical memory for each level of the page table hierarchy.  
2. Populating the entries to create an initial memory mapping. At a minimum, this involves identity-mapping the kernel's own code and data sections (i.e., virtual address \= physical address) and the VGA text buffer for output.  
3. Loading the physical address of the top-level PML4 table into the CR3 control register. This action atomically enables paging and places the CPU under the kernel's memory management control.

A more advanced configuration, necessary for a proper general-purpose OS, is to create a "higher-half" kernel, where the kernel's code and data are mapped into the upper portion of every process's virtual address space (e.g., starting from 0xFFFF800000000000). This simplifies system calls and context switching.

#### **4.4. Output and Debugging**

With the "no GPU" constraint, graphical output is unavailable. The two primary methods for early kernel output and debugging are essential:

* **VGA Text Mode**: The simplest form of video output. The kernel can write directly to a memory-mapped buffer located at physical address 0xB8000. Writing character/attribute pairs to this buffer causes them to appear on the screen in an 80x25 grid. This provides immediate visual feedback within an emulator.1  
* **Serial Port**: A serial port driver is one of the simplest to write and is indispensable for debugging, especially on real hardware where the screen may not be usable during a crash. It allows the kernel to send log messages and panic information to a host computer for capture and analysis.

### **Section 5: Stage 2 \- Core Kernel Infrastructure**

With the basic boot process established, the next stage involves building the core subsystems that are fundamental to any modern operating system: memory management, interrupt handling, and concurrency.

#### **5.1. Memory Management**

* **Physical Memory Manager (Frame Allocator)**: This component is responsible for managing the system's physical RAM. Using the memory map provided by the bootloader, it must build a data structure (commonly a bitmap or a free-list) to track the status of every 4 KiB physical page frame. It will provide functions to allocate\_frame() and deallocate\_frame(), which will be used by the virtual memory manager and for DMA buffers.1  
* **Virtual Memory Manager (VMM)**: The VMM works at a higher level of abstraction. It manages the virtual address space of the kernel and, eventually, of user processes. Its responsibilities include creating and destroying address spaces, allocating regions of virtual memory (e.g., for stacks or heaps), and using the frame allocator to map these virtual regions to physical frames by modifying the page tables. A crucial part of the VMM is the page fault handler, which must be able to handle legitimate faults (like allocating a page on-demand) and illegitimate ones (like a segmentation fault).  
* **Heap Allocator**: To allow for dynamic memory allocation within the kernel (e.g., creating a new process control block or expanding a list of open files), a kernel heap is required. This involves allocating a large, contiguous region of virtual memory for the heap and then implementing or porting a heap allocator algorithm (such as a linked-list allocator or a buddy allocator) to manage allocations within that region. The alloc crate in Rust provides the necessary traits (GlobalAlloc) to integrate this custom allocator with standard data structures like Box and Vec.1

#### **5.2. Interrupts and Exceptions**

* **The Interrupt Descriptor Table (IDT)**: The kernel must construct and load an IDT. This is a data structure, similar to the GDT, that holds up to 256 entries. Each entry is a gate descriptor that points to the code that should be executed when a specific interrupt or CPU exception occurs.1 The kernel must provide handler functions for critical CPU exceptions like Page Faults (vector 14\) and General Protection Faults (vector 13). A double fault handler is also critical to prevent the system from resetting on unrecoverable errors.  
* **Hardware Interrupts (IRQs)**: To receive input from hardware, the kernel must configure the system's interrupt controllers. On modern x86-64 systems, this means initializing the Advanced Programmable Interrupt Controller (APIC), specifically the local APIC (LAPIC) on each CPU core and the I/O APIC that receives interrupt signals from peripherals. The legacy Programmable Interrupt Controller (PIC) must be disabled. The kernel must then write Interrupt Service Routines (ISRs) for each hardware device it intends to use. These ISRs are the entry points for device drivers to respond to events.5

#### **5.3. Concurrency and Scheduling**

* **Processes and Threads**: The kernel must define data structures to represent units of execution. This is typically a Task or Process struct containing information such as the task's ID, state (e.g., Running, Ready, Blocked), register context (when not running), and a pointer to its top-level page table (PML4).  
* **Context Switching**: This is the mechanism for switching the CPU from executing one task to another. It is a highly performance-critical and architecture-specific operation that must be written in assembly language. The context switch code is responsible for saving all general-purpose registers of the outgoing task onto its kernel stack and restoring the registers of the incoming task from its kernel stack. The final ret instruction in the context switch function effectively jumps to the instruction pointer of the new task, completing the switch.  
* **The Scheduler**: The scheduler is the algorithm that implements the OS's multitasking policy. It decides which task from the Ready queue should run next. The scheduler is typically invoked by a timer interrupt. The kernel must program a hardware timer, such as the **HPET** or the local **APIC timer**, to generate an interrupt at a fixed frequency (e.g., 100 Hz).5 The ISR for this timer interrupt calls the scheduler, which performs a context switch if it decides a different task should run. The initial implementation would likely be a simple round-robin scheduler, with more complex algorithms (e.g., priority-based, fair-share) added later as needed.

### **Section 6: Stage 3 \- The Driver Gauntlet**

This stage represents the most laborious and hardware-specific phase of development. It involves writing the software that allows the abstract kernel to communicate with the concrete peripheral devices on the Lenovo Legion Y540. Each driver is a complex mini-project.

#### **6.1. The PCI/PCIe Bus Driver**

This is the foundational driver for a modern system. Before any device on the PCIe bus can be used, the kernel must have a driver that can enumerate the bus. This involves iterating through all possible bus, device, and function numbers, reading the configuration space of each potential device to check for its presence. When a device is found, the driver reads its Vendor ID and Device ID to identify it, its class codes to determine its function (e.g., storage controller, network controller), its Base Address Registers (BARs) to find the physical memory addresses of its control registers, and the interrupt line it is configured to use.

#### **6.2. Storage Stack**

* **NVMe Driver**: As the primary boot and data drive is NVMe, this driver is critical for any meaningful use of the system. The development process, based on the NVMe specification, is as follows 5:  
  1. Use the PCIe driver to identify the NVMe controller and map its control registers (located at the physical address specified in its BAR0/1) into the kernel's virtual address space.  
  2. Initialize the controller by writing to its configuration registers.  
  3. Allocate physically contiguous memory for the Admin Submission and Completion Queues.  
  4. Program the physical addresses of these queues into the controller.  
  5. Issue an IDENTIFY command to retrieve the drive's parameters, such as block size and total capacity.  
  6. Create one or more I/O queue pairs for read/write operations.  
  7. Implement functions to build READ and WRITE commands, place them in an I/O submission queue, and notify the controller by writing to a "doorbell" register.  
  8. Write an interrupt handler that, upon receiving an interrupt from the controller, reads the completion queue entries to determine which commands have finished and their status.  
* **AHCI/SATA Driver**: To access the secondary 1 TB HDD, a separate AHCI driver is required. While also a DMA-based protocol, its programming model differs significantly from NVMe's 21:  
  1. Identify the AHCI controller on the PCIe bus (it is part of the Intel HM370 chipset).  
  2. Map its Host Bus Adapter (HBA) memory registers.  
  3. For each active SATA port, allocate memory for a command list, a received FIS structure, and multiple command tables.  
  4. Program the controller with the physical addresses of these structures.  
  5. Issue commands by building a command FIS, setting up a Physical Region Descriptor Table (PRDT) to describe the data buffer for DMA, and setting a bit in the port's command issue register.  
  6. Handle interrupts to check for command completion or errors.

#### **6.3. Networking Stack**

* **Ethernet (Realtek) Driver**: This is the most practical starting point for networking. Based on documentation for similar Realtek chips like the RTL8169, the driver will need to 23:  
  1. Identify the device on the PCIe bus.  
  2. Reset the chip and read its MAC address from the registers.  
  3. Allocate DMA-capable memory for a ring of transmit descriptors and a ring of receive descriptors.  
  4. Program the controller's registers with the physical addresses of these descriptor rings.  
  5. To transmit a packet, the driver copies the packet data to a buffer, fills out a transmit descriptor pointing to it, and notifies the hardware.  
  6. The interrupt handler checks for completed transmissions (to free buffers) and for newly received packets (to pass up to a network protocol stack).  
* **Wi-Fi (Intel AC-9560) Driver**: This is the most challenging driver in this project, outside of a full GPU driver. The development process would be one of reverse-engineering and adaptation, not direct specification implementation 11:  
  1. A minimal filesystem (see below) must be working first, as the driver needs to read the proprietary firmware blob for the AC-9560 from the disk.  
  2. The driver must allocate memory and use DMA to load this firmware into the device's own RAM.  
  3. After loading, the driver initializes communication with the now-running firmware.  
  4. All subsequent Wi-Fi operations (scanning, connecting, sending/receiving data) are performed by exchanging command and event messages with the firmware over a shared memory interface. The Linux iwlwifi driver source code would be the indispensable, though highly complex, reference for understanding this command protocol.

#### **6.4. Filesystem**

A filesystem is a prerequisite for many advanced features, including loading Wi-Fi firmware or user-space programs. Initially, a very simple implementation would suffice. A RAM-based filesystem (ramfs or tmpfs) is the easiest to implement. For reading from disk, a minimal, read-only FAT32 driver is a common starting point, as the FAT format is relatively simple and well-documented.5 Developing a robust, high-performance, writable filesystem like ext2 or a custom design is a major OS sub-project in its own right.

## **Part III: Architectural Optimization for Specific Use Cases**

### **Section 7: Comparative Analysis of Use-Case Architectures**

The fundamental value of creating a custom operating system is the ability to escape the design compromises inherent in general-purpose systems like Linux or Windows. A general-purpose OS must be a jack-of-all-trades, providing fair scheduling, robust security boundaries, and a vast API for countless types of applications. A specialized OS can be a master of one, shedding entire subsystems and optimizing its core architecture for a single, well-defined workload. The choice of use case is therefore not an afterthought; it is the primary determinant of the kernel's fundamental design. An attempt to build a "one-size-fits-all" custom OS would inevitably result in a less capable, less stable, and less compatible version of Linux. The following analysis explores the radically different architectural blueprints required for each of the proposed use cases.

The table below serves as the central thesis of this analysis. It synthesizes the foundational concepts and hardware constraints into a strategic framework, illustrating the deep, causal chain from high-level application requirements down to low-level kernel design decisions. It provides a clear, comparative roadmap, enabling a developer to understand the profound architectural consequences that flow from their choice of target application. For instance, the high-throughput, low-latency requirement of a Kafka host directly motivates the adoption of a unikernel architecture and an I/O-centric scheduler, a design that would be entirely unsuitable for a general-purpose development machine. Conversely, the need to run a complex toolchain on a dev machine mandates a traditional monolithic or microkernel architecture capable of supporting process isolation and a full POSIX-compliant C library.

#### **Table 7.1: Architectural Blueprint by Use Case**

| Feature / Aspect | Backend Web Server | Dedicated Kafka Host | Self-Hosting Dev Machine |
| :---- | :---- | :---- | :---- |
| **Primary Goal** | Low-latency request handling, high concurrency. | Maximize message throughput, minimize I/O latency. | General-purpose computing, toolchain support, interactivity. |
| **Kernel Architecture** | **Unikernel (e.g., Hermit-style)**.6 Eliminates kernel/userspace boundaries and syscall overhead for maximum network stack performance. The web server application is linked directly with the kernel libraries into a single executable image. | **Hyper-optimized Unikernel**. The most extreme optimization path. The OS and the Kafka broker application are co-designed and compiled into a single, specialized appliance. The distinction between "kernel" and "application" is intentionally blurred. | **Monolithic or Microkernel (e.g., Redox-style)**.3 This traditional architecture is required to provide fundamental features like process isolation, protected virtual memory between applications, and a stable system call interface for a POSIX-like environment. |
| **Scheduler Focus** | Preemptive, low-latency, potentially work-stealing. Optimized to support an async/await runtime, ensuring that tasks blocked on I/O do not prevent other tasks from running. The goal is to minimize request-response time. | I/O-centric, likely non-preemptive for core broker threads. The scheduler's primary goal is to minimize context switches and keep the threads responsible for disk and network I/O running as long as possible to maximize data pipeline throughput. | Preemptive, fair-share, with a complex priority system. Must balance the needs of interactive applications (e.g., a text editor, which requires low latency) and long-running batch jobs (e.g., a compiler, which requires high throughput). |
| **Memory Management** | Optimized for a high rate of small, short-lived allocations (e.g., for per-request data structures) and a few large, static TCP/IP buffers. A slab allocator would be highly effective. | Dominated by the **OS page cache**. The OS's primary memory management goal is to maximize the amount of free RAM available for the page cache, which Kafka leverages heavily for buffering log segments before flushing to disk and for serving reads to consumers.31 | Full demand paging system with copy-on-write (to efficiently implement fork()), support for shared libraries (mapping the same physical code into multiple processes), and robust memory protection between processes. |
| **Filesystem Needs** | Minimal. The application might be entirely self-contained, or it might only need a simple, read-only filesystem to load configuration or static assets. | **Direct Log Segment Management**. To guarantee sequential I/O and eliminate filesystem overhead, the OS would likely bypass a traditional filesystem entirely. It would manage the NVMe drive as a raw block device, with a simple allocator for large, contiguous log segments.33 | A full, POSIX-compliant, feature-rich filesystem is mandatory. This would require porting an existing filesystem like ext4 or developing a custom one (like RedoxFS) supporting hierarchical directories, permissions, metadata, and various file types.3 |
| **Networking Stack** | A highly optimized, single-address-space TCP/IP stack. Because there is no kernel/user boundary, network packets can be processed with zero data copies between buffers, leading to extremely low latency. | **True Zero-Copy Path**. The architecture is designed to create a direct data pipeline from the storage device to the network card. Data read from the NVMe drive via DMA can be placed in the page cache and then transferred to the NIC's transmit buffer via DMA, with the CPU only orchestrating the process.35 | A full-featured, general-purpose networking stack that exposes a POSIX-compliant sockets API. It must support a wide range of protocols, options (setsockopt), and concurrent connections from multiple, isolated processes. |
| **Userspace/Libc** | Minimal no\_std environment. The application is built against the kernel's internal APIs. If any C code is used, it would be linked against a minimal, custom library providing only the necessary functions. | Pure no\_std environment. The Kafka broker logic, rewritten or ported to Rust, becomes the "application payload" of the unikernel. There is no traditional userspace. | **Full C Standard Library Port**. This is a massive undertaking. It requires porting a complete libc like musl or using a Rust-native implementation like relibc.3 This involves implementing dozens of system calls that the library expects the kernel to provide. |
| **Core Challenge** | Fine-tuning the custom TCP/IP stack and the integrated async runtime to handle tens of thousands of concurrent connections with minimal latency. | Achieving a true, end-to-end zero-copy I/O path from the NVMe controller to the NIC at the hardware level, orchestrating DMA transfers across the PCIe bus with minimal CPU intervention. | The "ecosystem" problem: porting the entire software stack (libc, binutils, gcc/llvm) and implementing a robust, secure, and stable multi-process environment that can host these complex applications without crashing.38 |
| **Difficulty Score** | **8/10 (Very Hard)** | **9/10 (Extremely Hard)** | **10/10 (Monumental)** |

### **Section 8: Deep Dive \- The Hyper-Optimized Kafka Host**

This use case represents the most compelling argument for a custom OS. The goal is not to build an OS *for* Kafka, but to build an OS that *is* Kafka. In this model, the distinction between the kernel and the application dissolves, resulting in a single-purpose software appliance designed for one task: streaming data at the highest possible throughput and lowest possible latency.

#### **8.1. The Architectural Vision: The Unikernel Appliance**

The system would be architected as a unikernel.6 The Kafka broker logic, likely ported to or rewritten in Rust to leverage its safety and concurrency features, would be statically linked with the necessary kernel libraries (memory manager, scheduler, drivers) into one monolithic executable. This executable is the entire OS. When booted, it would initialize the hardware and immediately begin executing the Kafka broker logic in ring 0 (kernel mode). This design completely eliminates the overhead of system calls, context switches between user and kernel mode, and data copying across protection boundaries, as there are no boundaries.

#### **8.2. Exploiting Sequential I/O at the Block Level**

Apache Kafka's legendary performance is built upon its disciplined use of sequential disk I/O, which is orders of magnitude faster than random I/O, especially on mechanical drives but also significantly so on SSDs.32 A general-purpose filesystem, with its journaling, metadata updates, and block allocation strategies, introduces overhead and can lead to fragmentation, which disrupts this sequential access pattern.

A hyper-optimized Kafka OS would discard the traditional filesystem concept for its data partitions. The NVMe driver would expose the SSD as a raw block device. A simple, custom "log segment allocator" would be built on top of this. When a new Kafka topic partition is created, this allocator would reserve a large, multi-gigabyte contiguous region of blocks on the drive. All subsequent writes to that partition would be pure, sequential appends into this pre-allocated region, guaranteeing the most efficient possible write pattern for the underlying hardware.34

#### **8.3. The Ultimate Zero-Copy Data Path**

The term "zero-copy" is often used to describe how Linux can use the sendfile system call to send data from the page cache to a network socket without copying it into the application's userspace buffers.35 A unikernel architecture allows for a far more profound optimization.

The theoretical maximum-performance data path for a consumer reading from the Kafka host would be:

1. A consumer request arrives at the NIC.  
2. The Kafka logic determines which log segment and offset are needed.  
3. The OS instructs the NVMe driver to initiate a DMA transfer to read the requested data from the SSD.  
4. The NVMe controller transfers the data directly from the flash storage into a buffer in main memory (the page cache) via DMA, with no CPU involvement for the data movement itself.  
5. The OS then instructs the network driver to transmit this buffer.  
6. The network driver provides the physical address of this buffer to the NIC.  
7. The NIC performs a second DMA transfer, reading the data directly from the page cache buffer and sending it out over the network.

In this ideal path, the data payload itself is never touched by the CPU. The CPU's role is merely to orchestrate the DMA transfers between the peripherals. This is the performance ceiling, a goal achievable only when the storage driver, network driver, and application logic all reside in the same address space and can be tightly co-designed.36

#### **8.4. A Purpose-Built Scheduler**

The scheduler for this OS would be radically simple yet highly effective. It would not need to be "fair." Its only goal is to maximize I/O throughput. It could be a non-preemptive, priority-based scheduler. The threads responsible for handling network requests and disk I/O would be assigned the highest priority and would be allowed to run until they voluntarily yield (e.g., when waiting for the next I/O operation to complete). This minimizes context switches, which are pure overhead in this context, and keeps the CPU and I/O devices as busy as possible. Lower-priority threads could handle background tasks like log compaction or metrics reporting.

### **Section 9: Deep Dive \- The Self-Hosting Development Machine**

This use case represents the "final boss" of hobbyist OS development. A system is considered "self-hosting" when it possesses a complete enough toolchain to compile its own source code. Achieving this is the ultimate demonstration of a general-purpose operating system, as it requires a vast and complex software ecosystem to be functional. The difficulty shifts from pure hardware optimization to the monumental task of software porting and system integration.

#### **9.1. The Syscall Wall: Building a POSIX Foundation**

To run standard command-line tools like a shell, a text editor, or a compiler, the OS must provide a stable and largely POSIX-compliant system call API. This is a formidable barrier. The kernel must implement handlers for dozens of system calls, each with precise semantics. Key categories include:

* **Process Management**: fork() (creating a new process with a copy-on-write address space), execve() (replacing a process's image with a new program), waitpid() (waiting for a child process to terminate), exit(), and getpid(). The fork() and execve() combination is the cornerstone of Unix-like process creation.  
* **File Management**: A complete set of file-related syscalls, including open(), read(), write(), close(), lseek() (seeking within a file), and stat() (retrieving file metadata). These must operate correctly on a proper, on-disk filesystem.  
* **Memory Management**: mmap() (for mapping files into memory and anonymous memory allocation) and sbrk() (for managing the program's heap), which are fundamental to how modern allocators and dynamic linkers work.

#### **9.2. Porting the Toolchain: A Multi-Stage Campaign**

Building the toolchain is a project within the project, requiring a methodical, multi-stage bootstrapping process.38

1. **Stage 1: The Cross-Compiler**: The process begins on a host OS like Linux. A full cross-compilation toolchain must be built, targeting the custom OS. This involves compiling binutils (the assembler and linker) and GCC or LLVM/Clang with a custom target triplet (e.g., x86\_64-myos-elf).  
2. **Stage 2: Porting a C Standard Library**: This is the most critical and difficult porting task. A C library like musl or newlib must be ported to the custom OS. This is not a simple compilation. It involves writing an architecture-specific and OS-specific layer within the library, which consists of small assembly stubs that translate the C function calls (e.g., read()) into the actual system call instructions (e.g., syscall) required by the custom kernel. Every syscall the C library needs must be implemented by the kernel.  
3. **Stage 3: Building Native Tools**: Using the cross-compiler and the newly ported C library, one must then cross-compile a native version of the entire toolchain (binutils and GCC/LLVM) that can *run on the custom OS itself*. This is a major integration test; if the kernel's syscalls, filesystem, or process management are buggy, these complex applications will fail in spectacular ways.  
4. **Stage 4: The Bootstrap**: The final, triumphant step is to boot the custom OS, copy its own source code to its filesystem, and then use the now-native compiler (running on the custom OS) to re-compile the kernel and all system utilities. If this completes successfully, the system is officially self-hosting.

## **Part IV: Conclusion and Recommendations**

### **Section 10: Synthesis and Strategic Recommendations**

#### **10.1. Summary of Findings**

The development of a custom operating system in Rust on the specified Lenovo Legion Y540-15IRH hardware is an undertaking of exceptional difficulty, yet one that offers an unparalleled educational journey into the depths of computer systems. The analysis reveals that the project's complexity is not a fixed quantity but a variable determined by architectural ambition and the scope of hardware support. The user's constraint to ignore GPU support provides a significant, though partial, simplification, as the complexity of writing a driver for the modern Intel Wi-Fi card introduces a comparable challenge.

The most critical finding is that the value of a custom OS lies in its specialization. A targeted, single-purpose unikernel, while still a very hard project, is an achievable goal for a dedicated individual developer over a 1-2 year timeframe. In contrast, the creation of a general-purpose, self-hosting operating system is a monumental task that approaches the complexity of large-scale, long-term open-source projects and is likely beyond the practical reach of a solo developer, requiring a multi-year effort from a small team.

#### **10.2. Recommended Development Path**

For any developer or team embarking on this journey, a structured, incremental approach is paramount to managing complexity and making steady progress. The following strategic path is recommended:

1. **Start in Emulation**: All initial development must be conducted within an emulator, preferably QEMU. QEMU provides essential debugging facilities, such as a GDB stub for source-level kernel debugging, and the ability to rapidly test changes without the risk of crashing or damaging physical hardware. The development cycle of compile-test-debug is orders of magnitude faster in an emulated environment.  
2. **Follow the Masters**: Do not reinvent the wheel where established patterns exist. The developer should lean heavily on the wealth of existing resources. Philipp Oppermann's "Writing an OS in Rust" blog series provides a step-by-step tutorial that is the de-facto standard starting point for the community.1 The architectures of existing Rust-based operating systems like the microkernel-based Redox 3 and the unikernel Hermit 6 should be studied to understand different design philosophies and their trade-offs. For the intricate details of hardware programming, the OSDev.org wiki is an indispensable and authoritative reference.5  
3. **Incremental Hardware Enablement**: Once the kernel is stable and boots reliably within QEMU, the process of porting to the physical Lenovo hardware can begin. This must be done incrementally, starting with the simplest and most essential drivers. A logical progression would be:  
   * a. Serial Port (for debug output)  
   * b. Timer (HPET or APIC, for scheduling)  
   * c. Keyboard (for basic interaction)  
   * d. PCI Express bus enumeration  
   * e. AHCI/SATA driver (for the secondary disk)  
   * f. NVMe driver (for the primary disk)  
   * g. Ethernet driver (for networking)  
     The Wi-Fi driver should be considered a stretch goal, attempted only after the core system is fully stable, or scoped out of the project entirely to maintain focus.  
4. **Choose a Use Case Early and Commit**: The most crucial strategic decision is the selection of the final use case. As the analysis in Part III demonstrates, the architectural requirements for a Kafka host versus a self-hosting development machine are fundamentally divergent. This decision must be made early in Stage 2 of the development process, as it will dictate the design of the scheduler, the memory manager, and the entire I/O subsystem. Attempting to build a general-purpose platform first and specializing later will lead to a suboptimal design that carries the weight of compromises that a specialized system is meant to avoid. For a solo developer, choosing a focused unikernel-style project offers the highest probability of success and delivering a final product that is demonstrably superior for its chosen task than a general-purpose OS.

#### **Works cited**

1. Writing an OS in Rust, accessed on August 11, 2025, [https://os.phil-opp.com/](https://os.phil-opp.com/)  
2. OS Development : r/rust \- Reddit, accessed on August 11, 2025, [https://www.reddit.com/r/rust/comments/1clkw5q/os\_development/](https://www.reddit.com/r/rust/comments/1clkw5q/os_development/)  
3. Redox-OS.org, accessed on August 11, 2025, [https://www.redox-os.org/](https://www.redox-os.org/)  
4. RedoxOS \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/RedoxOS](https://en.wikipedia.org/wiki/RedoxOS)  
5. OSDev Wiki: Expanded Main Page, accessed on August 11, 2025, [https://wiki.osdev.org/Expanded\_Main\_Page](https://wiki.osdev.org/Expanded_Main_Page)  
6. The Hermit Operating System \- Rust OSDev, accessed on August 11, 2025, [https://rust-osdev.com/showcase/hermit/](https://rust-osdev.com/showcase/hermit/)  
7. The Hermit Operating System | A Rust-based, lightweight unikernel, accessed on August 11, 2025, [https://hermit-os.org/](https://hermit-os.org/)  
8. Intel Core i7-9750H \- Specs, Benchmark Tests, Comparisons, and Laptop Offers, accessed on August 11, 2025, [https://laptopmedia.com/processor/intel-core-i7-9750h/](https://laptopmedia.com/processor/intel-core-i7-9750h/)  
9. Intel Core i7-9750H benchmarks and review, vs i7-8750H and i7-7700HQ, accessed on August 11, 2025, [https://www.ultrabookreview.com/27050-core-i7-9750h-benchmarks/](https://www.ultrabookreview.com/27050-core-i7-9750h-benchmarks/)  
10. Core i7-9750H: Tech Specs \- Low End Mac, accessed on August 11, 2025, [https://lowendmac.com/1234/core-i7-9750h-tech-specs/](https://lowendmac.com/1234/core-i7-9750h-tech-specs/)  
11. Intel® Wireless-AC 9560 Support, accessed on August 11, 2025, [https://www.intel.com/content/www/us/en/products/sku/99446/intel-wirelessac-9560/support.html](https://www.intel.com/content/www/us/en/products/sku/99446/intel-wirelessac-9560/support.html)  
12. Intel® Wireless-AC 9560 Downloads, Drivers and Software, accessed on August 11, 2025, [https://www.intel.com/content/www/us/en/products/sku/99446/intel-wirelessac-9560/downloads.html](https://www.intel.com/content/www/us/en/products/sku/99446/intel-wirelessac-9560/downloads.html)  
13. Intel Core i7-9750H Specs \- CPU Database \- TechPowerUp, accessed on August 11, 2025, [https://www.techpowerup.com/cpu-specs/core-i7-9750h.c2290](https://www.techpowerup.com/cpu-specs/core-i7-9750h.c2290)  
14. x86-64 \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/X86-64](https://en.wikipedia.org/wiki/X86-64)  
15. X86-64 Architecture: A Developer's Primer | AppMaster, accessed on August 11, 2025, [https://appmaster.io/blog/x86-64-architecture-a-developers-primer](https://appmaster.io/blog/x86-64-architecture-a-developers-primer)  
16. Envisioning a Simplified Intel® Architecture, accessed on August 11, 2025, [https://www.intel.com/content/www/us/en/developer/articles/technical/envisioning-future-simplified-architecture.html](https://www.intel.com/content/www/us/en/developer/articles/technical/envisioning-future-simplified-architecture.html)  
17. Lenovo Legion Y540-15IRH \- PSREF, accessed on August 11, 2025, [https://psref.lenovo.com/syspool/Sys/PDF/Legion/Lenovo\_Legion\_Y540\_15IRH/Lenovo\_Legion\_Y540\_15IRH\_Spec.PDF](https://psref.lenovo.com/syspool/Sys/PDF/Legion/Lenovo_Legion_Y540_15IRH/Lenovo_Legion_Y540_15IRH_Spec.PDF)  
18. Specifications Performance CPU 2.6 GHz Intel Core i7-9750H 6-Core Maximum Boost Speed 4.5 GHz L3 Cache 12 MB Memory Type 2666 MH \- DubaiMachines.com, accessed on August 11, 2025, [https://dubaimachines.com/productattachments/download/link/id/11246/](https://dubaimachines.com/productattachments/download/link/id/11246/)  
19. Lenovo Legion Y540-15IRH-PG0 81SY | Overview, Specs, Details | SHI, accessed on August 11, 2025, [https://www.shi.com/product/37280864/Lenovo-Legion-Y540-15IRH-PG0-81SY](https://www.shi.com/product/37280864/Lenovo-Legion-Y540-15IRH-PG0-81SY)  
20. NVMe \- OSDev Wiki, accessed on August 11, 2025, [https://wiki.osdev.org/NVMe](https://wiki.osdev.org/NVMe)  
21. AHCI \- OSDev Wiki, accessed on August 11, 2025, [https://wiki.osdev.org/AHCI](https://wiki.osdev.org/AHCI)  
22. Building an AHCI Driver | blraaz.me, accessed on August 11, 2025, [https://blraaz.me/osdev/2021/06/29/building-ahci-driver.html](https://blraaz.me/osdev/2021/06/29/building-ahci-driver.html)  
23. RTL8169 \- OSDev Wiki, accessed on August 11, 2025, [https://wiki.osdev.org/RTL8169](https://wiki.osdev.org/RTL8169)  
24. Rust Programming Language, accessed on August 11, 2025, [https://www.rust-lang.org/](https://www.rust-lang.org/)  
25. Embedded Rust documentation, accessed on August 11, 2025, [https://docs.rust-embedded.org/](https://docs.rust-embedded.org/)  
26. phil-opp/blog\_os: Writing an OS in Rust \- GitHub, accessed on August 11, 2025, [https://github.com/phil-opp/blog\_os](https://github.com/phil-opp/blog_os)  
27. OSDev Wiki:About, accessed on August 11, 2025, [https://wiki.osdev.org/OSDev\_Wiki:About](https://wiki.osdev.org/OSDev_Wiki:About)  
28. Writing an OS in Rust, accessed on August 11, 2025, [https://os.phil-opp.com/fr/](https://os.phil-opp.com/fr/)  
29. \[SOLVED\] What Is The Best Way To Develop Drivers? \- OSDev.org, accessed on August 11, 2025, [https://forum.osdev.org/viewtopic.php?t=57398](https://forum.osdev.org/viewtopic.php?t=57398)  
30. I'm...very confused about my hard drive : r/osdev \- Reddit, accessed on August 11, 2025, [https://www.reddit.com/r/osdev/comments/rbunvk/imvery\_confused\_about\_my\_hard\_drive/](https://www.reddit.com/r/osdev/comments/rbunvk/imvery_confused_about_my_hard_drive/)  
31. Apache Kafka Tutorial for Efficient Kafka Optimization \- \- Dattell, accessed on August 11, 2025, [https://dattell.com/data-architecture-blog/apache-kafka-optimization/](https://dattell.com/data-architecture-blog/apache-kafka-optimization/)  
32. Apache Kafka and the File System | Confluent Documentation, accessed on August 11, 2025, [https://docs.confluent.io/kafka/design/file-system-constant-time.html](https://docs.confluent.io/kafka/design/file-system-constant-time.html)  
33. Kafka's Secret to High-Performance Disk Writes: Sequential I/O \- Level Up Coding, accessed on August 11, 2025, [https://levelup.gitconnected.com/kafkas-secret-to-high-performance-disk-writes-sequential-i-o-059426c7a008](https://levelup.gitconnected.com/kafkas-secret-to-high-performance-disk-writes-sequential-i-o-059426c7a008)  
34. Kafka writes data directly on disk? \- Codemia, accessed on August 11, 2025, [https://codemia.io/knowledge-hub/path/kafka\_writes\_data\_directly\_on\_disk](https://codemia.io/knowledge-hub/path/kafka_writes_data_directly_on_disk)  
35. What is Zero Copy in Kafka? | NootCode Knowledge Hub, accessed on August 11, 2025, [https://www.nootcode.com/knowledge/en/kafka-zero-copy](https://www.nootcode.com/knowledge/en/kafka-zero-copy)  
36. The Zero Copy Optimization in Apache Kafka \- 2 Minute Streaming, accessed on August 11, 2025, [https://blog.2minutestreaming.com/p/apache-kafka-zero-copy-operating-system-optimization](https://blog.2minutestreaming.com/p/apache-kafka-zero-copy-operating-system-optimization)  
37. Zero-copy \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/Zero-copy](https://en.wikipedia.org/wiki/Zero-copy)  
38. Porting GCC to your OS \- OSDev Wiki, accessed on August 11, 2025, [https://wiki.osdev.org/Porting\_GCC\_to\_your\_OS](https://wiki.osdev.org/Porting_GCC_to_your_OS)  
39. Building a Rust-based Web Server as a Unikernel with OPS: A Practical Guide \- Zenodo, accessed on August 11, 2025, [https://zenodo.org/records/14593561](https://zenodo.org/records/14593561)