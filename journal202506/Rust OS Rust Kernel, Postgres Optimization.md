

# **A Symbiotic Architecture: Designing a Rust-Based Microkernel for Native PostgreSQL**

## **Section 1: The Symbiotic Architecture: Tailoring an OS to a Database Workload**

The pursuit of maximum performance in database systems has historically focused on algorithmic improvements, query optimization, and hardware acceleration. However, a significant and often overlooked performance frontier lies at the interface between the database management system and the underlying operating system. General-purpose operating systems, designed to serve a multitude of disparate applications, impose abstractions and scheduling policies that are frequently suboptimal for the highly specific and demanding workload of a high-performance relational database like PostgreSQL. This report outlines a series of architectural blueprints for a specialized, Rust-based microkernel designed from first principles to serve a single purpose: maximizing the performance of a native Rust port of PostgreSQL. The core design philosophy is one of symbiosis, where the OS is not a generic substrate but a tailored, co-designed component of the database system itself. This approach is made feasible and safe by leveraging the unique guarantees of the Rust programming language, drawing inspiration from the "intralingual design" principles demonstrated by advanced research operating systems like Theseus.

### **1.1. Deconstructing the PostgreSQL Performance Profile**

To design an OS optimized for PostgreSQL, one must first deeply understand the database's architectural patterns and the performance bottlenecks they engender when running on a conventional OS. PostgreSQL's design is a masterclass in robust, general-purpose data management, but its performance characteristics are dictated by a few key architectural decisions that create specific, predictable pressures on the underlying system.1

#### **The Process-per-Connection Model**

PostgreSQL employs a classic client-server architecture built upon a "process per-user" model.2 A central coordinating daemon, the

postmaster process, listens for incoming client connections. Upon receiving a connection request and successfully authenticating the client, the postmaster forks a new, independent operating system process.3 This new process, commonly called a "backend," is dedicated exclusively to servicing that single client connection for its entire duration. All queries and transactions from the client are handled within this private backend process.5

This architecture provides exceptional isolation. A crash or critical error in one backend process affects only a single client and does not bring down the entire database server, contributing to PostgreSQL's renowned stability.6 However, this robustness comes at a significant performance cost, particularly in environments with high connection churn or a large number of concurrent connections. The overhead of forking a new process—which involves duplicating the parent's address space (even with copy-on-write optimizations), creating new kernel process structures, and scheduling a new entity—is substantial compared to lighter-weight threading models.7 Furthermore, on a system with hundreds or thousands of active connections, the sheer number of processes creates significant scheduling overhead and memory pressure on the host OS.

This process-based isolation is, in essence, a workaround for the limitations of the generic operating systems PostgreSQL was designed to run on. UNIX-like systems offer the heavyweight process as the primary unit of strong isolation. A purpose-built OS, however, is not bound by this constraint and can offer lighter-weight mechanisms that provide the necessary isolation without the associated performance penalty.

#### **Memory Architecture: The Centrality of shared\_buffers**

PostgreSQL's memory architecture is dominated by a large, globally shared memory region known as shared\_buffers. This area serves as the database's primary disk page cache, holding frequently accessed table and index data in memory to avoid costly disk I/O.8 The effective management of this buffer cache is arguably the single most critical factor in PostgreSQL performance. The

shared\_buffers pool is allocated once at server startup and is shared among the postmaster, all background processes, and all client backend processes.8

Access to the pages within shared\_buffers is a major point of contention. The buffer manager employs a complex locking system to manage concurrent access, ensuring that multiple backends can read the same page simultaneously while preventing race conditions during writes.11 The efficiency of this locking mechanism and the algorithm used to select victim pages for eviction when the buffer is full (a clock-sweep algorithm) are critical to performance.11

In addition to the global shared\_buffers, each backend process allocates private memory for query execution. The most significant of these is work\_mem, which is used for in-memory sorting, hashing (for hash joins and aggregations), and other operations that require temporary data structures.10 If an operation's memory requirement exceeds

work\_mem, it must spill to temporary disk files, causing a dramatic performance degradation.

Finally, the wal\_buffers area is a smaller, shared buffer used to temporarily store transaction log records before they are flushed to the Write-Ahead Log (WAL) on disk.10 This buffering allows transaction commits to be grouped, turning many small, random writes into larger, more efficient sequential writes.

This multi-layered memory model reveals another fundamental tension with general-purpose operating systems. PostgreSQL implements its own page cache (shared\_buffers) because it cannot rely on the OS's generic filesystem cache to make database-aware decisions. The OS does not understand the concept of a transaction or which data pages are more valuable to keep in cache for future queries. This leads to a "double-caching" problem, where data may be present in both PostgreSQL's shared\_buffers and the OS's filesystem cache, wasting memory. A specialized OS can eliminate this redundancy by providing a mechanism for the database to directly manage a single, unified page cache.

#### **The Dichotomy of I/O Patterns**

The I/O workload generated by PostgreSQL is distinctly bimodal, comprising two very different patterns that a high-performance storage subsystem must handle efficiently:

1. **Sequential, Append-Only Writes:** The Write-Ahead Log is the cornerstone of PostgreSQL's durability and crash recovery (ACID properties). Every data modification is first recorded in the WAL. This results in a continuous stream of sequential, append-only writes to the WAL files.4 For write-heavy workloads, the throughput of the device storing the WAL is often the primary performance bottleneck. Separating the WAL onto a dedicated physical device is a standard best practice to avoid contention with other I/O patterns.13  
2. **Random Reads and Writes:** In contrast, accessing the main table and index data (the "heap files") typically involves random I/O patterns.1 A query might need to fetch a few pages from an index followed by a few data pages from the table, which are likely not contiguous on disk. Checkpoints, which periodically flush dirty data from  
   shared\_buffers to the heap files, also generate a significant amount of random write I/O. For read-heavy or analytical workloads, the random read performance (IOPS) of the storage system is paramount.

A general-purpose OS scheduler must balance these competing I/O patterns from all applications on the system. A specialized OS, aware that all I/O originates from the database, can implement a more intelligent I/O scheduling policy. For example, it could grant absolute priority to WAL writes to ensure low commit latency, while aggressively prefetching data for read queries and coalescing random writes during checkpoints to improve throughput.

#### **Key Performance Bottlenecks: The OS Impedance Mismatch**

Synthesizing these observations reveals a core theme: PostgreSQL's design is heavily influenced by the need to work around the generic, one-size-fits-all nature of conventional operating systems. This creates a fundamental "impedance mismatch" where the database expends resources fighting or layering on top of OS policies instead of leveraging them directly. The primary bottlenecks that a custom OS must address are direct consequences of this mismatch:

* **Context Switch Overhead:** The process-per-connection model leads to excessive context switching costs on systems with many concurrent clients.  
* **Shared Buffer Contention:** Locking within the shared buffer manager is a major scalability bottleneck, exacerbated by the OS scheduler's lack of awareness of which backend holds which locks.  
* **Redundant Caching:** The existence of both shared\_buffers and the OS filesystem cache wastes memory and CPU cycles.  
* **Inefficient I/O Scheduling:** Generic I/O schedulers cannot effectively prioritize the distinct and competing I/O patterns of the WAL and the main data files.

A purpose-built OS can resolve this impedance mismatch. It can provide precisely the mechanisms PostgreSQL needs: lightweight, isolated execution contexts instead of heavyweight processes; a direct, controllable, and unified interface to the page cache; and a database-aware I/O scheduler. This insight forms the central justification for designing a symbiotic OS architecture for PostgreSQL.

### **1.2. The Rust Advantage: Intralingual Design for System Software**

The ambition to build a new, specialized operating system is tempered by the immense complexity and historical difficulty of ensuring such systems are safe and correct. Traditional systems languages like C and C++ place the full burden of memory safety on the programmer, leading to entire classes of vulnerabilities (buffer overflows, use-after-free, data races) that have plagued systems software for decades. The Rust programming language offers a transformative alternative, enabling the construction of low-level systems with compile-time safety guarantees.

#### **Safety without Overhead**

The core philosophy underpinning this project is that of "intralingual design," a concept exemplified by the Theseus OS.14 This principle posits that isolation, safety, and security should be the responsibility of the software stack—specifically the language and compiler—rather than relying solely on hardware protection mechanisms like memory management units (MMUs) and privilege levels. Rust's ownership and borrow checking system is the key enabler of this philosophy. It statically verifies, at compile time, that all memory accesses are valid and that there are no data races in concurrent code. This allows for the construction of complex systems with a high degree of confidence in their safety, without incurring the runtime overhead of garbage collection or the architectural overhead of constant privilege-level transitions.

#### **Minimizing unsafe**

Rust provides the unsafe keyword as an escape hatch for operations that the compiler cannot prove are safe. This includes interacting directly with hardware, dereferencing raw pointers, or calling into non-Rust code. The goal in a safe-systems project is not to eliminate unsafe entirely—it is a necessary tool for building an OS—but to minimize its surface area. The strategy is to encapsulate necessary unsafe operations within small, highly-audited modules and expose them to the rest of the system through safe, high-level abstractions. The Theseus codebase provides numerous examples of this pattern, where complex, potentially dangerous operations like memory mapping or task switching are wrapped in safe, ergonomic APIs that uphold the system's invariants.14 This report will adopt this principle, confining

unsafe code to the absolute minimal kernel core and ensuring that the vast majority of the OS and the entire PostgreSQL port can be written in safe Rust.

#### **Fearless Concurrency**

A database is an inherently concurrent system. Rust's type system extends its safety guarantees to concurrency through the Send and Sync marker traits. The Send trait indicates that a type can be safely transferred to another thread, while the Sync trait indicates that a type can be safely shared (via a reference) among multiple threads. The compiler enforces these traits, preventing data races at compile time. This "fearless concurrency" is a powerful asset for building a database OS. It allows for the development of intricate, high-performance concurrent data structures—such as a lock-free buffer manager or a multi-threaded query executor—with the compiler acting as a vigilant partner, guaranteeing the absence of entire classes of common and pernicious concurrency bugs.

## **Section 2: Lessons from a Precursor: Relevant Abstractions in Theseus OS**

The Theseus OS, while an academic project with a different architectural goal (a single address space OS), serves as an invaluable source of battle-tested, safe abstractions for low-level systems programming in Rust. Its codebase demonstrates how to build core OS components—memory managers, schedulers, IPC mechanisms—while adhering to the principle of minimizing unsafe code. This section analyzes specific patterns from Theseus that are directly applicable to the design of a high-performance, PostgreSQL-optimized microkernel.

### **2.1. The MappedPages Paradigm: A Foundation for Safe Memory Management**

The cornerstone of Theseus's memory management subsystem is the MappedPages abstraction, a powerful demonstration of how to leverage Rust's RAII (Resource Acquisition Is Initialization) pattern to ensure memory safety.14 A

MappedPages object is a guard type that represents exclusive ownership over a contiguous range of virtual memory pages that are currently mapped to physical frames.

The safety of this paradigm stems from its lifecycle. The MappedPages object is created when memory is allocated and mapped. Access to the underlying memory is only possible through safe methods on this object. Crucially, when the MappedPages object goes out of scope, its Drop implementation is automatically invoked, which unmaps the pages and deallocates the underlying virtual and physical memory.14 This direct link between the object's lifetime and the validity of the memory mapping makes use-after-free errors a compile-time impossibility. The reference to the memory cannot outlive the

MappedPages object that guarantees its validity.

The memory crate in Theseus encapsulates the necessary unsafe operations for interacting with page tables and the MMU within a suite of safe, high-level APIs on the MappedPages object 14:

* as\_slice\<T\>() and as\_slice\_mut\<T\>(): These methods provide safe, bounds-checked access to the memory region as a slice of a given type T. The mutable version additionally verifies that the pages have write permissions.  
* as\_type\<T\>() and as\_type\_mut\<T\>(): These methods reinterpret the memory region as a single instance of a type T, performing alignment and size checks. The returned reference is lifetime-bound to the MappedPages object.  
* remap(): This method allows for safely changing the permission flags (e.g., from writable to read-only) of the memory region.

This pattern is directly translatable to the management of PostgreSQL's shared\_buffers in our custom microkernel. A central BufferManager server could own the entire physical memory region for the buffer pool. When a backend process needs to access a database page, it would request a "pin" on that page from the BufferManager. Instead of returning a raw pointer, the BufferManager would perform the necessary mapping into the backend's address space and return a MappedPages object representing that single page. The backend could then safely access the page's contents. When the backend is finished, it simply lets the MappedPages object go out of scope. Its Drop implementation would automatically communicate with the BufferManager to unmap the page and release the pin. This approach provides a robust, unsafe-free interface for one of the most critical and complex parts of database operation.

### **2.2. Safe Concurrency: Lightweight Tasks and Channels**

Theseus eschews the heavyweight process model of traditional OSes in favor of extremely lightweight tasks, managed by the task and spawn crates.14 This model provides a blueprint for replacing PostgreSQL's expensive process-per-connection model.

The TaskBuilder in the spawn crate is a prime example of leveraging Rust's type system for safety. When creating a new task, the developer must provide an entry function and an argument. The builder is generic over the types of the function (F), argument (A), and return value (R), and it enforces strict trait bounds: F: FnOnce, A: Send, R: Send, and all three must have a 'static lifetime.14 These compile-time constraints guarantee that a task cannot be created with a function that might be called incorrectly, or with data that cannot be safely transferred to the new task's context, eliminating a wide range of potential memory safety violations.

The TaskRef type, a reference-counted Arc\<Task\>, provides a safe, shared handle for managing and interacting with tasks.14 This abstraction can be directly adopted to represent PostgreSQL backends. A

TaskRef for each backend would be far more memory-efficient and faster to create and destroy than a full OS process.

This leads to a more nuanced understanding of the execution model. In a traditional OS, the process is a monolithic unit of both identity and execution. The process ID represents both the connection's persistent state (transaction status, temporary tables, session variables) and the currently executing query. Theseus's model allows for the separation of these concerns. A Task is simply a data structure holding state; the execution context is just one field within it.

This separation inspires a two-tiered task model for our PostgreSQL OS. We can introduce a PostgresBackend task that represents the persistent identity and state of a client connection. This task would live for the duration of the connection but would spend most of its time blocked, waiting for a new query. When a query arrives, the PostgresBackend task would not execute it directly. Instead, it would parse the query, generate an execution plan, and then spawn one or more ephemeral, even more lightweight "worker tasks" to execute the plan. These worker tasks would exist only for the duration of the query.

This model offers profound performance advantages. The overhead of creating and destroying the ephemeral worker tasks would be minimal. It allows for query-level parallelism to be naturally expressed and managed by the OS scheduler. A complex query involving multiple joins could be broken down into several worker tasks running in parallel. The OS scheduler, being database-aware, could even prioritize worker tasks based on the query's importance or the transaction's state. This represents a significant leap in sophistication over the coarse-grained process-per-connection model.

Furthermore, Theseus's synchronization primitives, such as the channels in the rendezvous and sync\_channel crates, demonstrate how to build complex, blocking communication mechanisms in safe Rust.14 These patterns, which use

WaitQueues and IrqSafeMutexes to manage task blocking and state transitions without race conditions, can be directly applied to implement the Inter-Process Communication (IPC) needed in a microkernel architecture.

### **2.3. Modularity and Dynamic Loading (mod\_mgmt)**

While our primary goal is to build a microkernel, not a single address space OS, the principles of modularity and dynamic state management from Theseus's mod\_mgmt crate are highly relevant.14 Theseus is structured as a collection of "cells," where each cell is a Rust crate compiled to a single, relocatable object file. The

mod\_mgmt component is a runtime loader and linker that can load, link, and manage these cells within isolated CrateNamespaces.

This model provides a powerful blueprint for the structure of a microkernel-based system. The core OS services—the filesystem server, the network stack, the PostgreSQL BufferManager, device drivers—can each be implemented as a separate, self-contained Rust crate (a cell). The microkernel itself would contain a mod\_mgmt-like loader responsible for starting these servers at boot time.

The key advantage of this approach is maintainability and live evolution. Because dependencies are tracked at a fine-grained, per-section level, it becomes possible to update individual system components at runtime without rebooting.14 A bug fix in the network stack could be deployed by having the kernel load the new

network\_stack crate, transfer state from the old instance, and then safely unload the old one. This provides the modularity and resilience benefits that are the primary motivation for microkernel architectures, but implemented using the safe, verifiable structure of Rust crates instead of ad-hoc process boundaries.15

## **Section 3: Architectural Blueprints for a Postgres-Optimized Microkernel**

Building upon the workload analysis of PostgreSQL and the safe implementation patterns from Theseus, this section presents three distinct architectural blueprints for a specialized microkernel. Each design represents a different point in the trade-off space between performance, safety, complexity, and control, offering a unique approach to achieving the goal of a symbiotic database operating system.

### **3.1. Architecture A: The Hyper-Cooperative Microkernel**

This architecture is a modern interpretation of the classic high-performance microkernel, heavily inspired by the design principles of the L4 family, particularly its relentless focus on minimizing IPC overhead.18 The philosophy is to make the kernel as small and fast as possible, providing a minimal set of powerful primitives. All traditional OS services, and indeed the PostgreSQL engine itself, are implemented as a cooperative ecosystem of isolated user-space server processes that communicate via a hyper-efficient, synchronous IPC mechanism.19

#### **Kernel Primitives (The unsafe Core)**

The kernel's API would be exceptionally small, consisting of only a handful of system calls. The implementation of this core would be the primary locus of unsafe code in the system, requiring rigorous auditing and verification.

* **ipc\_call(target\_endpoint: Capability, msg\_regs: \&mut \[u64\], timeout: Duration) \-\> Result**: This is the cornerstone of the system. It is a synchronous, combined send and receive operation. A client task invokes ipc\_call to send a message to a server and simultaneously block, waiting for a reply. The server receives the message by calling ipc\_call with a wildcard target\_endpoint. When a message arrives, the server processes it and calls ipc\_call again to reply to the client and wait for the next message. Inspired by L4, this call would pass small messages directly in CPU registers to avoid memory-copying overhead.18 The  
  target\_endpoint is a capability, a non-forgeable handle managed by the kernel that grants the right to communicate with a specific server endpoint, forming the basis of the system's security.21  
* **map\_memory(source\_task: Capability, source\_vaddr: VirtAddr, dest\_task: Capability, dest\_vaddr: VirtAddr, num\_pages: usize, perms: PagePerms) \-\> Result**: This system call allows one task to map a range of its own pages into another task's address space. This is the primary mechanism for bulk data transfer and is essential for achieving zero-copy communication.23 For example, the buffer manager can map a database page directly into a backend's address space without any intermediate copying.  
* **register\_interrupt(irq: u8, target\_endpoint: Capability) \-\> Result**: This call binds a hardware interrupt to an IPC endpoint. When the specified IRQ fires, the kernel does not run a complex handler. Instead, it synthesizes a small IPC message and sends it to the registered target\_endpoint, effectively converting hardware events into asynchronous messages that can be handled by a user-space driver server.24  
* **create\_task(parent\_cspace: Capability, parent\_vspace: Capability) \-\> (Capability, Capability)**: Creates a new task (thread of execution) and address space, returning capabilities for managing them.

#### **Server Ecosystem**

The system's functionality is realized by a collection of user-space servers, each running as an isolated task:

* **PostgreSQL Backends**: Each client connection is handled by a dedicated backend task, analogous to a traditional backend process. These tasks are lightweight, consisting of an address space and a single thread.  
* **BufferManager Server**: A critical, central server that owns and manages the physical memory corresponding to PostgreSQL's shared\_buffers. It exposes an IPC-based API for backends to pin, unpin, and request dirty\_flush for database pages.  
* **WALWriter Server**: A high-priority, dedicated server responsible for receiving WAL records via IPC from backends, buffering them, and writing them sequentially to disk. Its high priority ensures low transaction commit latency.  
* **DiskDriver Server**: A user-space driver that handles all block I/O. It receives requests (e.g., read\_block, write\_block) via IPC and interacts with the hardware by mapping device registers and receiving interrupts as IPC messages.  
* **NetworkStack Server**: A user-space TCP/IP stack that handles client connections and forwards query packets to the appropriate backend task.

#### **High-Performance Workflow: A SELECT Query**

To illustrate the data flow, consider the lifecycle of a simple SELECT query that requires a disk read:

1. A TCP packet arrives. The hardware raises an interrupt. The kernel intercepts it, creates an IPC message, and sends it to the NetworkStack server.  
2. The NetworkStack server processes the packet, identifies it as a query for a specific connection, and performs an ipc\_call to the corresponding PostgreSQL backend task, passing the query string in registers.  
3. The backend task wakes up, parses the query, and consults its query plan. It determines it needs to read page P from table T.  
4. The backend performs an ipc\_call to the BufferManager server with a pin\_page(T, P) request.  
5. The BufferManager checks its internal hash table. The page is not in the cache. It allocates a free buffer slot, sends a read\_block(block\_addr) request via ipc\_call to the DiskDriver server, and blocks the original backend's request by not replying yet.  
6. The DiskDriver server programs the disk controller to read the block into a pre-arranged memory buffer.  
7. The disk controller completes the read and raises an interrupt. The kernel translates this into an IPC message and sends it to the DiskDriver.  
8. The DiskDriver wakes up, identifies the completed request, and sends a reply IPC to the BufferManager.  
9. The BufferManager wakes up, marks the buffer slot as valid, and uses the map\_memory system call to map the physical frame containing the data page into the backend task's address space.  
10. Finally, the BufferManager sends a reply IPC to the waiting backend task. The message contains a capability granting access to the newly mapped page.  
11. The backend task unblocks, accesses the data directly from the mapped page (a zero-copy read), processes it, and sends the result back to the client via the NetworkStack.

This architecture achieves high performance by minimizing kernel complexity and optimizing the critical IPC path. However, its performance is ultimately limited by the number of IPC hops required for any given operation.

### **3.2. Architecture B: The LibOS-Exokernel Hybrid**

This architecture takes a more radical approach to minimizing kernel abstraction, drawing inspiration from the Exokernel research.25 The core tenet of the exokernel is to separate protection from management. The kernel's only job is to provide secure, protected multiplexing of the physical hardware. All traditional OS abstractions—virtual memory, filesystems, scheduling policies—are implemented in user space within a

**Library OS (LibOS)** that is linked directly into each application.28 This grants the application maximum control over resource management, enabling domain-specific optimizations impossible in other architectures.

#### **Kernel Primitives (The Minimalist Protector)**

The exokernel's system call interface is even more spartan than the microkernel's. It does not offer abstractions like "IPC" or "tasks" in the traditional sense. Instead, it exposes primitives that correspond closely to hardware capabilities.

* **alloc\_phys\_frame() \-\> FrameCapability**: Securely allocates an unused physical memory frame and returns a capability representing ownership.  
* **map\_page\_to\_frame(vaddr: VirtAddr, frame: FrameCapability, perms: PagePerms) \-\> Result**: Maps a virtual page in the current address space to a physical frame for which the task holds a capability. This gives the LibOS direct control over its own page tables.  
* **submit\_io\_command(queue: IoQueueCapability, command\_ptr: PhysAddr) \-\> Result**: Submits a command block (e.g., an NVMe submission queue entry) directly to a hardware I/O queue. The task must hold a capability for that specific queue.  
* **register\_exception\_handler(handler\_pc: VirtAddr, handler\_sp: VirtAddr)**: Registers a user-space entry point to handle exceptions, including page faults and interrupts.  
* **yield\_timeslice(next\_task: TaskCapability)**: Voluntarily yields the CPU to another task.

#### **The PostgreSQL LibOS**

Each PostgreSQL backend would be linked against a highly specialized PostgreSQL LibOS. This library would replace the standard C library and provide all necessary OS services by directly using the exokernel's primitives.

* **Custom Scheduler**: A cooperative, event-driven scheduler optimized for query processing. It would manage a set of "fibers" or lightweight threads within the backend's address space.  
* **Custom Page Fault Handler**: The LibOS would register its own page fault handler. This handler would be responsible for managing the backend's virtual memory, bringing in pages from disk as needed.  
* **Direct Device Drivers**: The LibOS would contain minimal drivers for the network card and disk controller. It would craft the raw hardware command structures (e.g., NVMe SQs, network ring buffer descriptors) in its own memory and use submit\_io\_command to enqueue them for execution.  
* **Shared Memory Coordinator**: Since each backend is in its own isolated address space, a central Coordinator process is needed to manage the shared\_buffers. This Coordinator would allocate a large contiguous region of physical memory at boot. When a backend needs to access a shared page, it would communicate with the Coordinator over a simple shared-memory ring buffer. The Coordinator would then use a special kernel mechanism to grant the backend a temporary FrameCapability for the requested physical frame, which the backend's LibOS could then map into its own address space.

#### **High-Performance Workflow: A SELECT Query**

The workflow in this model is dramatically different, with the kernel being almost entirely absent from the hot path.

1. The network card DMAs an incoming packet into a memory ring buffer owned by a backend's LibOS. An interrupt fires.  
2. The kernel, seeing the interrupt is bound to the backend, transfers control directly to the LibOS's registered interrupt handler.  
3. The LibOS's network driver processes the packet and wakes up the appropriate fiber to handle the query.  
4. The query planner determines it needs page P. It consults a shared-memory index (managed by the Coordinator) to find the physical frame address, F, for page P.  
5. The LibOS checks a local data structure to see if it already has a mapping for frame F. Let's assume it doesn't.  
6. The LibOS sends a message to the Coordinator via the shared-memory ring buffer requesting access to frame F.  
7. The Coordinator validates the request and uses a kernel call to delegate the FrameCapability for F to the backend task.  
8. The backend's LibOS receives the capability and uses the map\_page\_to\_frame system call to map F into its own address space at an available virtual address.  
9. If the page was not in memory, the LibOS would have crafted an NVMe read command, used submit\_io\_command to send it to the disk, and put the fiber to sleep. The disk completion interrupt would wake the fiber, which would then proceed with the mapping.  
10. The query execution fiber now has direct, raw memory access to the page and can complete its work.

This architecture offers unparalleled performance by minimizing kernel mediation. However, it comes at the cost of immense complexity. The development of a stable, secure, and feature-complete LibOS is a task of similar magnitude to developing a traditional OS kernel.

### **3.3. Architecture C: The Intralingual Monolith (A Contrarian Approach)**

This final architecture presents a contrarian view, directly challenging the premise that a microkernel is the optimal design for a dedicated database appliance. It argues that if the entire system, including the application, is written in a safe language like Rust, then hardware-enforced isolation (via separate address spaces) becomes a redundant and costly overhead. This design proposes a return to a monolithic structure, but one where safety and isolation are provided by the Rust compiler—an "intralingual monolith." This model is a direct application of the core principles of Theseus OS.14

#### **Architecture**

* **Single Address Space, Single Privilege Level**: There is no distinction between "kernel space" and "user space." All code—the low-level OS primitives, device drivers, the PostgreSQL query executor, the buffer manager—runs in a single, shared virtual address space at the highest hardware privilege level (e.g., Ring 0 on x86-64).  
* **Componentization via Crates**: The system is not a single, undifferentiated binary. Instead, it is composed of a collection of distinct Rust crates, each with a well-defined responsibility and public API. The PostgreSQL engine itself would be decomposed into crates like pg\_parser, pg\_executor, pg\_buffer\_manager, and pg\_wal\_writer.  
* **Dynamic Loading and Linking**: At boot time, a minimal core OS component, similar to Theseus's captain and mod\_mgmt crates, loads and dynamically links these component crates together.14 This preserves the modularity and maintainability of a microkernel design, allowing individual components to be developed, tested, and even updated independently.  
* **Isolation via Rust's Module System**: The primary isolation boundary is not the MMU, but the Rust compiler's visibility and privacy rules. The pg\_buffer\_manager crate, for example, would contain a struct BufferPool with its internal data structures (hash tables, free lists, etc.) being private to the module. It would only expose a safe public API, such as pub fn get\_page(\&self, tag: BufferTag) \-\> PageGuard. Other components, like pg\_executor, can only interact with the buffer pool through this safe, public interface. The compiler statically guarantees that the executor cannot, for example, directly access the buffer pool's internal free list and corrupt its state.

#### **Safety and Performance**

This model fundamentally redefines the relationship between safety and performance.

* **Performance**: This architecture achieves the absolute minimum communication overhead possible. When the query executor needs a page from the buffer manager, it is not an IPC or a system call; it is a direct, statically-linked function call. The cost is measured in nanoseconds—the time it takes to execute a few machine instructions to jump to a new function and return. There are no context switches, no address space switches, and no kernel crossings for inter-component communication because there is no kernel boundary to cross.  
* **Safety and unsafe Surface Area**: The safety of the entire system hinges on the guarantees of the Rust compiler. The vast majority of the code, including all of the complex database logic, can and must be written in 100% safe Rust. The unsafe keyword is only permitted in the lowest-level crates that interact directly with hardware, such as the disk driver's MMIO access or the context-switching code. This unsafe surface area is extremely small and can be subjected to intense scrutiny and formal verification, while the bulk of the system is proven safe by the compiler.

#### **Workflow: A SELECT Query**

The workflow in this model is refreshingly simple, mirroring that of a well-structured monolithic application.

1. The network\_driver crate receives a packet and places it in a shared buffer. It then calls a function in the connection\_manager crate.  
2. The connection\_manager identifies the connection and calls a function in the pg\_executor crate, passing a reference to the query.  
3. The pg\_executor parses and plans the query. To fetch a page, it calls pg\_buffer\_manager.get\_page(page\_id).  
4. The pg\_buffer\_manager function executes. It checks its hash map. If the page is not present, it calls disk\_driver.read\_block(block\_addr, target\_buffer).  
5. The disk\_driver function issues the command to the hardware and blocks the current task (cooperative scheduling).  
6. The disk interrupt handler, upon completion, wakes the blocked task.  
7. Control returns up the call stack, with each component passing data via safe references.

This model trades hardware-enforced isolation for language-enforced isolation, reaping a massive performance benefit in the process. It is the purest expression of the symbiotic OS concept, where the line between OS and application blurs into a single, cohesive, and safe system.

## **Section 4: Comparative Analysis and Recommendations**

The three proposed architectures—the Hyper-Cooperative Microkernel, the LibOS-Exokernel Hybrid, and the Intralingual Monolith—represent fundamentally different philosophies for constructing a specialized database operating system. The optimal choice depends on a careful analysis of their trade-offs with respect to the primary goals: maximizing PostgreSQL performance and minimizing the use of unsafe Rust.

### **4.1. Architectural Trade-offs Analysis**

#### **Performance**

The performance of each architecture is primarily dictated by the overhead of its fundamental communication and resource management primitives.

* **Architecture C (Intralingual Monolith)** offers the highest theoretical performance for inter-component communication. The cost of interaction between the query executor and the buffer manager is reduced to a simple function call, an operation that is orders of magnitude faster than even the most optimized IPC mechanism. By eliminating the kernel/user boundary and context switches for database operations, this model removes the single greatest source of overhead present in traditional systems. Its performance is limited only by the efficiency of the compiled Rust code and the underlying hardware.  
* **Architecture B (LibOS-Exokernel Hybrid)** provides the highest potential I/O throughput. By giving the PostgreSQL LibOS direct, unmediated control over the network and disk hardware, it eliminates kernel-level processing, buffering, and scheduling from the I/O path. This is ideal for bulk data operations and analytical workloads. However, communication between backends for managing shared resources (like the buffer pool) still requires some form of IPC, likely via a shared memory ring buffer, which introduces more overhead than a direct function call.  
* **Architecture A (Hyper-Cooperative Microkernel)** represents a compromise. Its performance is excellent compared to a general-purpose OS, thanks to a highly optimized, L4-style IPC mechanism. However, every interaction between servers—from the network stack to the backend, from the backend to the buffer manager, from the buffer manager to the disk driver—requires a full round-trip through the kernel's IPC path. While each hop is fast, the cumulative latency of multiple hops for a single query can become significant, making it inherently slower for communication-intensive tasks than the monolithic approach.

#### **Safety and unsafe Surface Area**

The safety of each system is a function of how much code must be written in unsafe Rust and how well that code is encapsulated.

* **Architecture C (Intralingual Monolith)** has the smallest and most contained unsafe surface area. unsafe code is strictly confined to the lowest-level hardware drivers (e.g., for accessing MMIO registers) and the context-switching mechanism. The entire PostgreSQL engine and all higher-level OS services can be written in 100% safe Rust, with the compiler guaranteeing their memory and thread safety.  
* **Architecture B (LibOS-Exokernel Hybrid)** has a slightly larger unsafe surface. The exokernel itself is minimal and can be rigorously audited. However, the LibOS must also contain unsafe code to interact with the raw hardware primitives exposed by the kernel (e.g., crafting NVMe command blocks, programming network card descriptors). While this unsafe code is still contained within the LibOS, it is more distributed than in the monolithic model.  
* **Architecture A (Hyper-Cooperative Microkernel)** has the largest unsafe surface of the three. The microkernel itself is larger than an exokernel, as it implements not just protection but also IPC and scheduling abstractions. The system call interface, the IPC stubs, and all device drivers contain necessary unsafe blocks. While still far safer than a traditional C-based kernel, it requires more unsafe code to be written and trusted.

#### **Development Complexity**

Complexity is a critical factor in the feasibility and long-term maintainability of the system.

* **Architecture B (LibOS-Exokernel Hybrid)** is by far the most complex. It effectively requires the development of a complete, custom operating system (the LibOS) from scratch, including schedulers, memory managers, and device drivers. This is a monumental engineering effort.  
* **Architecture A (Hyper-Cooperative Microkernel)** is moderately complex. While the kernel itself is small, designing a robust, efficient, and deadlock-free ecosystem of cooperating user-space servers is a significant systems design challenge.  
* **Architecture C (Intralingual Monolith)** is the simplest from a systems perspective. The development model closely resembles that of a large, modular application. The primary challenge is not in systems-level primitives but in disciplined software architecture—ensuring that the component crates have clean, well-defined APIs and do not devolve into a tangled "big ball of mud." The modularity patterns from Theseus provide a clear path to managing this complexity.

### **4.2. Key Table: Architectural Feature Comparison**

The following table provides a concise summary of the critical trade-offs between the three proposed architectures. This allows for a direct comparison of their fundamental design choices and resulting characteristics.

| Feature | Architecture A (Hyper-Cooperative Microkernel) | Architecture B (LibOS-Exokernel Hybrid) | Architecture C (Intralingual Monolith) |
| :---- | :---- | :---- | :---- |
| **Isolation Model** | Hardware (MMU-enforced Address Spaces) | Hardware (MMU-enforced Address Spaces) | Language (Rust Type System & Module Boundaries) |
| **Primary Communication** | Synchronous, Zero-Copy IPC | Shared Memory & Direct Hardware Access | Safe, Direct Function Calls |
| **Communication Overhead** | Low (Optimized IPC, but multiple hops) | Very Low (Minimal kernel mediation) | Near-Zero (Cost of a function call) |
| **Control over Resources** | Indirect (Via server requests) | Maximum (Direct management in LibOS) | High (Direct access within shared address space) |
| **unsafe Code Surface** | Small (Kernel IPC, drivers, memory mapping) | Minimal (Exokernel primitives, LibOS hardware interface) | Smallest (Confined to low-level drivers) |
| **Development Complexity** | High (Server ecosystem design) | Very High (LibOS development is complex) | Moderate (Requires disciplined software architecture) |
| **Best For...** | High-security, multi-tenant database systems | Single-purpose, maximum I/O throughput appliance | Single-purpose, lowest-latency OLTP appliance |

### **4.3. Final Recommendations**

Given the user's stated goals of **maximizing PostgreSQL performance** while simultaneously **minimizing unsafe Rust code**, the most promising path forward is the **Intralingual Monolith (Architecture C)**.

This recommendation is based on the following justifications:

1. **Unmatched Performance:** For a workload like OLTP (Online Transaction Processing), which is characterized by a high volume of small, latency-sensitive queries, communication overhead is the dominant performance factor. Architecture C fundamentally eliminates this overhead by replacing expensive IPC or system calls with simple function calls. It directly addresses the primary bottlenecks identified in the PostgreSQL workload analysis—context switching and inter-process communication—in the most efficient way possible.  
2. **Superior Safety Profile:** This architecture aligns most perfectly with the core strengths of Rust. It leverages the compiler's safety guarantees to their fullest extent, providing strong, static guarantees of isolation between components. This allows it to achieve the smallest possible unsafe surface area, confining trusted code to a minimal set of hardware drivers that can be rigorously audited. It is, paradoxically, the safest way to build a monolithic system.  
3. **Reduced Complexity:** While requiring disciplined software engineering, the overall system architecture is significantly less complex than building and coordinating a distributed system of microkernel servers or developing an entire OS within a library. The development workflow is more familiar, and the lessons from Theseus on managing a modular, crate-based system provide a clear and proven implementation path.

It is critical to note that this recommendation is contingent on the system being a dedicated database appliance. The entire premise of the intralingual monolith rests on the ability to trust all code running in the single address space, a trust that is established by the Rust compiler. If the requirements were to change to include multi-tenancy with support for arbitrary, potentially untrusted application code, the hardware-enforced isolation of the Hyper-Cooperative Microkernel (Architecture A) would be the superior and necessary choice for security. However, for the specific problem of creating the highest-performance, safest possible environment for a single, known application like PostgreSQL, the overhead of hardware isolation is a performance penalty that can be safely and effectively engineered away with Rust.

#### **Works cited**

1. PostgreSQL Performance Tuning and Optimization Guide \- Sematext, accessed on July 21, 2025, [https://sematext.com/blog/postgresql-performance-tuning/](https://sematext.com/blog/postgresql-performance-tuning/)  
2. www.postgresql.org, accessed on July 21, 2025, [https://www.postgresql.org/docs/7.3/arch-pg.html\#:\~:text=In%20database%20jargon%2C%20PostgreSQL%20uses,%2C%20the%20psql%20program)%2C%20and](https://www.postgresql.org/docs/7.3/arch-pg.html#:~:text=In%20database%20jargon%2C%20PostgreSQL%20uses,%2C%20the%20psql%20program\)%2C%20and)  
3. Understanding PostgreSQL architecture and attributes \- Prisma, accessed on July 21, 2025, [https://www.prisma.io/dataguide/postgresql/getting-to-know-postgresql](https://www.prisma.io/dataguide/postgresql/getting-to-know-postgresql)  
4. Understanding the Fundamentals of PostgreSQL® Architecture \- Instaclustr, accessed on July 21, 2025, [https://www.instaclustr.com/blog/postgresql-architecture/](https://www.instaclustr.com/blog/postgresql-architecture/)  
5. PostgreSQL Architecture Explained | Yugabyte, accessed on July 21, 2025, [https://www.yugabyte.com/postgresql/postgresql-architecture/](https://www.yugabyte.com/postgresql/postgresql-architecture/)  
6. PostgreSQL \- System Architecture \- GeeksforGeeks, accessed on July 21, 2025, [https://www.geeksforgeeks.org/postgresql/postgresql-system-architecture/](https://www.geeksforgeeks.org/postgresql/postgresql-system-architecture/)  
7. PostgreSQL Performance Tuning: Key Parameters \- TigerData, accessed on July 21, 2025, [https://www.tigerdata.com/learn/postgresql-performance-tuning-key-parameters](https://www.tigerdata.com/learn/postgresql-performance-tuning-key-parameters)  
8. Aiven for PostgreSQL® shared buffers, accessed on July 21, 2025, [https://aiven.io/docs/products/postgresql/concepts/pg-shared-buffers](https://aiven.io/docs/products/postgresql/concepts/pg-shared-buffers)  
9. Determining the optimal value for shared\_buffers using the pg\_buffercache extension in PostgreSQL | AWS Database Blog, accessed on July 21, 2025, [https://aws.amazon.com/blogs/database/determining-the-optimal-value-for-shared\_buffers-using-the-pg\_buffercache-extension-in-postgresql/](https://aws.amazon.com/blogs/database/determining-the-optimal-value-for-shared_buffers-using-the-pg_buffercache-extension-in-postgresql/)  
10. Understanding the importance of shared\_buffers, work\_mem, and wal\_buffers in PostgreSQL \- Fujitsu Enterprise Postgres, accessed on July 21, 2025, [https://www.postgresql.fastware.com/pzone/2024-06-understanding-shared-buffers-work-mem-and-wal-buffers-in-postgresql](https://www.postgresql.fastware.com/pzone/2024-06-understanding-shared-buffers-work-mem-and-wal-buffers-in-postgresql)  
11. 30 years of PostgreSQL buffer manager locking design evolution | by Dichen Li | Medium, accessed on July 21, 2025, [https://medium.com/@dichenldc/30-years-of-postgresql-buffer-manager-locking-design-evolution-e6e861d7072f](https://medium.com/@dichenldc/30-years-of-postgresql-buffer-manager-locking-design-evolution-e6e861d7072f)  
12. Understanding the PostgreSQL Architecture | Severalnines, accessed on July 21, 2025, [https://severalnines.com/blog/understanding-postgresql-architecture/](https://severalnines.com/blog/understanding-postgresql-architecture/)  
13. PostgreSQL Performance Tuning: Optimize Your Database Server \- EDB, accessed on July 21, 2025, [https://www.enterprisedb.com/postgres-tutorials/introduction-postgresql-performance-tuning-and-optimization](https://www.enterprisedb.com/postgres-tutorials/introduction-postgresql-performance-tuning-and-optimization)  
14. Theseus-20250721174526.txt  
15. Microkernels Explained \- Blue Goat Cyber, accessed on July 21, 2025, [https://bluegoatcyber.com/blog/microkernels-explained/](https://bluegoatcyber.com/blog/microkernels-explained/)  
16. Microkernel Architecture, Principles, Benefits & Challenges \- Aalpha Information Systems, accessed on July 21, 2025, [https://www.aalpha.net/blog/microkernel-architecture/](https://www.aalpha.net/blog/microkernel-architecture/)  
17. Microkernel Architecture Pattern \- System Design \- GeeksforGeeks, accessed on July 21, 2025, [https://www.geeksforgeeks.org/system-design/microkernel-architecture-pattern-system-design/](https://www.geeksforgeeks.org/system-design/microkernel-architecture-pattern-system-design/)  
18. L4 microkernel family \- Wikipedia, accessed on July 21, 2025, [https://en.wikipedia.org/wiki/L4\_microkernel\_family](https://en.wikipedia.org/wiki/L4_microkernel_family)  
19. Microkernel \- Wikipedia, accessed on July 21, 2025, [https://en.wikipedia.org/wiki/Microkernel](https://en.wikipedia.org/wiki/Microkernel)  
20. performance | microkerneldude, accessed on July 21, 2025, [https://microkerneldude.org/tag/performance/](https://microkerneldude.org/tag/performance/)  
21. Wayless: a Capability-Based Microkernel \- PDXScholar, accessed on July 21, 2025, [https://pdxscholar.library.pdx.edu/cgi/viewcontent.cgi?article=1867\&context=honorstheses](https://pdxscholar.library.pdx.edu/cgi/viewcontent.cgi?article=1867&context=honorstheses)  
22. Frequently Asked Questions | seL4, accessed on July 21, 2025, [https://sel4.systems/About/FAQ.html](https://sel4.systems/About/FAQ.html)  
23. Zero-copy \- Wikipedia, accessed on July 21, 2025, [https://en.wikipedia.org/wiki/Zero-copy](https://en.wikipedia.org/wiki/Zero-copy)  
24. COMP9242 Advanced Operating Systems S2/2011 Week 9: Microkernel Design \- UNSW, accessed on July 21, 2025, [http://www.cse.unsw.edu.au/\~cs9242/11/lectures/09-ukinternals.pdf](http://www.cse.unsw.edu.au/~cs9242/11/lectures/09-ukinternals.pdf)  
25. Exokernel: An Operating System Architecture for ... \- Papers, accessed on July 21, 2025, [https://mwhittaker.github.io/papers/html/engler1995exokernel.html](https://mwhittaker.github.io/papers/html/engler1995exokernel.html)  
26. Application Performance and Flexibility on Exokernel Systems, accessed on July 21, 2025, [https://users.ece.cmu.edu/\~ganger/papers/exo-sosp97/exo-sosp97.pdf](https://users.ece.cmu.edu/~ganger/papers/exo-sosp97/exo-sosp97.pdf)  
27. CS 261 Notes on Exokernel, accessed on July 21, 2025, [https://www.read.seas.harvard.edu/\~kohler/class/cs261-f11/exokernel.html](https://www.read.seas.harvard.edu/~kohler/class/cs261-f11/exokernel.html)  
28. Exokernel: An Operating System Architecture for \- ResearchGate, accessed on July 21, 2025, [https://www.researchgate.net/publication/2560567\_Exokernel\_An\_Operating\_System\_Architecture\_for](https://www.researchgate.net/publication/2560567_Exokernel_An_Operating_System_Architecture_for)  
29. Exokernel – Engler, Kaashoek etc.… “Mechanism is policy” Outline: Overview – 20 min Specific abstractions, accessed on July 21, 2025, [https://www.cs.utexas.edu/\~dahlin/Classes/GradOS/lectures/exokernel.pdf](https://www.cs.utexas.edu/~dahlin/Classes/GradOS/lectures/exokernel.pdf)