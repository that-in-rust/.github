

# **Forging a New System: A Feasibility Analysis and Implementation Roadmap for a Custom Rust OS on the Lenovo Legion Y540 Platform**

## **Executive Summary & The Modern OS-Dev Endeavor**

### **Project Overview**

This report presents an exhaustive technical analysis of the endeavor to create a custom operating system (OS) from scratch using the Rust programming language. The specific hardware target for this analysis is the Lenovo Legion Y540-15IRH-PG0, a modern, high-performance laptop. The objective is to provide a clear, deeply researched assessment of the project's difficulty, delineate the specific challenges posed by the hardware components, and furnish a strategic roadmap for various potential use cases, from specialized server roles to interactive development environments. This document is intended for a technically proficient audience considering a significant systems programming project, offering the necessary depth to inform a go/no-go decision and strategic planning.

### **Core Thesis**

The difficulty of developing a custom Rust OS for this platform is not a single, static value; it is a dynamic variable determined by two critical factors: the chosen kernel architecture and the desired level of hardware support. Rust, with its powerful safety guarantees and compile-time checks, coupled with the mature ecosystem of tools and libraries curated by the rust-osdev community 1, significantly de-risks the development of core kernel components like memory management and scheduling. However, the project's ultimate feasibility and scope are overwhelmingly dictated by the challenge of writing device drivers for the system's complex, modern peripherals. The most formidable of these, acting as a "great filter" for the project's ambitions, is the proprietary NVIDIA GeForce GTX 1650 graphics processing unit (GPU).3 A successful outcome is contingent upon a pragmatic and strategic approach that prioritizes targeted, well-defined use cases over the monumental task of creating a general-purpose replacement for a mature OS like Linux.

### **Key Recommendations**

A thorough analysis of the hardware, software ecosystem, and project goals leads to the following primary recommendations:

1. **Adopt a Unikernel Architecture:** For server-side applications, such as a dedicated backend service or a high-throughput message queue host, a unikernel design offers the most direct path to success. This architecture, which co-packages the application with only the necessary OS libraries into a single, specialized image, perfectly aligns with the goal of a minimal, highly optimized system. Projects like Hermit, a unikernel written in Rust, provide an excellent conceptual and practical foundation for this approach.6  
2. **Strategically Abandon the GPU:** The NVIDIA GPU represents the project's single greatest technical obstacle. A pragmatic strategy involves treating the discrete GPU as inert hardware for the purposes of the custom OS. The focus should be on headless operation for server tasks or basic text-mode interaction via the UEFI-provided framebuffer. Attempting to write a hardware-accelerated graphics driver from scratch would divert the project into a multi-year reverse-engineering effort, eclipsing the primary goal of building a functional operating system.  
3. **Implement a Phased Development Plan:** The project should be executed in discrete, manageable phases. Initial development should occur within an emulated environment like QEMU to rapidly iterate on the core kernel. Subsequent phases should incrementally add support for real hardware, beginning with the most critical and well-documented components (CPU, memory, NVMe storage) before tackling more esoteric peripherals.

## **The Foundational Challenge \- From Power-On to a Rust main()**

This section deconstructs the initial, fundamental steps of OS development. It demonstrates how Rust's language features and ecosystem provide a more robust and safer foundation for these critical tasks compared to traditional systems programming languages like C.

### **The "From Scratch" Spectrum: Defining the Starting Line**

In the context of modern computing hardware, building an OS "from scratch" does not imply writing every single byte from the initial boot sector. Such an approach is unnecessary and counterproductive on contemporary systems. The Lenovo Legion Y540, like all modern PCs, utilizes the Unified Extensible Firmware Interface (UEFI) rather than the legacy Basic Input/Output System (BIOS).8 This is a significant advantage. UEFI provides a standardized, high-level environment that simplifies the process of loading an OS kernel.

Therefore, the project's starting line is not at the level of 16-bit real mode but at the interface to the UEFI firmware. The task is to create a UEFI-compatible application—the OS kernel—that the firmware can load and execute. This approach intelligently leverages the existing, standardized platform firmware to handle the low-level hardware initialization, allowing the developer to focus on the kernel itself.

There are two primary, well-supported pathways for this in the Rust ecosystem:

1. **Direct UEFI Application:** The uefi-rs crate is a cornerstone of the Rust OS development community.2 It provides safe, idiomatic Rust wrappers around the UEFI protocol. Using this library, the kernel can be built as a standalone UEFI application. The library handles the complex details of the UEFI interface, providing the kernel with essential information upon startup, such as a map of available physical memory and access to a basic graphics framebuffer for console output. This is the most direct and modern approach.  
2. **Multiboot2 Bootloader:** An alternative is to use a standard, pre-existing bootloader like GRUB, which supports the Multiboot2 specification. The bootloader is responsible for loading the kernel from disk and then passes control to it, along with a data structure containing information about the machine state. The multiboot2 crate can then be used within the Rust kernel to safely parse this boot information structure.2

### **The Rust Advantage: \#\[no\_std\] and the Core Libraries**

Rust is uniquely suited for systems development due to its standard library's deliberate, tiered design.1 An operating system, by its very nature, cannot depend on another operating system's services for fundamental operations like file I/O, networking, or memory allocation. Rust accommodates this reality through a powerful mechanism that allows developers to shed these dependencies incrementally.

The entry point into bare-metal Rust programming is the \#\!\[no\_std\] attribute, placed at the root of the crate.10 This attribute instructs the compiler to not link the standard library (

std), which contains all the OS-dependent functionalities. This leaves the developer with a minimal but powerful set of tools provided by two foundational libraries:

* **core:** This library is the absolute bedrock of Rust. It is platform-agnostic and provides the primitive types (u64, bool, char), fundamental control flow macros (if, for, while), and core concepts like Traits and Options that have no external dependencies.1 It is the minimum required to write any Rust code.  
* **alloc:** This library sits one level above core. It provides the common heap-allocated data structures that are essential for any complex program, such as Box\<T\> (a pointer to heap-allocated data), Vec\<T\> (a dynamic array), and String.1 Crucially, the  
  alloc library does not contain a memory allocator itself. Instead, it defines a standard interface (GlobalAlloc trait) that the OS kernel must implement.

This separation forces a disciplined and safe development methodology. To gain access to convenient data structures like Vec, the developer must first successfully implement the kernel's memory management subsystem (paging and a heap allocator). This architectural choice prevents entire classes of bugs common in C-based OS development, where one might accidentally attempt to use dynamic memory before the memory manager is initialized. It imposes a logical and safe order of operations: establish control over memory, then use abstractions that rely on that control. This structured approach is a key feature that enhances both productivity and the final system's robustness.

### **Core Kernel Milestones: Building the Pillars of the OS**

With the \#\[no\_std\] foundation, the initial development of the kernel involves constructing a series of foundational pillars. The path is well-trodden and excellently documented by resources like Philipp Oppermann's "Writing an OS in Rust" blog series.10

* **CPU Initialization (x86\_64):** The first task upon gaining control from the bootloader is to configure the CPU for protected, 64-bit operation. This involves setting up critical data structures like the Global Descriptor Table (GDT), which defines memory segments, and the Interrupt Descriptor Table (IDT), which maps interrupts and exceptions to handler functions. The x86\_64 crate provides type-safe, validated abstractions for these structures, abstracting away much of the error-prone manual bit-twiddling required in C.2  
* **Handling CPU Exceptions:** A robust kernel must be able to gracefully handle hardware exceptions—errors detected by the CPU such as division by zero or attempts to access invalid memory (page faults). The kernel must register handlers for these exceptions in the IDT. Implementing these handlers, especially a "double fault" handler for when an exception handler itself fails, is a critical early step to prevent the system from entering a fatal "triple fault" state, which causes an immediate reset.10  
* **Memory Management:** This is arguably the most complex part of core kernel development.  
  * **Paging:** The Intel i7-9750H processor employs a 4-level paging scheme to translate virtual memory addresses used by software into physical addresses that correspond to RAM chips.12 The kernel must take the memory map provided by UEFI, identify available physical memory frames, and construct a set of page tables. This process enables fundamental OS features like memory isolation between processes and virtual memory. A key task is mapping the kernel's own code and data into a "higher-half" of the virtual address space, separating it from future user-space applications. This is a complex but well-understood procedure, with detailed guides available.10  
  * **Heap Allocator:** Once paging is functional and the kernel has a region of virtual memory it can manage, it must implement a heap allocator. This is the component that satisfies the GlobalAlloc trait required by the alloc crate. Common designs include simple but fragment-prone "bump allocators," more complex "linked-list allocators," or efficient "fixed-size block allocators".10 With a working allocator, the kernel can finally use  
    Vec, Box, and other essential dynamic data structures.  
* **Interrupts and Scheduling:** To move beyond a single-threaded program, the kernel must handle hardware interrupts. On modern systems like the Y540, this involves configuring the Advanced Programmable Interrupt Controller (APIC) on the CPU. The APIC is responsible for routing interrupts from hardware devices to the CPU cores. By enabling the timer interrupt, the kernel can implement preemption, periodically interrupting a running task to give another task a chance to run. This forms the basis of a scheduler, enabling multitasking and the eventual execution of multiple concurrent programs.

## **The Hardware Gauntlet \- A System-Specific Driver Analysis**

This section moves from the general principles of OS development to the specific and arduous reality of enabling the hardware components of the Lenovo Legion Y540. The difficulty of writing a driver for each component varies dramatically, with some being straightforward and others representing near-insurmountable challenges.

### **CPU and Chipset (Intel i7-9750H / HM370)**

The central processing unit is a 9th Generation Intel Core i7-9750H, a high-performance mobile processor based on the "Coffee Lake-HR" microarchitecture.12 It is a standard 64-bit x86 processor with 6 cores and 12 threads via Hyper-Threading. Its instruction set architecture and features—including advanced vector extensions like AVX2, virtualization technologies like VT-x and VT-d, and power management features like Speed Shift Technology—are well-documented by Intel and thoroughly supported by existing Rust crates like

x86\_64.2 At a fundamental level, getting the CPU to execute instructions is the most straightforward part of the hardware enablement process.

The CPU communicates with the rest of the system via the Intel HM370 chipset.17 The chipset acts as a hub for I/O devices. To discover and configure these devices, the kernel must parse the ACPI (Advanced Configuration and Power Interface) tables provided by the firmware. These tables describe the system's hardware layout. The

acpi crate from the rust-osdev organization is an essential tool for this task, providing a safe interface to this complex data.2

### **Storage (PCIe NVMe SSD)**

The laptop is equipped with a high-speed PCIe NVMe Solid State Drive.3 NVM Express (NVMe) is a modern protocol designed specifically for fast, non-volatile storage, offering much higher performance than the older SATA protocol.

* **The Challenge:** Writing an NVMe driver is a significant undertaking. It requires a deep understanding of several complex technologies. First, the driver must communicate over the PCIe bus, discovering the device and mapping its configuration space into memory. Communication with the device itself is done via Memory-Mapped I/O (MMIO) and, crucially, Direct Memory Access (DMA). DMA allows the NVMe controller to read and write data directly to and from the system's main memory, bypassing the CPU. While this is key to its high performance, it is also extremely dangerous from a programming perspective. A bug in the DMA setup could allow the hardware to corrupt arbitrary parts of kernel memory, leading to catastrophic and difficult-to-debug system failures. This necessitates careful and extensive use of unsafe Rust code, cordoned off behind safe abstractions. The driver must also manage the NVMe protocol's sophisticated queueing mechanism, which involves setting up submission and completion queues in memory for the hardware to process.  
* **Existing Work and Feasibility:** Despite the complexity, this is a solvable problem. The path to writing an NVMe driver in Rust is illuminated by several high-quality reference implementations:  
  * The Linux kernel project now officially includes a PCI NVMe driver written in Rust, known as rnvme.20 While performance benchmarks show it is still being optimized to match the highly-tuned C driver in all scenarios, its existence is definitive proof of feasibility and provides an invaluable, production-quality codebase to study.20  
  * Other projects, such as the Redox OS and the userspace driver vroom, also provide complete Rust implementations of NVMe drivers.22 The bachelor's thesis detailing the implementation of  
    vroom is a particularly useful resource for understanding the driver's architecture from the ground up.23  
* **Difficulty Assessment:** Significant, but achievable. The availability of multiple open-source Rust drivers transforms this from a research project into an engineering one. A developer can learn from existing code to build a functional driver for the custom OS.

### **Networking (Gigabit Ethernet & Intel Wireless-AC 9560\)**

The laptop provides two networking interfaces: a wired Gigabit Ethernet port and a wireless card.3

* **Ethernet:** The wired connection is managed by a Realtek Gigabit Ethernet controller.3 Writing a driver for a standard PCIe network interface card (NIC) is a classic OS development task. It involves similar principles to the NVMe driver: interacting with the device via PCIe, setting up descriptor rings for transmitting and receiving packets via DMA, and handling interrupts to signal that new data has arrived. On top of the driver, the OS needs a network stack to handle protocols like TCP/IP. The  
  smoltcp library is a popular, high-quality choice for a pure-Rust, bare-metal TCP/IP stack.  
* **Wi-Fi:** The Intel Wireless-AC 9560 card is a far more complex beast.3 Modern Wi-Fi cards are not simple packet movers; they are sophisticated co-processors that run their own internal software. To function, these cards require the host OS driver to load a large, proprietary firmware "blob" into their memory at initialization. The driver must then communicate with this firmware to manage the intricate state machines of the 802.11 protocol, handle various authentication and encryption schemes (WPA2/3), and perform radio frequency management. The complexity is an order of magnitude greater than that of a wired NIC.  
* **Difficulty Assessment:** Writing the Ethernet driver is challenging but a well-understood problem. Writing a driver for the Wi-Fi card from scratch is extremely difficult and likely infeasible for a solo developer without specialized expertise in wireless protocols and firmware reverse engineering. For the purposes of this project, a pragmatic approach would be to focus solely on the wired Ethernet connection.

### **The NVIDIA GPU (GTX 1650\) \- The Great Filter**

This single component is the project's most significant technical hurdle and the primary factor that constrains its feasible scope.

* **The Hardware:** The laptop contains an NVIDIA GeForce GTX 1650 Mobile GPU.3 This is a powerful graphics card based on the TU117 variant of the Turing architecture.4 It is a complex co-processor featuring up to 1024 CUDA cores, dedicated hardware for video encoding and decoding (NVENC/NVDEC), and a sophisticated power management system.4  
* **The Driver Impasse:** The path to controlling this hardware is effectively blocked.  
  * **Proprietary Lock-in:** NVIDIA's business model is built on its software stack. The drivers that control their GPUs are highly proprietary and closed-source, and the low-level hardware programming interfaces are not publicly documented.27  
  * **The nouveau Project:** The open-source community's attempt to create a free driver, known as nouveau, is a testament to the difficulty of this task. It is a massive, collaborative reverse-engineering effort that has been ongoing for over a decade.28 For modern GPUs like the Turing-based GTX 1650,  
    nouveau is still heavily reliant on signed firmware blobs provided by NVIDIA to perform essential functions like setting clock speeds for proper performance. Without this firmware, the card is largely unusable for demanding tasks.28 Replicating even a fraction of the  
    nouveau project's work is not a viable goal for a single developer building a new OS.  
  * **The Role of CUDA:** It is important to clarify that NVIDIA's CUDA platform is a parallel computing API for GPGPU (General-Purpose computing on GPUs).29 It is a user-space library and toolchain that allows developers to run computations on the GPU. It  
    *requires* a fully functional, pre-existing NVIDIA kernel driver to be installed on the system. CUDA is a tool for *using* the GPU, not for *building the driver* that controls it.  
* **Practical Implications:** The inability to write a functional driver for the GTX 1650 has profound consequences for the project's scope.  
  * Any form of hardware-accelerated graphics, whether through OpenGL or Vulkan APIs, is infeasible.  
  * The most that can be realistically achieved is a basic, unaccelerated graphics mode. The UEFI firmware can initialize the display in a simple framebuffer mode, and the uefi-rs library can provide the kernel with a pointer to this framebuffer, allowing it to draw pixels and display a low-resolution console.2 For more advanced text-mode output, the legacy  
    vga crate could be used, but this is a step back from the UEFI framebuffer.2  
  * Consequently, all potential use cases that depend on the GPU—such as a modern graphical user interface (GUI), gaming, or machine learning acceleration—are off the table.

The presence of this specific GPU forces a fundamental, strategic decision at the very beginning of the project. The developer must choose one of two paths. Path A is to accept the limitation, treat the powerful GPU as dead weight, and commit to building a headless or text-mode operating system. Path B is to redefine the project's goal entirely, shifting from "building a custom OS" to "embarking on a multi-year, likely fruitless, quest to reverse-engineer a modern NVIDIA GPU." The former is very difficult; the latter is effectively impossible for a solo developer.

### **Essential Peripherals (Keyboard, Trackpad, USB, Audio)**

Beyond the core components, a fully functional system requires drivers for a host of smaller peripherals.

* **Keyboard and Trackpad:** On modern laptops, these input devices are typically connected internally via a PS/2, I2C, or SMBus interface. The ps2-mouse crate provides a starting point if the interface is PS/2.2 If it is I2C or SMBus, a driver would need to be written for the specific controller on the HM370 chipset.  
* **USB:** The system features multiple USB 3.1 ports.9 A complete USB stack is a major software project in itself. It requires a host controller driver (for the xHCI controller on the chipset), a hub driver to manage port expansion, and finally, class drivers for specific device types (e.g., mass storage, HID for keyboards/mice). While a kernel-level project, the existence of user-space Rust libraries like  
  rusb demonstrates that the complex USB protocol can be managed effectively in Rust, and these can serve as a conceptual guide.31  
* **Audio:** The audio hardware is a Realtek ALC3287 codec, which communicates over the Intel High Definition Audio bus.8 This is another complex subsystem that requires a sophisticated driver to discover the codec's capabilities, configure its components, and manage audio data streams.

For a specialized OS, these peripherals are often low-priority. They add significant development time and are not essential for many server-side use cases.

## **Architectural Crossroads \- Monolith, Microkernel, or Unikernel?**

The high-level architecture of the kernel is a critical design decision that influences the system's security, modularity, and performance characteristics. The choice of architecture should be driven by the project's ultimate goals.

### **The Traditional Paths**

* **Monolithic Kernel:** This is the architecture used by mainstream operating systems like Linux and Windows. In a monolithic kernel, all core OS services—including the scheduler, memory manager, filesystem, network stack, and all device drivers—run together in a single, privileged address space (kernel space). The primary advantage is performance; communication between components is as fast as a simple function call. The main disadvantages are reduced security and robustness. A bug in any single component, such as a device driver, can crash the entire system. The large, complex codebase also makes it harder to develop and maintain.  
* **Microkernel:** In contrast, a microkernel aims for maximum modularity and security. Only the absolute minimum set of services runs in the privileged kernel space—typically just Inter-Process Communication (IPC), basic scheduling, and virtual memory management. All other services, including device drivers, filesystems, and network stacks, are implemented as separate, unprivileged user-space processes. Communication happens via the kernel's IPC mechanism. This design is highly robust and secure, as a crash in a driver will not bring down the kernel. However, it can incur a performance penalty due to the overhead of context switching between processes for communication. The Redox OS is a prominent example of a microkernel-based OS written in Rust.32

### **The Specialized Path: The Unikernel**

There is a third architectural option that aligns remarkably well with the prompt's request for a specialized, optimized OS: the unikernel.

* **Concept:** A unikernel is a highly specialized, single-purpose machine image. It is constructed by linking an application directly with only the specific operating system libraries it needs to run.6 The result is a single executable file that contains the application, its dependencies, and a minimal OS kernel, all running in a single address space. There is no distinction between user space and kernel space, and there are no system calls in the traditional sense; services are accessed via direct function calls.  
* **The Hermit Project:** Hermit is a mature, high-performance unikernel written entirely in Rust.6 It is designed specifically for cloud and high-performance computing workloads. It provides its own networking stack and can be booted directly on a hypervisor. Because it links against standard Rust libraries, many existing Rust applications can be compiled to run on Hermit with little or no modification.

The concept of a unikernel is the logical conclusion of the desire for a specialized system. The user's request for an OS that is "optimized for a specific use case" and "may not need everything that a linux offers" is the precise problem statement that unikernels are designed to solve. A monolithic or microkernel OS, even when stripped down, still carries the architectural baggage of being a general-purpose system, such as the mechanisms for user/kernel separation and system calls. A unikernel dispenses with this overhead entirely. For a dedicated server appliance—like a web server, database, or Kafka host—this results in a minimal attack surface, a smaller memory footprint, and potentially higher performance by eliminating the boundary-crossing overhead between the application and the kernel. For the server-oriented use cases described in this report, the unikernel model is not merely an option; it is the most direct and philosophically aligned architecture.

## **Use Case Deep Dive: A Strategic Implementation Matrix**

To provide a concrete assessment of difficulty, this section presents a matrix of potential use cases for a custom Rust OS on the Lenovo Legion Y540. The matrix breaks down each goal into its core requirements, identifies the primary obstacles, recommends a suitable architecture, and provides an expert-level estimate of the development effort required for a solo developer with relevant expertise.

The following table serves as a strategic guide, allowing for a direct comparison of the trade-offs involved in pursuing different project ambitions. Each column is designed to answer a key question for the developer: What components must be built? What are the hardest parts? What is the best high-level design? How long will this realistically take?

| Use Case | Core OS Components Required | Key Implementation Hurdles & Hardware Dependencies | Recommended Architecture | Estimated Difficulty (Solo Expert Developer) |
| :---- | :---- | :---- | :---- | :---- |
| **1\. Headless Backend Server***(e.g., REST API, Database)* | UEFI Boot (uefi-rs), Paging, Heap Allocator, Scheduler, Interrupts (APIC), NVMe Driver, Ethernet Driver, TCP/IP Stack (smoltcp). | **NVMe Driver:** Requires mastering DMA and careful management of unsafe Rust. **Ethernet Driver:** A standard but non-trivial PCIe device interaction task. **Robustness:** The system must be stable for long-running server tasks, demanding meticulous error handling throughout the kernel and drivers. | **Unikernel (Hermit-based)** or **Custom Monolith**. The unikernel approach is highly recommended for its inherent simplicity, security benefits, and performance potential for I/O-bound applications. | **6-12 Person-Months.** This is a challenging but achievable project. The development path is well-defined by existing Rust OS projects and tutorials. |
| **2\. High-Throughput Kafka Host** | All components from Use Case 1, plus: Highly optimized, zero-copy networking and storage paths. A sophisticated, low-latency scheduler designed for I/O workloads. | **Performance Tuning:** The primary hurdle is moving beyond a "working" driver to one that can saturate the hardware and compete with the performance of tuned C drivers.20 This requires deep system profiling and optimization of the entire I/O path, from the network card's DMA buffers to the NVMe controller's submission queues. | **Unikernel (Hermit-based).** This is the ideal scenario for a unikernel. By eliminating the kernel/user context switch and memory copies associated with system calls, a unikernel can achieve extremely low-latency I/O, which is critical for a message broker like Kafka.6 | **12-18 Person-Months.** The core development is similar to the general backend server, but the additional effort required for deep performance optimization is significant and should not be underestimated. |
| **3\. Minimalist Text-Mode Dev Machine** | All components from Use Case 1, plus: Keyboard Driver (PS/2 or I2C), Basic Filesystem (e.g., FAT32 for interoperability), Serial Port Driver (for debugging), a simple Shell/REPL. | **Keyboard Driver:** Requires identifying the specific bus (PS/2, I2C, SMBus) used by the laptop's embedded controller and writing a corresponding driver. **Filesystem:** Implementing a robust, writable filesystem is a complex task involving buffer caching and careful state management. **Toolchain:** Porting a full compiler like rustc to run on the new OS is a massive project in its own right. More realistically, this machine would be used for editing text files and cross-compiling from a separate, fully-featured host. | **Custom Monolith.** A unikernel is poorly suited for an interactive, general-purpose environment that implies running arbitrary command-line tools. The monolithic architecture is the classic choice for this type of hobby OS project. | **18-24 Person-Months.** The scope expands considerably beyond a single-purpose appliance. The addition of interactive user input, a filesystem, and a shell introduces significant new complexity. |
| **4\. Graphical Desktop Dev Machine** | All components from Use Case 3, plus: **GPU Driver (NVIDIA)**, Windowing System, GUI Toolkit, Mouse/Trackpad Driver, Audio Driver. | **NVIDIA GPU Driver:** **Effectively impossible.** As detailed exhaustively in Section 3.4, this is the project's definitive showstopper. The lack of public documentation and the immense scale of the nouveau reverse-engineering effort make this goal unattainable.27 | **N/A (Infeasible).** The hardware constraints imposed by the proprietary NVIDIA GPU render this goal unattainable from scratch. | **Many Person-Years.** This is considered infeasible for a solo developer. The project ceases to be about building an OS and becomes entirely about the single, monumental task of writing an open-source NVIDIA driver. |
| **5\. Virtualization Host (VMM)** | UEFI Boot, Paging, Scheduler, plus: Intel VT-x support, Extended Page Tables (EPT), VT-d for device passthrough (IOMMU). | **Virtualization Complexity:** Requires a deep and expert-level understanding of the Intel virtualization architecture, as detailed in the Intel developer manuals.13 Writing a Virtual Machine Monitor (VMM) is a task as complex as writing an OS kernel itself. Rust's safety features, however, are a tremendous benefit in this domain, helping to prevent subtle bugs in the VMM that could compromise guest isolation. | **Specialized Monolith.** The VMM *is* the kernel. Its sole purpose is to manage and run guest virtual machines. | **24-36+ Person-Months.** An expert-level project on par with the most complex systems programming tasks. It is a niche where Rust's unique combination of low-level control and high-level safety abstractions is exceptionally valuable. |

## **A Pragmatic Roadmap and Final Recommendations**

Synthesizing the preceding analysis, this final section provides a concrete, phased development plan and a set of concluding strategic recommendations to maximize the probability of a successful and educational outcome.

### **The Phased Approach: From Simulation to Metal**

A project of this magnitude should not be attempted as a single, monolithic effort. A phased approach, starting in a controlled environment and incrementally adding complexity, is essential.

* **Phase 1: The Sandbox (1-2 months).** All initial development should take place within the QEMU emulator. This provides a fast and forgiving development cycle. The primary resource for this phase is Philipp Oppermann's blog\_os tutorial series.10 The goal is to produce a bootable kernel image that can print to the VGA console, correctly handle CPU exceptions, and has a functional heap allocator, enabling the use of the  
  alloc crate.  
* **Phase 2: First Contact (2-4 months).** The focus shifts to booting on the real Lenovo Legion Y540 hardware. The kernel must be compiled as a UEFI application using uefi-rs.2 The initial goal is to successfully boot and establish a stable debugging loop. This typically involves getting output to the UEFI framebuffer and enabling logging over a serial port (if a physical port or USB-to-serial adapter can be made to work).  
* **Phase 3: The I/O Gauntlet (4-8 months).** This phase involves tackling the first major device driver. The PCIe NVMe SSD driver is the logical choice, as it is essential for any useful system and has excellent Rust reference implementations available for study.20 This will be the project's first major trial-by-fire with  
  unsafe Rust, DMA, and direct hardware interaction. Success in this phase is a major milestone.  
* **Phase 4: Specialization (Ongoing).** With the core platform stabilized, development diverges based on the chosen use case from the matrix in Section 5\. For a unikernel, this involves integrating the target application (e.g., a web server framework) and beginning the long process of performance optimization. For a text-mode OS, this phase involves building the keyboard driver, a simple filesystem, and a command-line shell.

### **Final Recommendations**

The success of this ambitious project hinges less on raw coding velocity and more on strategic wisdom and pragmatic scoping. The following three recommendations are paramount:

1. **Embrace the Unikernel:** For the server-side use cases that form the most viable paths for this project, the unikernel architecture is the superior choice. It directly addresses the goal of a minimal, optimized system, sidesteps the complexity of building a general-purpose OS, and delivers a secure, high-performance result. The source code of the Hermit project should be used as a primary reference and inspiration.34  
2. **Abandon the GPU:** The single most important decision to ensure the project's feasibility is to acknowledge that writing a hardware-accelerated driver for the NVIDIA GTX 1650 is not possible within a reasonable timeframe. The project must be re-scoped to be either headless or text-based. This one decision transforms the project from a Sisyphean task into one that is merely very, very difficult.  
3. **Leverage the Community:** This journey should not be undertaken in isolation. The Rust OS development community is a vibrant and supportive ecosystem. The resources provided by the rust-osdev GitHub organization 2, the detailed tutorials 10, and the source code of existing projects like Redox 32 and Hermit 34 are the project's most valuable assets.

### **Conclusion: The Ultimate Learning Endeavor**

While the creation of a production-ready, general-purpose operating system to rival Linux on this hardware is beyond the reach of a solo developer, the goal of building a specialized, functional system is a monumental but achievable capstone project. It offers an unparalleled, hands-on education in the deepest workings of modern computer systems, from the firmware interface and hardware device protocols to the highest levels of software architecture. The Rust programming language, with its emphasis on safety and its well-designed abstractions for low-level programming, is an ideal tool for this task. Ultimately, success lies not in an attempt to build everything, but in the wisdom to make strategic choices, the pragmatism to scope the project realistically, and the diligence to build upon the powerful foundations laid by the broader Rust and systems development communities.

#### **Works cited**

1. Rust \- OSDev Wiki, accessed on August 11, 2025, [https://wiki.osdev.org/Rust](https://wiki.osdev.org/Rust)  
2. Rust OSDev \- GitHub, accessed on August 11, 2025, [https://github.com/rust-osdev](https://github.com/rust-osdev)  
3. Order Code – 23246640.2.4 Laptop Specifications \- • 9th Generation Intel Core i7-9750H 6-Core Processor (Up to 4.5GHz) with, accessed on August 11, 2025, [https://www.tescaglobal.com/assets/photo/product/file/file-7583-1701080610.pdf](https://www.tescaglobal.com/assets/photo/product/file/file-7583-1701080610.pdf)  
4. NVIDIA GeForce GTX 1650 Specs | TechPowerUp GPU Database, accessed on August 11, 2025, [https://www.techpowerup.com/gpu-specs/geforce-gtx-1650.c3366](https://www.techpowerup.com/gpu-specs/geforce-gtx-1650.c3366)  
5. NVIDIA GeForce GTX 1650 (Laptop, 50W) \- LaptopMedia, accessed on August 11, 2025, [https://laptopmedia.com/video-card/nvidia-geforce-gtx-1650-laptop-50w/](https://laptopmedia.com/video-card/nvidia-geforce-gtx-1650-laptop-50w/)  
6. The Hermit Operating System | Rust OSDev, accessed on August 11, 2025, [https://rust-osdev.com/showcase/hermit/](https://rust-osdev.com/showcase/hermit/)  
7. The Hermit Operating System | A Rust-based, lightweight unikernel, accessed on August 11, 2025, [https://hermit-os.org/](https://hermit-os.org/)  
8. Lenovo Legion Y540-15IRH-PG0 81SY | Overview, Specs, Details | SHI, accessed on August 11, 2025, [https://www.shi.com/product/37280864/Lenovo-Legion-Y540-15IRH-PG0-81SY](https://www.shi.com/product/37280864/Lenovo-Legion-Y540-15IRH-PG0-81SY)  
9. Lenovo Legion Y540-15IRH-PG0 \- OVERVIEW, accessed on August 11, 2025, [https://psref.lenovo.com/syspool/Sys/PDF/Legion/Lenovo\_Legion\_Y540\_15IRH\_PG0/Lenovo\_Legion\_Y540\_15IRH\_PG0\_Spec.pdf](https://psref.lenovo.com/syspool/Sys/PDF/Legion/Lenovo_Legion_Y540_15IRH_PG0/Lenovo_Legion_Y540_15IRH_PG0_Spec.pdf)  
10. Writing an OS in Rust, accessed on August 11, 2025, [https://os.phil-opp.com/](https://os.phil-opp.com/)  
11. phil-opp/blog\_os: Writing an OS in Rust \- GitHub, accessed on August 11, 2025, [https://github.com/phil-opp/blog\_os](https://github.com/phil-opp/blog_os)  
12. Core i7-9750H \- Intel \- WikiChip, accessed on August 11, 2025, [https://en.wikichip.org/wiki/intel/core\_i7/i7-9750h](https://en.wikichip.org/wiki/intel/core_i7/i7-9750h)  
13. Intel Core i7-9750H Specs \- CPU Database \- TechPowerUp, accessed on August 11, 2025, [https://www.techpowerup.com/cpu-specs/core-i7-9750h.c2290](https://www.techpowerup.com/cpu-specs/core-i7-9750h.c2290)  
14. Intel Core i7-9750H \- Specs, Benchmark Tests, Comparisons, and Laptop Offers, accessed on August 11, 2025, [https://laptopmedia.com/processor/intel-core-i7-9750h/](https://laptopmedia.com/processor/intel-core-i7-9750h/)  
15. Intel Core i7-9750H benchmarks and review, vs i7-8750H and i7-7700HQ, accessed on August 11, 2025, [https://www.ultrabookreview.com/27050-core-i7-9750h-benchmarks/](https://www.ultrabookreview.com/27050-core-i7-9750h-benchmarks/)  
16. Intel® Core™ i7-9750H Processor (12M Cache, up to 4.50 GHz) \- Product Specifications, accessed on August 11, 2025, [https://www.intel.com/content/www/us/en/products/sku/191045/intel-core-i79750h-processor-12m-cache-up-to-4-50-ghz/specifications.html](https://www.intel.com/content/www/us/en/products/sku/191045/intel-core-i79750h-processor-12m-cache-up-to-4-50-ghz/specifications.html)  
17. Intel® Core™ i7-9750H Processor, accessed on August 11, 2025, [https://www.intel.com/content/www/us/en/products/sku/191045/intel-core-i79750h-processor-12m-cache-up-to-4-50-ghz/compatible.html](https://www.intel.com/content/www/us/en/products/sku/191045/intel-core-i79750h-processor-12m-cache-up-to-4-50-ghz/compatible.html)  
18. Lenovo Legion Y540-15IRH \- PSREF, accessed on August 11, 2025, [https://psref.lenovo.com/syspool/Sys/PDF/Legion/Lenovo\_Legion\_Y540\_15IRH/Lenovo\_Legion\_Y540\_15IRH\_Spec.PDF](https://psref.lenovo.com/syspool/Sys/PDF/Legion/Lenovo_Legion_Y540_15IRH/Lenovo_Legion_Y540_15IRH_Spec.PDF)  
19. Intel Core i7 9750H @ 3790.38 MHz \- CPU-Z VALIDATOR, accessed on August 11, 2025, [https://valid.x86.fr/uzg0gq](https://valid.x86.fr/uzg0gq)  
20. NVMe Driver \- Rust for Linux, accessed on August 11, 2025, [https://rust-for-linux.com/nvme-driver](https://rust-for-linux.com/nvme-driver)  
21. A pair of Rust kernel modules \- LWN.net, accessed on August 11, 2025, [https://lwn.net/Articles/907685/](https://lwn.net/Articles/907685/)  
22. bootreer/vroom: userspace nvme driver \- GitHub, accessed on August 11, 2025, [https://github.com/bootreer/vroom](https://github.com/bootreer/vroom)  
23. Writing an NVMe Driver in Rust \- Technische Universität München, accessed on August 11, 2025, [https://db.in.tum.de/\~ellmann/theses/finished/24/pirhonen\_writing\_an\_nvme\_driver\_in\_rust.pdf](https://db.in.tum.de/~ellmann/theses/finished/24/pirhonen_writing_an_nvme_driver_in_rust.pdf)  
24. NVIDIA TU117 GPU Specs \- TechPowerUp, accessed on August 11, 2025, [https://www.techpowerup.com/gpu-specs/nvidia-tu117.g881](https://www.techpowerup.com/gpu-specs/nvidia-tu117.g881)  
25. NVIDIA GeForce GTX 1650 Mobile: Detailed Specifications and Benchmark Ratings, accessed on August 11, 2025, [https://cputronic.com/gpu/nvidia-geforce-gtx-1650-mobile](https://cputronic.com/gpu/nvidia-geforce-gtx-1650-mobile)  
26. Number of SMXs of GeForce GTX 1650 (Laptop), 50W, 1024 cores, accessed on August 11, 2025, [https://forums.developer.nvidia.com/t/number-of-smxs-of-geforce-gtx-1650-laptop-50w-1024-cores/115221](https://forums.developer.nvidia.com/t/number-of-smxs-of-geforce-gtx-1650-laptop-50w-1024-cores/115221)  
27. NvidiaGraphicsDrivers \- Debian Wiki, accessed on August 11, 2025, [https://wiki.debian.org/NvidiaGraphicsDrivers](https://wiki.debian.org/NvidiaGraphicsDrivers)  
28. nouveau · freedesktop.org, accessed on August 11, 2025, [https://nouveau.freedesktop.org/](https://nouveau.freedesktop.org/)  
29. CUDA \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/CUDA](https://en.wikipedia.org/wiki/CUDA)  
30. Lenovo Legion Y540-15IRH-PG0, accessed on August 11, 2025, [https://store.lenovo.com/in/en/lenovo-legion-y540-15irh-pg0-81sy00ucin-375.html](https://store.lenovo.com/in/en/lenovo-legion-y540-15irh-pg0-81sy00ucin-375.html)  
31. potto216/rust-usb-examples: Examples accessing and manipulating USB devies \- GitHub, accessed on August 11, 2025, [https://github.com/potto216/rust-usb-examples](https://github.com/potto216/rust-usb-examples)  
32. Redox-OS.org, accessed on August 11, 2025, [https://www.redox-os.org/](https://www.redox-os.org/)  
33. Building a Rust-based Web Server as a Unikernel with OPS: A Practical Guide \- Zenodo, accessed on August 11, 2025, [https://zenodo.org/records/14593561](https://zenodo.org/records/14593561)  
34. hermit-os/hermit-rs: Hermit for Rust. \- GitHub, accessed on August 11, 2025, [https://github.com/hermit-os/hermit-rs](https://github.com/hermit-os/hermit-rs)  
35. Writing an OS in Rust \- Wesley Aptekar-Cassels, accessed on August 11, 2025, [https://blog.wesleyac.com/posts/writing-an-os-in-rust](https://blog.wesleyac.com/posts/writing-an-os-in-rust)