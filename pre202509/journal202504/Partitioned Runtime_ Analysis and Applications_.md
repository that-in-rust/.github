

# **Architectures of Separation: A Definitive Report on Partitioned Runtimes**

### **Executive Summary**

This report provides a comprehensive analysis of the "partitioned runtime" paradigm, a foundational concept in modern computing. It establishes that this term describes two distinct but related design philosophies: **partitioning for parallelism** to enhance performance in data-intensive systems, and **partitioning for isolation** to ensure safety, security, and determinism in complex and critical systems.

The analysis traces the evolution of partitioning from its theoretical computer science roots to its practical implementation in diverse domains, including large-scale data warehouses (Snowflake, BigQuery), distributed computing frameworks (Spark, ONNX Runtime), and safety-critical embedded systems (avionics, automotive, medical).

We deconstruct the core architectural principles, including **spatial partitioning** (memory and resource isolation) and **temporal partitioning** (guaranteed CPU time allocation). The report details the enabling technologies, with a particular focus on the role of **hypervisors** and the evolution of the **separation kernel** as a high-assurance, minimalist foundation for certifiable systems.

A key finding is that the move toward partitioned architectures is an economic and engineering imperative, driven by the need to consolidate functions onto shared hardware (Integrated Modular Avionics) without sacrificing the inherent fault containment of older, federated systems.

The report concludes with a critical examination of the profound benefits—fault isolation, enhanced security, real-time performance, and the enablement of mixed-criticality—and the significant challenges, including implementation complexity, performance overhead, and the severe threat of network partitioning failures in distributed environments.

---

## **Part I: Foundational Principles of Partitioning**

This part establishes the fundamental concepts of partitioning, distinguishing between the two primary motivations—parallelism and isolation—and detailing the core strategies used in each domain.

### **Chapter 1: The Partitioning Paradigm: Data, Computation, and Resources**

#### **1.1 Defining Partitioning: From Abstract Problem to Practical Solution**

At its most fundamental level, the concept of partitioning in computer science is rooted in the **Partition Problem**, a task in number theory that asks whether a given multiset of positive integers can be divided into two subsets whose elements sum to the same value.1 This problem is classified as NP-complete, meaning that no known algorithm can solve it for all inputs in polynomial time. The inherent computational difficulty of achieving a "perfect" partition, where work or data is distributed with perfect balance, is a crucial theoretical underpinning for why practical partitioning in real-world systems is so complex. Because finding an ideal solution is intractable for large-scale problems, system designers do not attempt to solve the pure partition problem. Instead, they rely on a variety of

**heuristics** and specialized algorithms—such as greedy algorithms, dynamic programming, and approximation schemes—to find solutions that are either optimal for specific constraints or acceptably close to optimal.1

In practice, this theoretical challenge translates into a pragmatic engineering principle: partitioning is the act of dividing a larger entity—be it a dataset, a computational workload, or a set of system resources—into smaller, more manageable, and often independent units.2 This strategy of "divide and conquer" has become a cornerstone of modern computing, representing the primary method for tackling the immense challenges of scale, complexity, and performance in systems ranging from multi-core processors to globally distributed cloud services.5 The "partitioned runtime," therefore, is the environment in which these divided workloads execute, an environment fundamentally shaped by the goals and mechanisms of the chosen partitioning strategy.

#### **1.2 The Two Primary Modalities of Partitioning**

The term "partitioned runtime" is not monolithic; its meaning and implementation differ profoundly based on the primary objective. The concept has followed two distinct evolutionary paths, leading to two primary modalities that, while sharing a common principle, address fundamentally different problems. Understanding this dichotomy is the most critical step in grasping the subject.

##### **1.2.1 Partitioning for Parallelism (Data-Centric)**

This modality is driven by the need for performance, throughput, and scalability, particularly in the realms of big data analytics and distributed computing.7 The core goal is to take a large computational problem, such as a complex data analytical query, and break it down into numerous smaller tasks that can be executed concurrently on different processing units, whether they are multiple cores on a single node or multiple nodes in a distributed cluster.7 In these systems, an analytical query is decomposed into fundamental operations like table scans, joins, and aggregations. To execute these operations in parallel, the underlying data must be partitioned and often repartitioned

*at runtime* to be redistributed among parallel workers.7 This dynamic partitioning is essential for making large-scale data processing feasible within acceptable timeframes. For example, a query that would take hours on a single machine can be completed in minutes by distributing the work across hundreds of partitioned data segments.9

##### **1.2.2 Partitioning for Isolation (System-Centric)**

This modality is driven by the need for safety, security, and fault containment. It is the dominant paradigm in safety-critical embedded systems, such as those found in avionics, automotive, industrial control, and medical devices.10 The primary objective is to create strongly encapsulated execution environments, or "partitions," that are strictly separated from one another in both

**space** (memory and I/O resources) and **time** (CPU allocation).12 This separation ensures that a fault, whether accidental (a bug) or malicious (a cyberattack), in a low-assurance partition (e.g., an in-vehicle infotainment system) cannot propagate to affect the operation of a high-assurance, safety-critical partition (e.g., the braking control system).14 Unlike the dynamic partitioning for parallelism, this form of partitioning is typically configured statically at system build-time or boot-time to create a predictable, verifiable, and deterministic runtime environment.6

The ambiguity of the term "partitioned runtime" arises directly from these two divergent use cases. In the data-centric world, the runtime is an engine that *performs partitioning* on a workload. In the system-centric world, the runtime itself *is partitioned* to create isolated sandboxes for multiple workloads. The remainder of this report will analyze these two modalities, their underlying strategies, their benefits, and their challenges in detail.

#### **1.3 Data Partitioning Strategies: A Deep Dive**

To achieve parallelism and query efficiency in data-intensive systems, several well-established strategies are employed to divide large datasets. The choice of strategy is critical and depends heavily on the structure of the data and the expected query patterns.

* **Horizontal Partitioning (Sharding):** This is the most common strategy for scaling out databases. Data is divided by rows into multiple, smaller tables or data stores, known as shards.4 All shards share the same schema, but each holds a distinct subset of the data, for example, based on a customer ID range or geographic region.16 The value used to determine which shard a row belongs to is called the "shard key." A well-chosen shard key distributes data and query load evenly, while a poor choice can lead to "hotspots" where one shard is overwhelmed.4  
* **Vertical Partitioning:** In this approach, data is divided by columns. Tables are split into smaller tables that contain fewer columns.4 This is particularly useful for separating frequently accessed, "hot" data from infrequently accessed, "cold" data. For instance, a product's name and price, which are read often, might be placed in one partition, while its detailed description and high-resolution images are placed in another. This optimizes I/O performance and allows for more effective caching of the frequently used data.4  
* **Functional Partitioning:** This strategy segregates data according to its business context or the function it serves within an application. For example, an e-commerce system might store all data related to invoices in one partition, product inventory in another, and customer information in a third.4 This aligns the data architecture with the application's bounded contexts, improving isolation and reducing data access contention between different parts of the system.  
* **Hash Partitioning:** This is a fundamental technique used to distribute data evenly across a fixed number of partitions. A hash function is applied to a partitioning key (e.g., a user ID or order number), and the resulting hash value determines which partition the data is assigned to.7 Its primary goal is to co-locate matching records from different tables on the same node. This is extremely valuable for distributed join operations; if two large tables are hashed on their join key, the join can be performed as a series of independent, local joins on each partition, avoiding massive and costly network data shuffles.7  
* **Range Partitioning:** This method divides data based on a continuous range of values in a specific column, such as a date, a timestamp, or an integer ID.16 For example, a sales data table might be partitioned by month. This is highly effective for queries that filter on the partitioning key, as the query optimizer can perform "partition pruning"—skipping all partitions that do not fall within the query's specified range.19 This can lead to dramatic performance improvements. However, range partitioning is susceptible to data skew; for instance, if data is partitioned by date, the current day's partition may receive all new writes, creating a hotspot. To mitigate this, systems often use sampling techniques to analyze the data distribution and determine more optimal range boundaries.7  
* **Radix Partitioning:** This is a highly efficient, though less common, algorithm that partitions data based on the binary representation of the partitioning keys.7 It operates by focusing on specific bit positions within the key. A typical implementation involves two passes over the data: the first pass creates a histogram to count how many records will fall into each partition based on their bit patterns, and the second pass uses this histogram to place each record into its correct output location.7 The use of fast bitwise operations makes this method very performant and cache-efficient, though the two-pass nature can introduce overhead.7

#### **1.4 System Resource Partitioning: Spatial and Temporal Separation**

In the context of partitioning for isolation, the focus shifts from data to the fundamental resources of the computer: memory and CPU time. The goal is to create virtual containers that prevent interference between software components.

* **Spatial Partitioning:** This is the principle of memory and resource isolation. It ensures that a software component running in one partition cannot read, write, or execute code in the memory space of another partition.11 This extends beyond main memory to include control over I/O devices, ensuring one partition cannot interfere with an external device assigned to another.13 Spatial partitioning is the bedrock of system security and fault containment. It prevents a bug or malicious code in one component from corrupting the state of the entire system, effectively creating firewalls in software that are enforced by hardware.22  
* **Temporal Partitioning:** This is the principle of CPU time isolation. It guarantees that each partition receives a specified budget of processor time and ensures that one component cannot monopolize the CPU, thereby starving other components and causing them to miss their deadlines.11 This is achieved through specialized scheduling mechanisms. Temporal partitioning is absolutely essential for providing the predictability and determinism required in hard real-time systems, where missing a deadline can have catastrophic consequences.22

These two forms of partitioning—spatial and temporal—are the pillars upon which safe, secure, and reliable integrated systems are built. They allow developers to consolidate multiple applications with different levels of trust and criticality onto a single physical computer, while maintaining the strong isolation that was once only achievable through physically separate hardware.

---

## **Part II: Partitioned Runtimes in System Software and Architecture**

This part explores the implementation of partitioning for isolation, focusing on the operating systems that enforce it, the hardware that enables it, and the controlled communication required between isolated components.

### **Chapter 2: The Partitioning Operating System: Enforcing Isolation and Determinism**

A partitioning operating system is a specialized OS designed to establish and manage multiple encapsulated execution environments on a single computer. Its primary purpose is to provide fault containment equivalent to an idealized system where each application runs on its own dedicated processor with its own peripherals.11 This is achieved by implementing robust mechanisms for both spatial and temporal partitioning, which are not merely software constructs but are fundamentally dependent on underlying hardware support for enforcement.

#### **2.1 Architectural Principles: The Role of Hardware Support**

The guarantees provided by a partitioning OS are only as strong as the hardware mechanisms they leverage to enforce isolation boundaries. Software alone cannot prevent a determined or buggy process from interfering with another; it requires the non-bypassable authority of the processor's hardware protection features.

* **Memory Management Unit (MMU):** In more sophisticated systems, the MMU is the primary tool for enforcing spatial partitioning. The MMU translates virtual addresses used by a process into physical addresses in RAM. By giving each partition its own separate virtual address space, the OS ensures that a process in one partition cannot even formulate an address that points to the memory of another partition. Any attempt to access an unmapped or protected address results in a hardware fault, which traps to the OS for handling.11 This provides a powerful and granular form of memory protection.  
* **Memory Protection Unit (MPU):** In the resource-constrained world of embedded systems and microcontrollers, a full MMU may be absent. In its place, many processors offer a Memory Protection Unit (MPU).25 An MPU does not perform address translation but instead allows the OS to define a small number of memory regions and assign specific access permissions (e.g., read-only, no-execute) to each region for the currently running task.26 While less flexible than an MMU, an MPU is a critical enabler for creating secure "compartments" on low-power devices, providing a sufficient level of spatial partitioning to protect critical firmware from less-trusted application code.25

The partitioning OS is responsible for configuring these hardware units at system startup and during context switches to maintain the integrity of each partition's execution space. By doing so, it ensures that a memory fault (e.g., buffer overflow) or a timing failure (e.g., a task exceeding its worst-case execution time) within one partition remains contained and does not propagate to disrupt or corrupt others.11

#### **2.2 Temporal Partitioning in Practice: Scheduling Regimes**

The guarantee of CPU time, or temporal partitioning, is the responsibility of the OS scheduler. Unlike general-purpose schedulers that aim for fairness or overall throughput, schedulers in partitioning OSs for critical systems prioritize predictability and guaranteed resource allocation.

* **Fixed Partition Schedulers:** A common and straightforward approach is to use a fixed partition scheduler. Here, the system designer pre-allocates a static budget of CPU time to each partition, often as a percentage.6 For example, Partition A might be guaranteed 30% of the CPU, while Partition B gets 70%. This approach is highly effective at preventing process starvation and denial-of-service attacks, as a runaway or malicious process in one partition can consume no more than its allocated budget, leaving the resources for other partitions untouched.6 This static allocation provides strong determinism.  
* **Drawbacks of Fixed Scheduling:** The primary weakness of fixed scheduling is its inherent inefficiency. If Partition A only uses 10% of its 30% budget during a given cycle, the remaining 20% of CPU time is typically wasted. It cannot be reallocated to Partition B, even if Partition B is under heavy load and could benefit from the extra cycles.6 This can lead to significantly lower overall CPU utilization, sometimes as low as 70%, forcing system designers to use more powerful and expensive processors than would otherwise be necessary or to limit system functionality.6  
* **Adaptive Partitioning:** More advanced systems, such as the one implemented in the QNX RTOS, employ adaptive partitioning to overcome the inefficiency of fixed schedulers.12 In an adaptive scheme, partitions still have a guaranteed minimum budget of resources. However, any unused CPU time from one partition can be dynamically redistributed to other partitions that require additional resources. This allows the system to behave like a strict, hard real-time scheduler when under full load, but to operate more efficiently and responsively to peak demands when the system is not fully loaded, making it better suited for dynamic environments.12  
* **Cyclic Scheduling:** In many safety-critical systems, particularly those adhering to standards like ARINC 653, a deterministic cyclic scheduling approach is used. The schedule is defined by a "Major Time Frame" (MTF), which is a repeating, fixed-duration cycle. Within the MTF, each partition is given one or more dedicated "partition windows" (or time slots) in which to execute.21 This entire schedule is defined in a static configuration table and can be mathematically analyzed and verified offline to prove that all timing constraints will be met. This provides the highest level of determinism required for the most critical applications.27

#### **2.3 Case Studies in Industry Standards: IMA, ARINC 653, and AUTOSAR**

The principles of partitioning have been codified into major industry standards, reflecting a maturation of embedded systems engineering from bespoke solutions to disciplined, architecture-centric design.

* **Integrated Modular Avionics (IMA):** This is the architectural concept in modern aviation that drove the need for partitioning standards. The traditional "federated" architecture used physically separate computer systems for each avionics function (e.g., autopilot, flight management).10 This provided natural and robust fault containment. IMA challenges this model by consolidating multiple functions onto a single, shared, fault-tolerant computing platform to reduce size, weight, and cost.10 This consolidation, however, erases the natural fault containment boundaries, creating the risk that a fault in one function could corrupt the entire shared system. Partitioning is the essential technology that restores strong fault containment to the IMA architecture.10  
* **ARINC 653:** This is the key software standard that defines how to build partitioned systems for IMA. It specifies a standard interface between the application software and the OS, known as the **APplication EXecutive (APEX)**.28 ARINC 653 mandates both spatial and temporal partitioning and formalizes the two-level hierarchical scheduling model: a static, table-driven, round-robin schedule for the partitions themselves, and a preemptive, priority-based scheduling policy for the processes running  
  *within* each partition's allocated time window.28 Commercial RTOSs like PikeOS and LynxOS provide ARINC 653-compliant "personalities" to meet the requirements of the avionics industry.13  
* **AUTOSAR (Automotive Open System Architecture):** This is the corresponding standard in the automotive industry. As cars become "computers on wheels," with hundreds of software components from different suppliers, the need for isolation is paramount. AUTOSAR defines the concept of a **Software (SW) Partition** as a mechanism for logical and resource isolation (both memory and CPU time) on an Electronic Control Unit (ECU).32 This partitioning is crucial for integrating components of different safety levels (e.g., infotainment vs. advanced driver-assistance systems) and for demonstrating compliance with safety standards like ISO 26262\.13

The emergence of these standards signals a critical shift. They enable **composability**—the ability to develop, test, and certify individual software components in isolation, with a high degree of confidence that they can be integrated without unintended interference. This moves the industry away from a risky "integrate and pray" model to a disciplined, verifiable, and more reliable approach to building complex systems.

#### **2.4 Resource Allocation Strategies: Fixed vs. Dynamic**

Beyond CPU scheduling, the allocation of main memory is another critical function of a partitioning OS. The strategies for memory allocation mirror the trade-offs seen in scheduling.

* **Fixed (Static) Partitioning:** In this model, the main memory is divided into a number of fixed-size partitions at system boot time.3 When a process arrives, it is allocated a partition large enough to hold it. This approach is simple to implement but is highly susceptible to  
  **internal fragmentation**. If a 3MB process is loaded into a 4MB partition, the 1MB of leftover space within that partition is wasted and cannot be used by any other process.3  
* **Dynamic (Variable) Partitioning:** To combat internal fragmentation, dynamic partitioning creates partitions at runtime that are sized exactly to the needs of the incoming process.34 This eliminates internal fragmentation and allows for more flexible and efficient use of memory. However, it introduces two major complexities. First, the implementation is more difficult.34 Second, it suffers from  
  **external fragmentation**. As processes are loaded and unloaded, the free memory can become divided into numerous small, non-contiguous holes. A situation can arise where there is enough total free memory to satisfy a new process's request, but no single hole is large enough, leading to allocation failure.34  
* **Placement Algorithms:** In a dynamic partitioning scheme, when multiple free blocks (holes) are available that could satisfy a request, the OS must use a placement algorithm to decide which one to allocate. Common algorithms include:  
  * **First-Fit:** Scans memory from the beginning and allocates the first hole that is large enough. It is fast but can lead to fragmentation at the beginning of memory.3  
  * **Best-Fit:** Scans the entire list of free holes and allocates the smallest hole that is large enough. This minimizes the size of the leftover hole but can be slower due to the exhaustive search and may leave behind tiny, unusable fragments.3  
  * **Worst-Fit:** Scans the entire list and allocates the largest available hole. The idea is that the leftover hole will be large enough to be useful, but this strategy often leads to poor performance and rapid fragmentation.3  
  * **Next-Fit:** Similar to First-Fit, but it begins its search from the location of the last allocation rather than from the beginning of memory. This can improve performance but may lead to poorer overall memory utilization.3

Each of these algorithms presents a different trade-off between allocation speed and memory utilization efficiency, and the choice depends on the specific requirements of the system.

### **Chapter 3: The Bedrock of Trust: Hypervisors and Separation Kernels**

While the operating system provides the logic for partitioning, the enforcement of that logic at the lowest level is often delegated to a specialized software layer that sits directly on the hardware: the hypervisor. In the realm of high-assurance systems, this concept has evolved into the separation kernel, a technology that represents the pinnacle of isolation and trust.

#### **3.1 Virtualization as an Enabler for Partitioning**

Virtualization is a technology that abstracts hardware resources, allowing a single physical machine to host multiple, isolated guest environments known as Virtual Machines (VMs).35 Each VM runs its own complete operating system and applications, making it a natural and powerful mechanism for implementing spatial partitioning.37 The software layer that creates and manages these VMs is the

**hypervisor**, also known as a Virtual Machine Monitor (VMM).38

In the context of partitioned runtimes, the hypervisor acts as the foundational layer of isolation. It carves up the physical hardware (CPU, memory, I/O devices) and allocates subsets of these resources to different partitions.14 This enables the creation of complex, consolidated systems where, for example, a general-purpose OS like Linux or Android can run in one partition, while a safety-critical real-time operating system (RTOS) runs in another, all on the same multi-core processor.22 The hypervisor is the ultimate arbiter, enforcing the boundaries between these disparate worlds.

#### **3.2 The Separation Kernel: A Minimalist, High-Assurance Evolution**

The separation kernel is a highly specialized type of **bare-metal (Type 1\) hypervisor** that is designed with a single, overriding purpose: to provide robust, verifiable separation and information flow control.40 The concept, first articulated by John Rushby in his seminal 1981 paper, was born from the realization that security and separation are too critical to be entrusted to a large, complex operating system. The core philosophy is to create a kernel that is so small, simple, and focused on its one task that it can be rigorously analyzed and even formally verified to be correct—a level of assurance impossible for a general-purpose OS.40

Key characteristics that distinguish a separation kernel from a general-purpose hypervisor are its extreme minimalism and dedication to its core function. A true separation kernel contains **no device drivers, no file system, no network stack, no user model, no shell access, and no dynamic memory allocation**.40 All of these complex, ancillary services are pushed up into the guest VMs (the partitions) that run on top of the kernel. This radical reduction of functionality results in an exceptionally small codebase (as little as 15kB) and, consequently, a minimal attack surface, which greatly simplifies security and safety analysis.40

#### **3.3 Architectural Characteristics of Separation Kernels**

The unique philosophy of the separation kernel manifests in several key architectural characteristics that set it apart.

* **Hardware-Enforced Separation:** Separation kernels are designed to leverage modern hardware virtualization extensions (such as Intel VT-x and EPT, or ARM's virtualization extensions at EL2) to their fullest extent.40 They use these hardware features to create and enforce the boundaries of the partitions, managing memory access rights and peripheral allocation directly in hardware. This makes the isolation non-bypassable and tamper-proof from the perspective of the software running within the partitions.40  
* **Strict Information Flow Control:** A core design goal is to create a runtime environment that is functionally indistinguishable from one composed of physically separate, air-gapped machines connected by dedicated communication lines.40 The kernel's primary function is to enforce a strict policy that information can only flow between partitions along known, explicitly configured, and mediated communication channels.41 All other potential channels for information flow, including side channels, are intended to be eliminated by the design.  
* **Static Configuration:** Unlike dynamic cloud environments where VMs are created and destroyed on demand, partitions in a separation kernel-based system are typically defined **statically** at system design or boot time.42 Resources such as CPU cores, memory regions, and I/O devices are permanently allocated to specific partitions. For enhanced security, the very code responsible for configuring these partitions may be purged from memory after the system has booted, preventing any runtime modification of the isolation policy.40 This static nature is fundamental to the kernel's verifiability and its ability to provide deterministic, predictable behavior.

#### **3.4 Role in Building Certifiable, Mixed-Criticality Systems**

The architectural properties of the separation kernel make it the ideal foundation for building **Mixed-Criticality Systems (MCS)**. These are systems where applications with vastly different levels of criticality—for example, a safety-critical flight control function certified to the highest standard (DO-178C DAL A) and a non-critical passenger entertainment system—must coexist and execute concurrently on the same hardware platform.14

The provable, hardware-enforced isolation provided by the separation kernel is what makes this consolidation possible without compromising safety. It guarantees that no failure or malicious action in a low-criticality partition can impact a high-criticality one.45 This isolation has profound implications for the certification process, which is often the most expensive and time-consuming part of developing safety-critical systems.

By using a certified separation kernel, developers can partition the system and certify each component to its own required level of assurance.46 A change to the non-critical infotainment system, for instance, does not necessitate a full re-certification of the flight control system, as their independence is guaranteed by the underlying kernel.14 This modular approach to certification dramatically reduces cost, risk, and time-to-market. Leading commercial RTOSs for safety-critical markets, such as

**SYSGO's PikeOS** and **Green Hills Software's INTEGRITY**, are built upon this proven separation kernel architecture.14

It is crucial to recognize that the separation kernel is not merely a "minimal hypervisor." It represents a fundamentally different design philosophy. While a general-purpose hypervisor prioritizes flexibility, dynamic resource management, and efficient server consolidation, a separation kernel prioritizes provable security, static isolation, and real-time determinism above all else. It co-opts the hardware of virtualization not for efficiency, but for assurance. This distinction clarifies its unique and vital role in the landscape of partitioned runtimes.

### **Chapter 4: Inter-Partition Communication (IPC): The Controlled Dialogue**

Once a system has been divided into strongly isolated partitions, the next critical challenge is to enable them to communicate and coordinate their actions in a controlled and secure manner. In a partitioned system, Inter-Partition Communication (IPC) is not merely a feature; it is a carefully designed and policed aspect of the architecture, as any communication channel is a potential vector for interference or attack. The design of the IPC mechanism is therefore as crucial to the system's overall integrity as the isolation mechanism itself.

#### **4.1 Mechanisms for Communication**

While the mechanisms for IPC are often familiar from general-purpose operating systems, their implementation in a partitioned environment is subject to strict control.

* **Shared Memory:** This is often the most performant method for IPC. A specific region of physical memory is mapped into the address space of two or more partitions, allowing them to exchange data at memory speed.47 However, this approach requires careful management. Without proper synchronization mechanisms like locks or semaphores, it is highly prone to race conditions and data corruption. In a partitioned system, access to shared memory must be explicitly granted and configured by the underlying OS or hypervisor.48  
* **Message Passing / Queues:** A more structured and inherently safer approach is message passing. Partitions communicate by sending discrete messages to one another, typically via a message queue or mailbox managed by the kernel.47 The kernel is responsible for copying the message from the sender's address space to the receiver's, which introduces some overhead but provides a clean, decoupled interface. This is a common pattern in distributed systems and microservice architectures, valued for its explicitness and ability to manage communication flow.50  
* **Remote Procedure Calls (RPCs):** RPCs provide a higher level of abstraction, making communication between partitions appear as a simple, local function call.50 The RPC framework handles the underlying details of marshalling arguments, sending the data via a lower-level mechanism (like message passing), and returning the result, hiding the complexity of the distributed environment from the application developer.8

#### **4.2 The Hypervisor as Mediator**

In a high-assurance partitioned system, direct, unmediated communication between partitions is strictly forbidden. Every interaction must pass through the trusted kernel or hypervisor, which acts as a security guard, enforcing the system's information flow policy.14

This mediation is fundamental to maintaining isolation. The hypervisor is responsible for setting up and tearing down communication channels and ensuring that data flows only between partitions that are explicitly authorized to communicate.52 For instance, the PikeOS hypervisor is designed to intercept privileged system calls from guest operating systems, first checking them against the partition's configured permissions before allowing them to be executed.14

Patented designs illustrate specific implementations of this principle. One such method involves each partition allocating an **Inter Partition Communication Area (IPCA)** from within its own private memory.52 The partition registers the location of its IPCA with the hypervisor. The hypervisor then treats the collection of all these non-contiguous IPCAs as a single

**Virtual Shared Resource (VSR)**. It controls all access to the VSR, ensuring that a partition can only write to or read from the IPCA of a target partition, and that no other part of any partition's private memory is ever exposed.52

A similar concept is found in Microsoft's Hyper-V architecture, which uses a **Synthetic Interrupt Controller (SynIC)**. Partitions communicate by posting messages into pre-defined slots on a shared memory page. When a message is posted, the hypervisor generates a synthetic interrupt to notify the destination partition of the message's arrival, prompting it to read the shared page.54 In all these cases, the hypervisor is the central, trusted mediator of all communication.

#### **4.3 Performance vs. Security in Communication**

The choice of an IPC mechanism involves an inescapable trade-off between performance and security. The fastest methods, like raw shared memory, offer the weakest isolation and are the most difficult to secure and verify. Conversely, the most secure methods, which involve deep mediation by the hypervisor with data copying and context switching, inevitably introduce performance overhead.55

The criticality of this trade-off in high-assurance systems has led to the development of specialized communication architectures. The **Partitioning Communication System (PCS)**, for example, is a security architecture that extends the principles of Multiple Independent Levels of Security (MILS) to the network layer.57 Its goal is to provide communication services that are non-bypassable, evaluatable, and tamper-proof, sharing the responsibility for security between the underlying separation kernel and the application layer itself.57 The existence of such frameworks underscores the fact that in a partitioned system, IPC cannot be an afterthought. It must be co-designed with the partitioning and isolation strategy, as it represents a deliberate and necessary breach in the very walls the system is designed to erect. The choice of mechanism is not merely a technical detail but a fundamental security architecture decision.

---

## **Part III: A Comparative Analysis of Modern Computing Paradigms**

To fully appreciate the role and significance of partitioned runtimes, it is essential to situate them within the broader landscape of computing. This part provides a comparative analysis, contrasting partitioned systems with alternative kernel designs and other mainstream isolation technologies to highlight their unique characteristics, strengths, and weaknesses.

### **Chapter 5: Kernel Philosophies: Partitioning vs. Monolithic and Microkernel Designs**

The kernel is the core of any operating system, and its design philosophy dictates the fundamental structure, performance, and reliability of the entire system. Partitioned systems, particularly those built on separation kernels, represent a specific point on a spectrum of kernel architectures.

#### **5.1 The Kernel Spectrum**

* **Monolithic Kernels:** This is the classic and most widespread kernel design, exemplified by systems like Linux and traditional Unix.56 In a monolithic architecture, all core OS services—including the scheduler, memory management, file systems, network stacks, and device drivers—are tightly integrated and run in a single, privileged address space known as kernel space.55 The primary advantage of this design is performance; communication between components is as fast as a direct function call within the same address space.56 However, this tight integration is also its greatest weakness. A bug in any single component, such as a third-party device driver, can corrupt the entire kernel and lead to a system crash, making monolithic kernels inherently less secure and more difficult to maintain.58  
* **Microkernels:** In response to the fragility of monolithic designs, the microkernel philosophy aims for modularity and resilience. In a microkernel architecture, only the most essential functions—such as basic process management, inter-process communication (IPC), and low-level memory handling—reside in the privileged kernel space.55 All other OS services, including device drivers, file systems, and network stacks, are implemented as separate, unprivileged user-space processes called "servers".56 These servers communicate with each other and with applications via IPC mediated by the minimal kernel. This design offers superior reliability, as the failure of a user-space server (e.g., a network driver) can often be handled by simply restarting that server, without affecting the rest of the system.55 The primary drawback is performance overhead, as the IPC required for communication between servers involves context switches and data copying, which is significantly slower than a direct function call in a monolithic kernel.55  
* **Hybrid Kernels:** Systems like Windows and macOS are often described as hybrid kernels. They represent a pragmatic compromise between the two extremes.58 They move more services into kernel space than a pure microkernel to gain performance benefits, but they retain a more modular, message-passing structure internally than a traditional monolithic kernel.58 This approach seeks to balance the speed of monolithic design with the modularity of a microkernel.  
* **Modular Kernels:** This term typically refers to modern monolithic kernels, like Linux, that have been enhanced with the ability to dynamically load and unload "modules" (such as device drivers) at runtime.59 This adds a significant degree of flexibility, as the kernel does not need to be recompiled to add support for new hardware. However, it is crucial to understand that these loaded modules still execute within the kernel's single, privileged address space. Therefore, while it improves flexibility, it does not solve the fundamental reliability and security problem of monolithic designs; a faulty module can still crash the entire system.58

#### **5.2 Situating Partitioned OSs and Separation Kernels**

Within this spectrum, partitioning-focused systems occupy a distinct and specialized niche.

* A **Partitioning Operating System** is best understood as an architectural pattern rather than a specific kernel type. Its defining characteristic is its explicit and primary support for enforcing spatial and temporal partitioning.11 This architecture can be implemented on top of different kernel bases. For example, a system could use a modified monolithic kernel with a specialized scheduler and MMU/MPU management to create partitions.  
* A **Separation Kernel**, however, is the purest practical implementation of the microkernel philosophy, refined and optimized for the single purpose of high-assurance separation.40 It takes the microkernel's minimalism to its logical extreme, stripping out every function not absolutely essential for creating and maintaining isolated partitions.

A key philosophical distinction is the **separation of mechanism and policy**.58 Monolithic kernels tend to bundle both the mechanisms (e.g., how memory is protected) and the policies (e.g., which processes get which memory) together. Microkernels, and especially separation kernels, aim to provide only the fundamental

*mechanisms* for isolation and communication. The *policies* governing how those mechanisms are used are then implemented by the applications and services running in the user-space partitions. This separation provides greater flexibility and allows the system to be tailored to very specific security and safety requirements.58

#### **Table 1: Comparative Analysis of Kernel Architectures**

| Feature | Monolithic Kernel | Modular Kernel | Microkernel | Separation Kernel |
| :---- | :---- | :---- | :---- | :---- |
| **Architecture** | All OS services are integrated into a single, large kernel running in a privileged address space.55 | A monolithic kernel that can dynamically load and unload modules (e.g., drivers) at runtime.59 | Only essential services run in the kernel; most OS functions are user-space servers.58 | An extreme microkernel designed exclusively for creating isolated partitions and controlling information flow.40 |
| **Core Philosophy** | Performance and simplicity of design through tight integration. | Flexibility and extensibility for a monolithic design. | Modularity, reliability, and security through service isolation. | Provable security and safety through minimalist design and formal verification. |
| **Services in Kernel Space** | Scheduler, memory management, IPC, file systems, network stack, device drivers.58 | Same as monolithic, but with drivers and other services loadable as modules.59 | Minimal IPC, basic scheduling, basic memory management.55 | Only the mechanisms for spatial/temporal partitioning and mediated IPC. No drivers, file systems, or network stacks.40 |
| **Key Advantage** | High performance due to low-overhead communication (direct function calls).56 | Adds flexibility to the monolithic model without a major performance penalty. | High reliability and security; failure of a user-space server is typically not catastrophic.55 | Highest level of security and safety assurance; enables certifiable mixed-criticality systems.14 |
| **Key Disadvantage** | Low reliability and security; a bug in any component can crash the entire system.56 | Does not solve the core reliability issue of monolithic kernels, as modules run in kernel space. | Performance overhead due to frequent IPC and context switching between user-space servers.56 | Highly specialized; not suitable for general-purpose computing. Performance depends on the efficiency of the IPC mechanism. |
| **Example Systems** | Traditional Unix, MS-DOS | Linux, FreeBSD | QNX, L4, Minix 3 | PikeOS, INTEGRITY-178, LynxSecure.22 |

### **Chapter 6: Isolation Technologies: Partitioned Runtimes, VMs, and Containers**

Beyond kernel design, the modern computing landscape offers several distinct technologies for achieving application isolation. Understanding the trade-offs between Virtual Machines, containers, and the high-assurance partitioned runtimes provided by separation kernels is critical for any system architect.

#### **6.1 Virtualizing the Hardware: Virtual Machines (VMs)**

Virtual Machines are the heavyweight champions of isolation. A VM is a complete emulation of a physical computer, from the hardware layers (CPU, disk, networking) upwards.35 This emulation is managed by a hypervisor.

* **Isolation Boundary:** The hypervisor creates a strong, hardware-enforced boundary between each VM and between the VMs and the host system. Each VM runs its own full, independent guest operating system.36  
* **Security:** This architecture provides excellent security isolation. A compromise or crash within one VM is contained and cannot affect other VMs on the same physical host, as they do not share an OS.35  
* **Overhead:** The primary drawback of VMs is their high resource overhead. Because each VM includes a complete OS, they are large in size (often measured in gigabytes), consume significant memory, and are slow to boot (often taking minutes).38 This makes them less agile for dynamic, rapidly scaling applications.

#### **6.2 Virtualizing the OS: Containers**

Containers represent a more lightweight approach to virtualization. Instead of virtualizing the hardware, containers virtualize the operating system itself.

* **Isolation Boundary:** Multiple containers run on a single host OS, sharing the host's kernel. The isolation is at the process level, enforced by kernel features like **namespaces** (which give each container its own view of the filesystem, network, and process tree) and **cgroups** (which limit a container's access to resources like CPU and memory).36  
* **Security:** Container isolation is generally considered weaker than VM isolation. Since all containers share the same host kernel, a vulnerability in the kernel itself could potentially be exploited to allow an attacker to "escape" the container and compromise the host and all other containers.35  
* **Overhead:** The key advantage of containers is their extremely low overhead. They do not bundle a guest OS, making them very small (measured in megabytes) and incredibly fast to start (typically in seconds).38 This efficiency and speed make them the ideal technology for microservice architectures and scalable, cloud-native applications where agility and density are paramount.36

#### **6.3 Partitioned Runtimes: A Third Way for High-Assurance Systems**

Partitioned runtimes, especially those built upon a **separation kernel**, offer a unique set of trade-offs that position them as a "third way" for systems where neither general-purpose VMs nor containers are a perfect fit.

* **Isolation Boundary:** Like a VM, a partition in a separation kernel-based system is isolated by a bare-metal hypervisor (the separation kernel). This provides strong, hardware-enforced isolation between partitions.40  
* **Security:** The security guarantees are very high, arguably higher than a standard VM, because the trusted computing base (the separation kernel itself) is vastly smaller and more rigorously designed and verified than a general-purpose hypervisor.40  
* **Overhead:** The overhead is significantly lower than that of a full VM. Because the separation kernel is minimal and the partitions are not required to run a full general-purpose OS (they can run a small RTOS or even bare-metal code), the resource consumption is much lower. This allows for near bare-metal performance within the partitions.37  
* **Key Differentiator:** The defining characteristics that set this approach apart are **determinism and certifiability**. Unlike VMs and containers, which are designed for enterprise IT and web-scale applications, separation kernel-based runtimes are specifically engineered to provide the hard real-time performance and verifiable safety and security properties required for certification to the most stringent industry standards.14

#### **Table 2: Isolation Technology Trade-offs: VMs vs. Containers vs. Partitioned Runtimes**

| Feature | Virtual Machine (VM) | Container | Partitioned Runtime (Separation Kernel) |
| :---- | :---- | :---- | :---- |
| **Virtualization Layer** | Hardware | Operating System | Hardware (via minimal hypervisor) |
| **Isolation Boundary** | Hypervisor | Host OS Kernel | Separation Kernel |
| **Resource Overhead** | High (each VM has a full OS) 38 | Low (shares host OS kernel) 38 | Low-to-Moderate (minimal kernel, can run lightweight guest) 40 |
| **Size** | Large (Gigabytes) 38 | Small (Megabytes) 38 | Minimal kernel, guest size varies |
| **Startup Time** | Slow (Minutes) 36 | Fast (Seconds) 36 | Fast (approaching bare-metal boot) |
| **Security Guarantees** | Strong; full isolation between VMs.35 | Weaker; kernel exploits can lead to container escapes.35 | Strongest; formally verifiable isolation, minimal attack surface.40 |
| **Real-Time Determinism** | No; not designed for hard real-time guarantees. | No; not designed for hard real-time guarantees. | Yes; primary design goal for hard real-time systems.22 |
| **Ideal Use Case** | Running multiple OSs, legacy applications, full environment isolation.36 | Microservices, cloud-native applications, rapid scaling, CI/CD pipelines.36 | Safety-critical and security-critical embedded systems (avionics, automotive, medical), mixed-criticality consolidation.14 |

---

## **Part IV: System-Wide Implications: Benefits and Challenges**

Having established the foundational principles and architectural underpinnings of partitioned runtimes, this part synthesizes their strategic impact. It examines the profound benefits that drive their adoption as well as the significant challenges and risks that must be managed in their implementation.

### **Chapter 7: The Dividends of Division: Fault Isolation, Security, and Performance**

The decision to architect a system around partitions is driven by a compelling set of benefits that address some of the most difficult problems in modern computing: reliability, security, and performance.

#### **7.1 Fault Containment and Availability**

The most fundamental benefit of partitioning for isolation is **fault containment**. In a monolithic system, a fault in one component can easily cascade, leading to a total system failure. A partitioned architecture erects firewalls between components, ensuring that a fault is contained within the partition where it occurs.10 This principle was an inherent by-product of the older "federated" avionics architectures, where each function ran on its own dedicated hardware. The move to Integrated Modular Avionics (IMA) made partitioning a mandatory software technique to restore this critical property to consolidated systems.10

This robust fault isolation directly translates to higher **system availability**. In a large-scale distributed data system, if a server hosting one shard fails, only the data in that partition becomes unavailable; operations on all other partitions can continue uninterrupted.4 Similarly, in a safety-critical system like a car, a crash in the non-critical infotainment partition will not affect the operation of the engine control or braking systems, allowing the vehicle to continue operating safely.22 This ability to isolate failures and maintain the functionality of the wider system is a primary driver for adopting partitioned designs.

#### **7.2 Security by Design: The Principle of Least Privilege**

Partitioning is a direct and powerful implementation of the **principle of least privilege**, a cornerstone of secure system design.62 This principle dictates that every component should be granted only the minimum set of privileges and resources necessary to perform its function. By placing components into distinct partitions, each with a strictly defined set of permissions, the architecture enforces this principle by default.

This enforcement dramatically reduces the system's **attack surface**. A vulnerability exploited in a less-privileged, network-facing partition (e.g., a web server) is contained. The attacker does not gain access to the resources of a more privileged partition that might hold sensitive data, encryption keys, or critical control logic.22 The compromise of one part does not lead to the compromise of the whole.62 Separation kernels provide the highest-assurance foundation for this model, creating tamper-proof, non-bypassable partitions that can securely host applications of different security classifications (e.g., Top Secret and Unclassified) on the same physical hardware, with provable guarantees that no unauthorized information flow can occur between them.14

#### **7.3 Real-Time Determinism and Performance**

Partitioning delivers significant performance benefits, though the nature of these benefits differs depending on the modality.

* **Performance via Parallelism:** In the world of big data and distributed computing, partitioning is the key that unlocks massive performance gains. By dividing a large dataset and its associated query into smaller pieces, the work can be distributed across hundreds or thousands of cores or nodes, allowing it to be processed in parallel.7 This parallel execution can reduce the time for complex analytical queries from hours to mere seconds or minutes.7  
* **Performance via Pruning:** A more subtle but equally powerful performance benefit comes from **partition pruning**. When data is partitioned on a key that is frequently used in query filters (such as a date or category), the query optimizer can intelligently determine which partitions are relevant to the query and skip scanning all the others.16 For a large historical dataset partitioned by month, a query for a single day's activity might only need to read 1/30th of one partition's data, ignoring 99.9% of the total dataset and dramatically reducing I/O and processing time.63  
* **Real-Time Determinism:** In the domain of real-time systems, performance is measured not just by speed but by predictability. **Temporal partitioning** provides this predictability, or **determinism**. By guaranteeing a fixed budget of CPU time to each critical task, the system ensures that its execution time is bounded and it will always meet its deadline, regardless of the behavior of other, less-critical tasks in the system.6 This guaranteed, low-latency response is a non-negotiable requirement for hard real-time systems like industrial controllers and avionics.22

#### **7.4 Enabling Mixed-Criticality Systems**

Perhaps the most significant modern application of partitioning for isolation is its role as the **enabling technology for Mixed-Criticality Systems (MCS)**. Driven by powerful economic incentives to reduce size, weight, power consumption, and cost (SWaP-C), industries like automotive and aerospace are increasingly consolidating functions with different criticality levels onto single, powerful multi-core processors.15

This consolidation is only feasible if the system can provide absolute assurance that low-criticality functions (e.g., diagnostics, passenger entertainment) cannot interfere with high-criticality, safety-certified functions (e.g., flight controls, autonomous driving decisions).14 Partitioning provides this assurance. By placing components of different criticality into separate, isolated partitions, the architecture prevents fault propagation and resource contention.14

This has a profound impact on the certification process. Instead of having to certify the entire, complex system to the highest level of criticality of its most critical component, each partition can be certified independently to its own required level.46 This modular certification vastly reduces the cost, time, and complexity of system validation.14 Furthermore, these systems can be designed to

**gracefully degrade**. In the event of a failure or resource constraint (such as a low battery), the system can be programmed to automatically drop or reduce the resources allocated to low-criticality partitions while guaranteeing that the high-criticality functions continue to operate, preserving the core safety of the system.44

### **Chapter 8: The Perils of Partitioning: Complexity, Overhead, and Failure Modes**

Despite its profound benefits, partitioning is not a panacea. The act of dividing a system introduces its own set of significant challenges and risks. The decision to partition is effectively a decision to embrace the complexities of a distributed system, even if that system resides on a single chip. These challenges span implementation complexity, performance overhead, and dangerous new failure modes.

#### **8.1 Implementation and Management Complexity**

Partitioning is inherently complex. It adds a significant layer of architectural and managerial overhead to any project.68

* **Design Complexity:** Choosing the right partitioning strategy is a difficult, non-trivial problem. In data systems, selecting an appropriate partitioning key requires a deep, a priori understanding of the data's structure and its future access patterns. A poor choice can lead to performance bottlenecks that are difficult to remedy later.68 In system software, dynamic memory partitioning is notoriously difficult to implement correctly without introducing subtle bugs or fragmentation issues.34  
* **Management Overhead:** A partitioned system is more difficult to manage and maintain. Standard operational tasks like performing backups, applying security patches, and monitoring system health must now be coordinated across dozens or hundreds of partitions or shards. This increases operational complexity and cost, and requires more sophisticated tooling and expertise.68

#### **8.2 Performance Overheads**

While partitioning can boost performance, it can also introduce new sources of overhead that, if not managed carefully, can negate the benefits.

* **Metadata Overhead:** In data systems, creating an excessive number of small partitions can be counterproductive. Each partition requires metadata to describe its contents and location. As the number of partitions grows into the thousands or millions, the sheer size of this metadata catalogue can become a bottleneck, and the time spent retrieving and processing it can slow down query planning.16 This is the problem of  
  **over-partitioning**, where the overhead of managing the partitions outweighs the benefit of pruning them.64  
* **Communication Overhead:** Communication between partitions is never free. In a partitioned OS, an IPC call involves context switches and data copying, which consumes CPU cycles and introduces latency.55 In a distributed system, this communication occurs over the network, which is orders of magnitude slower than local memory access.  
* **Cross-Partition Query Overhead:** Queries that can be satisfied within a single partition are fast. However, queries that need to access data across multiple partitions are significantly more complex and can be slow. Such queries require the system to send parallel requests to all relevant partitions and then aggregate the results on the client side, which can be a time-consuming and resource-intensive process.17

#### **8.3 The Challenge of Data Skew and Hotspots**

A central goal of partitioning for parallelism is to balance the load evenly across all available resources. Failures in this balancing act lead to severe performance degradation.

* **Data Skew:** This occurs when the chosen partitioning strategy results in an uneven distribution of data, with some partitions growing much larger than others.7 For example, if a global customer database is partitioned by country, the shard for the United States or China might be orders of magnitude larger than the one for Luxembourg, completely unbalancing the system.68 This means that queries involving the large partition will be slow, while resources allocated to the small partitions sit idle.9  
* **Hotspots:** This is a related problem where a single partition or shard receives a disproportionate amount of the query traffic, even if the data is evenly distributed.17 This can happen if the partitioning key is based on an attribute that becomes extremely popular, such as partitioning social media data by user ID when a single celebrity user goes viral. This "hot" partition can become overwhelmed, creating a bottleneck for the entire system.

#### **8.4 Catastrophic Failures: The Threat of Network Partitioning**

Perhaps the most insidious and dangerous challenge arises in distributed partitioned systems: the **network partition**. This is not a simple server crash, but a communication failure that splits the cluster into two or more disconnected sub-clusters, or "islands." Critically, nodes within each island can still communicate with each other and may therefore believe they are fully operational, while being completely unaware of the other islands.70

This scenario can lead to **silent and catastrophic failures**. A comprehensive study of 136 such failures in 25 widely used cloud systems found that they frequently result in permanent data loss, data corruption, the reappearance of previously deleted data, and broken synchronization primitives like locks.70 These failures often occur because different parts of the partitioned system develop conflicting views of the system's true state. For example, two islands might each elect their own "leader," leading to a "split-brain" scenario where both leaders accept writes, leading to inconsistent and ultimately corrupted data.70

The study revealed several alarming realities about these failures: they are surprisingly easy to trigger (88% could be caused by isolating a single node), they often require little or no specific client input, and many systems have flawed, simplistic mechanisms for leader election and data consolidation that handle these events incorrectly.70 A particularly dangerous and poorly understood variant is the

**partial network partition**, where nodes have an inconsistent view of the network topology itself (e.g., node A can see B but not C, while node B can see C but not A), leading to deep confusion and failure.70 This threat highlights that the move to a partitioned architecture necessitates a rigorous approach to handling the fundamental problems of distributed consensus and failure detection.

---

## **Part V: The Future Trajectory of Partitioned Systems**

The principles of partitioning, forged in the domains of high-performance data analytics and high-assurance embedded systems, are now being adapted and extended to meet the demands of the next wave of computing. This part examines the future trajectory of partitioned runtimes as they evolve to power emerging technologies like artificial intelligence, the Internet of Things, and autonomous systems.

### **Chapter 9: The Next Frontiers: Edge AI, Autonomous Systems, and IoT**

The future of partitioning is being shaped by three interconnected technology trends that push the boundaries of computation, requiring systems that are simultaneously intelligent, distributed, and reliable. The evolution of partitioned runtimes is central to this future, representing a convergence of the two primary modalities of parallelism and isolation.

#### **9.1 Partitioning AI/ML Models for Distributed and Edge Inference**

The sheer size and computational cost of modern Artificial Intelligence (AI) models, particularly Large Foundation Models (LFMs), make it impossible to run them on a single device. Partitioning is therefore an essential technique for both training and deploying these models.

* **Runtime Model Partitioning:** The **ONNX Runtime** provides a clear example of a partitioned runtime designed specifically for AI inference. It operates on a model's computational graph, dynamically partitioning it into subgraphs at runtime. Each subgraph is then assigned to the most suitable "execution provider"—be it a CPU, a GPU, or a specialized custom accelerator like a Neural Processing Unit (NPU).71 This strategy allows applications to transparently leverage heterogeneous hardware to maximize performance.  
* **Dynamic Reconfiguration for Edge AI:** Looking forward, systems for Edge AI will require even more sophisticated partitioning. The vision is for runtimes that can dynamically reconfigure and redistribute partitions of a large model across a continuum of resources—from the user's device to edge servers and the central cloud. This redistribution will be driven by real-time profiling of network conditions, node utilization, and Quality of Service (QoS) requirements, ensuring consistent and performant AI services even under fluctuating conditions.72  
* **Compiler-Driven Partitioning:** To manage this complexity, new compiler technologies are emerging. Systems like **PartIR** aim to provide a more expressive, predictable, and hardware-agnostic way to partition neural network models.73 By separating the high-level partitioning strategy (expressed as a series of "tactics") from the underlying model code, these tools allow developers to experiment with complex parallelism strategies without rewriting the model itself, de-risking the process of automatic partitioning and making it more portable across different hardware backends.73

#### **9.2 Hardware-Software Partitioning in FPGAs and SoCs for Edge Devices**

In the resource-constrained environment of edge devices—such as IoT sensors, industrial controllers, and wearable medical devices—the trade-off between performance, power consumption, and flexibility is acute. Here, **hardware-software partitioning** on integrated platforms like Field-Programmable Gate Arrays (FPGAs) and Systems-on-Chip (SoCs) is a critical design discipline.74

The core strategy is to offload computationally intensive, highly parallelizable, and latency-sensitive tasks to dedicated hardware logic (the FPGA fabric or specialized accelerators), while keeping higher-level control logic, user interfaces, and functions that require future updates in software running on an embedded CPU.76 For example, in an AI-powered device, the low-level convolution layers of a neural network might be accelerated in hardware, while the pre-processing and final decision logic remain in more flexible C++ code.76

A particularly innovative application of this is **intelligent partitioning** for power management in edge AI MCUs. Alif Semiconductor's Ensemble processors, for instance, feature a partitioned architecture with separate high-performance and high-efficiency core clusters.77 The low-power, high-efficiency cores are always-on, handling continuous, low-intensity monitoring tasks (e.g., listening for a wake-word or scanning for a specific visual event). Only when a relevant event is detected do they wake the power-hungry, high-performance cores to execute the heavy inference workload. This approach dramatically extends battery life, making complex AI feasible in tiny, battery-powered devices like wearable medical sensors.77

#### **9.3 The Role of Partitioning in Autonomous Vehicles and IoT**

Autonomous vehicles and the Internet of Things (IoT) represent the confluence of all these challenges. They are complex, connected, mixed-criticality systems that demand both high performance and high assurance.

* **Autonomous Vehicles:** A modern autonomous vehicle is a quintessential mixed-criticality system on wheels. It must simultaneously process massive streams of sensor data (from LiDAR, radar, and cameras), run sophisticated AI models for perception and decision-making, and execute safety-critical, real-time control functions for steering, braking, and acceleration.78 Partitioned architectures, based on standards like AUTOSAR and enabled by underlying separation kernels, are the only viable way to consolidate these diverse functions onto powerful multi-core SoCs while guaranteeing the safety and security of the vehicle's critical operations.32  
* **IoT and Edge Computing:** The sheer volume of data generated by billions of IoT devices makes centralized cloud processing a bottleneck due to network latency and bandwidth limitations.80  
  **Edge computing** addresses this by moving computation closer to the data sources. Partitioning is fundamental to this paradigm in several ways:  
  * **Workload Partitioning:** Computational tasks are partitioned and distributed across the IoT device, the local edge server, and the remote cloud to find the optimal balance between latency, power consumption, and available compute resources.80  
  * **System Partitioning:** The edge devices themselves, especially in industrial or medical settings, use partitioned runtimes to isolate their critical real-time control functions from their non-critical data analytics and communication functions, ensuring that a network issue or analytics bug does not compromise the device's core operation.37  
  * **Future Network Orchestration:** The next generation of wireless networks, 6G, is envisioned not just as a communication pipeline but as an intelligent workload orchestration system. These networks will be capable of dynamically partitioning and shifting computational tasks and AI model components across the entire device-edge-cloud continuum in real-time, based on application needs and network state.72

This forward-looking perspective reveals a clear trend: the future of partitioning is increasingly **dynamic and heterogeneous**. The static, pre-configured partitions that defined traditional safety-critical systems are evolving. The demands of AI, IoT, and autonomous systems require runtimes that can intelligently and dynamically partition workloads across a diverse fabric of computational resources (CPUs, GPUs, NPUs, FPGAs) and across a physically distributed environment (device, edge, cloud). This represents a grand convergence of the two primary modalities of partitioning—blending the performance-seeking parallelism of the data world with the safety-seeking isolation of the embedded world to manage the complex, unpredictable, and critical workloads of the future.

### **Conclusion**

This report has undertaken a comprehensive analysis of the partitioned runtime, deconstructing it from a single, ambiguous term into a powerful and multifaceted design philosophy with two primary modalities: partitioning for parallelism and partitioning for isolation. The investigation reveals that partitioning is not a single technology but a fundamental architectural approach to managing complexity, scale, performance, and trust in modern computing systems.

The critical trade-off between performance and isolation lies at the heart of every partitioning strategy. In data-centric systems, the goal is to maximize parallelism and minimize data movement, accepting the complexities of distributed state and the risk of network failures to achieve performance at scale. In system-centric, high-assurance environments, the goal is to create provably isolated partitions to guarantee safety and security, accepting the overhead of mediation and the constraints of static configuration to achieve determinism and certifiability.

Based on this analysis, several high-level recommendations emerge for system architects:

* **For architects of large-scale data systems,** the focus must be on **partitioning for parallelism**. The primary challenges are not in the partitioning mechanism itself, but in the strategic decisions surrounding it. Success hinges on selecting the right partitioning key to avoid data skew and hotspots, and on carefully designing application logic to manage the complexity of cross-partition operations and the eventual consistency models they often entail.  
* **For architects of high-assurance, safety-critical systems,** the focus must be on **partitioning for isolation**. The gold standard for this domain is an architecture founded on a **separation kernel**. This approach provides the highest level of verifiable spatial and temporal separation, which is the essential prerequisite for building certifiable mixed-criticality systems where failures are contained and trust is paramount.  
* **For architects of emerging AI and Edge systems,** the future lies in embracing **dynamic and heterogeneous partitioning**. The challenge is to build runtimes that can intelligently partition and orchestrate workloads across a diverse array of hardware accelerators (CPUs, GPUs, NPUs) and a physically distributed landscape (device, edge, cloud). This requires a synthesis of both partitioning modalities: the dynamic, performance-seeking parallelism of data systems combined with the security and isolation principles of critical systems.

Ultimately, the principles of partitioning—of dividing a complex whole into manageable, well-defined parts—are timeless. As computing systems become ever more complex, consolidated, and connected, the disciplined application of these principles will become even more critical. Partitioning is, and will continue to be, a foundational technique for building the scalable, reliable, and secure software that powers our world.

#### **Works cited**

1. Partition problem \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/Partition\_problem](https://en.wikipedia.org/wiki/Partition_problem)  
2. Partition \- Apache Beam®, accessed on August 11, 2025, [https://beam.apache.org/documentation/transforms/java/elementwise/partition/](https://beam.apache.org/documentation/transforms/java/elementwise/partition/)  
3. Partition Allocation Methods in Memory Management \- GeeksforGeeks, accessed on August 11, 2025, [https://www.geeksforgeeks.org/operating-systems/partition-allocation-methods-in-memory-management/](https://www.geeksforgeeks.org/operating-systems/partition-allocation-methods-in-memory-management/)  
4. Data partitioning guidance \- Azure Architecture Center \- Microsoft Learn, accessed on August 11, 2025, [https://learn.microsoft.com/en-us/azure/architecture/best-practices/data-partitioning](https://learn.microsoft.com/en-us/azure/architecture/best-practices/data-partitioning)  
5. Run-Time Partitioning of Scientific Continuum Calculations Running on Multiprocessors | EECS at UC Berkeley, accessed on August 11, 2025, [https://www2.eecs.berkeley.edu/Pubs/TechRpts/1987/5524.html](https://www2.eecs.berkeley.edu/Pubs/TechRpts/1987/5524.html)  
6. OS Partitioning for Embedded Systems \- all-electronics.de, accessed on August 11, 2025, [https://www.all-electronics.de/wp-content/uploads/migrated/document/186151/103ael0406-qnx.pdf](https://www.all-electronics.de/wp-content/uploads/migrated/document/186151/103ael0406-qnx.pdf)  
7. Partitioning Data at Runtime for Data Analytical Queries | by Supun Kamburugamuve | Parallel & Distributed Computing For Data Enthusiasts | Medium, accessed on August 11, 2025, [https://medium.com/parallel-distributed-computing-for-data-enthusiast/partitioning-data-at-runtime-for-data-analytical-queries-7ba12071644e](https://medium.com/parallel-distributed-computing-for-data-enthusiast/partitioning-data-at-runtime-for-data-analytical-queries-7ba12071644e)  
8. Distributed computing \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/Distributed\_computing](https://en.wikipedia.org/wiki/Distributed_computing)  
9. Spark Partitioning: Unlocking Big Data Performance | by Scaibu \- Medium, accessed on August 11, 2025, [https://scaibu.medium.com/spark-partitioning-unlocking-big-data-performance-e08f6891135d](https://scaibu.medium.com/spark-partitioning-unlocking-big-data-performance-e08f6891135d)  
10. Partitioning in Avionics Architectures: Requirements, Mechanisms ..., accessed on August 11, 2025, [https://www.csl.sri.com/papers/partitioning/partition.pdf](https://www.csl.sri.com/papers/partitioning/partition.pdf)  
11. (PDF) A Comparison of Partitioning Operating Systems for ..., accessed on August 11, 2025, [https://www.researchgate.net/publication/225207719\_A\_Comparison\_of\_Partitioning\_Operating\_Systems\_for\_Integrated\_Systems](https://www.researchgate.net/publication/225207719_A_Comparison_of_Partitioning_Operating_Systems_for_Integrated_Systems)  
12. What are partitions and what is adaptive partitioning?, accessed on August 11, 2025, [http://www.qnx.com/developers/docs/qnxcar2/topic/com.qnx.doc.adaptivepartitioning.userguide/topic/ap\_overview\_Partitions\_.html](http://www.qnx.com/developers/docs/qnxcar2/topic/com.qnx.doc.adaptivepartitioning.userguide/topic/ap_overview_Partitions_.html)  
13. A Comparison of Partitioning Operating Systems for Integrated Systems, accessed on August 11, 2025, [https://www.cs.unc.edu/\~anderson/teach/comp790/papers/comparison.pdf](https://www.cs.unc.edu/~anderson/teach/comp790/papers/comparison.pdf)  
14. Separation Kernel – Basis for Certifiable Applications and Systems \- SYSGO, accessed on August 11, 2025, [https://www.sysgo.com/fileadmin/user\_upload/data/professional\_article\_download/SYSGO\_PA\_2019-03\_Separation\_Kernel\_as\_a\_basis\_for\_certifiable\_applications\_and\_systems.pdf](https://www.sysgo.com/fileadmin/user_upload/data/professional_article_download/SYSGO_PA_2019-03_Separation_Kernel_as_a_basis_for_certifiable_applications_and_systems.pdf)  
15. What Are Mixed-Criticality OS Environments? | Wind River | Wind River, accessed on August 11, 2025, [https://www.windriver.com/solutions/learning/what-are-mixed-criticality-os-environments](https://www.windriver.com/solutions/learning/what-are-mixed-criticality-os-environments)  
16. Introduction to partitioned tables | BigQuery \- Google Cloud, accessed on August 11, 2025, [https://cloud.google.com/bigquery/docs/partitioned-tables](https://cloud.google.com/bigquery/docs/partitioned-tables)  
17. Data partitioning strategies \- Azure Architecture Center | Microsoft Learn, accessed on August 11, 2025, [https://learn.microsoft.com/en-us/azure/architecture/best-practices/data-partitioning-strategies](https://learn.microsoft.com/en-us/azure/architecture/best-practices/data-partitioning-strategies)  
18. Creating partitioned tables | BigQuery \- Google Cloud, accessed on August 11, 2025, [https://cloud.google.com/bigquery/docs/creating-partitioned-tables](https://cloud.google.com/bigquery/docs/creating-partitioned-tables)  
19. Partitioned Tables and Indexes \- SQL Server, Azure SQL Database, Azure SQL Managed Instance | Microsoft Learn, accessed on August 11, 2025, [https://learn.microsoft.com/en-us/sql/relational-databases/partitions/partitioned-tables-and-indexes?view=sql-server-ver17](https://learn.microsoft.com/en-us/sql/relational-databases/partitions/partitioned-tables-and-indexes?view=sql-server-ver17)  
20. How does data partitioning improve database performance? \- Tencent Cloud, accessed on August 11, 2025, [https://www.tencentcloud.com/techpedia/107948](https://www.tencentcloud.com/techpedia/107948)  
21. Partition Scheduling in APEX Runtime Environment for Embedded Avionics Software, accessed on August 11, 2025, [https://www.cs.umbc.edu/\~younis/Publications/RTCSA98/RTCSA98.pdf](https://www.cs.umbc.edu/~younis/Publications/RTCSA98/RTCSA98.pdf)  
22. INTEGRITY Real-time Operating System \- Green Hills Software, accessed on August 11, 2025, [https://www.ghs.com/products/rtos/integrity.html](https://www.ghs.com/products/rtos/integrity.html)  
23. Everything You Need to Know When Assessing Partitioning Skills \- Alooba, accessed on August 11, 2025, [https://www.alooba.com/skills/concepts/information-security/internet-security/partitioning/](https://www.alooba.com/skills/concepts/information-security/internet-security/partitioning/)  
24. Real-Time Operating Systems, accessed on August 11, 2025, [http://www.ittc.ku.edu/\~heechul/courses/eecs753/S17/slides/W11-RTOS.pdf](http://www.ittc.ku.edu/~heechul/courses/eecs753/S17/slides/W11-RTOS.pdf)  
25. EC: Embedded Systems Compartmentalization via Intra-Kernel Isolation \- Computer Science Purdue, accessed on August 11, 2025, [https://www.cs.purdue.edu/homes/dxu/pubs/SP23\_EC.pdf](https://www.cs.purdue.edu/homes/dxu/pubs/SP23_EC.pdf)  
26. Utility-Based Cache Partitioning: A Low-Overhead, High-Performance, Runtime Mechanism to Partition Shared Caches | Request PDF \- ResearchGate, accessed on August 11, 2025, [https://www.researchgate.net/publication/221005367\_Utility-Based\_Cache\_Partitioning\_A\_Low-Overhead\_High-Performance\_Runtime\_Mechanism\_to\_Partition\_Shared\_Caches](https://www.researchgate.net/publication/221005367_Utility-Based_Cache_Partitioning_A_Low-Overhead_High-Performance_Runtime_Mechanism_to_Partition_Shared_Caches)  
27. (PDF) Partition scheduling in APEX runtime environment for embedded avionics software, accessed on August 11, 2025, [https://www.researchgate.net/publication/3778398\_Partition\_scheduling\_in\_APEX\_runtime\_environment\_for\_embedded\_avionics\_software](https://www.researchgate.net/publication/3778398_Partition_scheduling_in_APEX_runtime_environment_for_embedded_avionics_software)  
28. ARINC 653 \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/ARINC\_653](https://en.wikipedia.org/wiki/ARINC_653)  
29. avionics application software standard interface part 1 required services arinc653p1-5, accessed on August 11, 2025, [https://www.sae.org/standards/content/arinc653p1-5/](https://www.sae.org/standards/content/arinc653p1-5/)  
30. PikeOS \- Certified RTOS with hypervisor functionality for mission-critical systems \- Third-Party Products & Services \- MATLAB & Simulink \- MathWorks, accessed on August 11, 2025, [https://www.mathworks.com/products/connections/product\_detail/pikeos.html](https://www.mathworks.com/products/connections/product_detail/pikeos.html)  
31. PikeOS \-Hypervisor and RTOS in the same product. Aerospace and Defense, Automotive for Safety and Security systems and Multi-Core certification \- Sightsys, accessed on August 11, 2025, [https://www.sightsys.co.il/product/sysgo-pikeos-hypervisor-rtos-for-aerospace-defense-and-automotive-for-safety-and-security-systems-and-multi-core-certification/](https://www.sightsys.co.il/product/sysgo-pikeos-hypervisor-rtos-for-aerospace-defense-and-automotive-for-safety-and-security-systems-and-multi-core-certification/)  
32. what is a SW partition for AUTOSAR? : r/embedded \- Reddit, accessed on August 11, 2025, [https://www.reddit.com/r/embedded/comments/17jq9do/what\_is\_a\_sw\_partition\_for\_autosar/](https://www.reddit.com/r/embedded/comments/17jq9do/what_is_a_sw_partition_for_autosar/)  
33. Partition Allocation in Memory Management \- Tutorialspoint, accessed on August 11, 2025, [https://www.tutorialspoint.com/partition-allocation-in-memory-management](https://www.tutorialspoint.com/partition-allocation-in-memory-management)  
34. Variable (or Dynamic) Partitioning in Operating System ..., accessed on August 11, 2025, [https://www.geeksforgeeks.org/operating-systems/variable-or-dynamic-partitioning-in-operating-system/](https://www.geeksforgeeks.org/operating-systems/variable-or-dynamic-partitioning-in-operating-system/)  
35. Containers vs Virtual Machines | Atlassian, accessed on August 11, 2025, [https://www.atlassian.com/microservices/cloud-computing/containers-vs-vms](https://www.atlassian.com/microservices/cloud-computing/containers-vs-vms)  
36. Containerization vs Virtualization: 9 Key Differences \- SentinelOne, accessed on August 11, 2025, [https://www.sentinelone.com/cybersecurity-101/cloud-security/containerization-vs-virtualization/](https://www.sentinelone.com/cybersecurity-101/cloud-security/containerization-vs-virtualization/)  
37. Segregated Software Architecture for Medical Devices \- DiVA, accessed on August 11, 2025, [https://kth.diva-portal.org/smash/get/diva2:1985116/FULLTEXT01.pdf](https://kth.diva-portal.org/smash/get/diva2:1985116/FULLTEXT01.pdf)  
38. Containers vs VM \- Difference Between Deployment Technologies ..., accessed on August 11, 2025, [https://aws.amazon.com/compare/the-difference-between-containers-and-virtual-machines/](https://aws.amazon.com/compare/the-difference-between-containers-and-virtual-machines/)  
39. PikeOS \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/PikeOS](https://en.wikipedia.org/wiki/PikeOS)  
40. What Is A Separation Kernel? \- Lynx Software Technologies, accessed on August 11, 2025, [https://www.lynx.com/embedded-systems-learning-center/what-is-a-separation-kernel](https://www.lynx.com/embedded-systems-learning-center/what-is-a-separation-kernel)  
41. Separation kernel \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/Separation\_kernel](https://en.wikipedia.org/wiki/Separation_kernel)  
42. The Quest-V Separation Kernel for Mixed Criticality Systems \- University of York, accessed on August 11, 2025, [https://www-users.york.ac.uk/\~rd17/wmc2013/paper18.pdf](https://www-users.york.ac.uk/~rd17/wmc2013/paper18.pdf)  
43. Formal Verification of Information Flow Security for a Simple ARM-Based Separation Kernel \- DiVA portal, accessed on August 11, 2025, [https://www.diva-portal.org/smash/get/diva2:675835/FULLTEXT01.pdf](https://www.diva-portal.org/smash/get/diva2:675835/FULLTEXT01.pdf)  
44. Energy efficient partition allocation in mixed-criticality systems \- PMC, accessed on August 11, 2025, [https://pmc.ncbi.nlm.nih.gov/articles/PMC6422255/](https://pmc.ncbi.nlm.nih.gov/articles/PMC6422255/)  
45. SYSGO extends PikeOS Support for NXP i.MX 8 Processors with CoreAVI's VkCore® SC GPU Acceleration Driver Implementation, accessed on August 11, 2025, [https://coreavi.com/news/coreavis-extends-pikeos-support/](https://coreavi.com/news/coreavis-extends-pikeos-support/)  
46. Integrating PikeOS With Microchip's RISC-V Based PolarFire® SoC FPGA, accessed on August 11, 2025, [https://www.microchip.com/en-us/about/media-center/blog/2023/integrating-pikeos-with-microchip-risc-v-based-polarfire-soc-fpga](https://www.microchip.com/en-us/about/media-center/blog/2023/integrating-pikeos-with-microchip-risc-v-based-polarfire-soc-fpga)  
47. Mastering Multi-Core Processors in Embedded Applications \- RunTime Recruitment, accessed on August 11, 2025, [https://runtimerec.com/mastering-multi-core-processors-in-embedded-applications/](https://runtimerec.com/mastering-multi-core-processors-in-embedded-applications/)  
48. Resource Allocation Techniques for Processes \- GeeksforGeeks, accessed on August 11, 2025, [https://www.geeksforgeeks.org/operating-systems/resource-allocation-techniques-for-processes/](https://www.geeksforgeeks.org/operating-systems/resource-allocation-techniques-for-processes/)  
49. Kafka topic partitioning strategies and best practices \- New Relic, accessed on August 11, 2025, [https://newrelic.com/blog/best-practices/effective-strategies-kafka-topic-partitioning](https://newrelic.com/blog/best-practices/effective-strategies-kafka-topic-partitioning)  
50. Interprocess Communication in Distributed Systems \- GeeksforGeeks, accessed on August 11, 2025, [https://www.geeksforgeeks.org/operating-systems/interprocess-communication-in-distributed-systems/](https://www.geeksforgeeks.org/operating-systems/interprocess-communication-in-distributed-systems/)  
51. Inter-Service Communication in Microservices \- GeeksforGeeks, accessed on August 11, 2025, [https://www.geeksforgeeks.org/system-design/inter-service-communication-in-microservices/](https://www.geeksforgeeks.org/system-design/inter-service-communication-in-microservices/)  
52. US7412705B2 \- Method for inter partition communication within a logical partitioned data processing system \- Google Patents, accessed on August 11, 2025, [https://patents.google.com/patent/US7412705B2/en](https://patents.google.com/patent/US7412705B2/en)  
53. US7921426B2 \- Inter partition communication within a logical partitioned data processing system \- Google Patents, accessed on August 11, 2025, [https://patents.google.com/patent/US7921426B2/en](https://patents.google.com/patent/US7921426B2/en)  
54. Inter-Partition Communication \- Microsoft Learn, accessed on August 11, 2025, [https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/tlfs/inter-partition-communication](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/tlfs/inter-partition-communication)  
55. Difference Between Microkernel and Monolithic Kernel ..., accessed on August 11, 2025, [https://www.geeksforgeeks.org/operating-systems/difference-between-microkernel-and-monolithic-kernel/](https://www.geeksforgeeks.org/operating-systems/difference-between-microkernel-and-monolithic-kernel/)  
56. What is difference between monolithic and micro kernel? \- Stack Overflow, accessed on August 11, 2025, [https://stackoverflow.com/questions/4537850/what-is-difference-between-monolithic-and-micro-kernel](https://stackoverflow.com/questions/4537850/what-is-difference-between-monolithic-and-micro-kernel)  
57. Partitioning Communication System \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/Partitioning\_Communication\_System](https://en.wikipedia.org/wiki/Partitioning_Communication_System)  
58. Kernel (operating system) \- Wikipedia, accessed on August 11, 2025, [https://en.wikipedia.org/wiki/Kernel\_(operating\_system)](https://en.wikipedia.org/wiki/Kernel_\(operating_system\))  
59. Difference between Micro Kernel and Modular Kernel \- GeeksforGeeks, accessed on August 11, 2025, [https://www.geeksforgeeks.org/operating-systems/difference-between-micro-kernel-and-modular-kernel/](https://www.geeksforgeeks.org/operating-systems/difference-between-micro-kernel-and-modular-kernel/)  
60. Are there any reasons to choose VMs over containers? : r/devops \- Reddit, accessed on August 11, 2025, [https://www.reddit.com/r/devops/comments/qvzrkm/are\_there\_any\_reasons\_to\_choose\_vms\_over/](https://www.reddit.com/r/devops/comments/qvzrkm/are_there_any_reasons_to_choose_vms_over/)  
61. performance problem with partitioning table \- Ask TOM, accessed on August 11, 2025, [https://asktom.oracle.com/ords/f?p=100:11:0::::p11\_question\_id:14188311731917](https://asktom.oracle.com/ords/f?p=100:11:0::::p11_question_id:14188311731917)  
62. Fine-grained Program Partitioning for Security, accessed on August 11, 2025, [https://www.cse.psu.edu/\~gxt29/papers/HuangEuroSec21.pdf](https://www.cse.psu.edu/~gxt29/papers/HuangEuroSec21.pdf)  
63. Micro-partitions & Data Clustering \- Snowflake Documentation, accessed on August 11, 2025, [https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions)  
64. Top 10 Performance Tuning Tips for Amazon Athena | AWS Big Data Blog, accessed on August 11, 2025, [https://aws.amazon.com/blogs/big-data/top-10-performance-tuning-tips-for-amazon-athena/](https://aws.amazon.com/blogs/big-data/top-10-performance-tuning-tips-for-amazon-athena/)  
65. Mixed Criticality Systems \- A Review \- University of York, accessed on August 11, 2025, [https://www-users.york.ac.uk/\~ab38/review.pdf](https://www-users.york.ac.uk/~ab38/review.pdf)  
66. Allocation algorithms for multicore partitioned mixed-criticality real-time systems \- PMC, accessed on August 11, 2025, [https://pmc.ncbi.nlm.nih.gov/articles/PMC11784874/](https://pmc.ncbi.nlm.nih.gov/articles/PMC11784874/)  
67. Partitioned Mixed-Criticality Scheduling on Multiprocessor Platforms, accessed on August 11, 2025, [https://user.it.uu.se/\~wangyi/pdf-files/2014/date14-gu.pdf](https://user.it.uu.se/~wangyi/pdf-files/2014/date14-gu.pdf)  
68. Common Problems Associated with Data Partitioning \- Design Gurus, accessed on August 11, 2025, [https://www.designgurus.io/course-play/grokking-system-design-fundamentals/doc/common-problems-associated-with-data-partitioning](https://www.designgurus.io/course-play/grokking-system-design-fundamentals/doc/common-problems-associated-with-data-partitioning)  
69. Addressing performance issues with over-partitioned Delta tables \- Databricks, accessed on August 11, 2025, [https://kb.databricks.com/data/addressing-performance-issues-with-over-partitioned-delta-tables](https://kb.databricks.com/data/addressing-performance-issues-with-over-partitioned-delta-tables)  
70. An Analysis of Network-Partitioning Failures in Cloud ... \- USENIX, accessed on August 11, 2025, [https://www.usenix.org/system/files/osdi18-alquraan.pdf](https://www.usenix.org/system/files/osdi18-alquraan.pdf)  
71. ONNX Runtime Architecture, accessed on August 11, 2025, [https://onnxruntime.ai/docs/reference/high-level-design.html](https://onnxruntime.ai/docs/reference/high-level-design.html)  
72. Intelligent Orchestration of Distributed Large Foundation Model Inference at the Edge \- arXiv, accessed on August 11, 2025, [https://arxiv.org/html/2504.03668v2](https://arxiv.org/html/2504.03668v2)  
73. PartIR: Composing SPMD Partitioning Strategies for Machine Learning \- arXiv, accessed on August 11, 2025, [https://arxiv.org/html/2401.11202v2](https://arxiv.org/html/2401.11202v2)  
74. Dynamic Hardware/Software Partitioning: A First Approach \- Computer Science and Engineering, accessed on August 11, 2025, [https://www.cs.ucr.edu/\~vahid/pubs/dac03\_dhs.pdf](https://www.cs.ucr.edu/~vahid/pubs/dac03_dhs.pdf)  
75. Partitioning methodology for dynamically reconfigurable embedded systems | IEE Proceedings \- Computers and Digital Techniques, accessed on August 11, 2025, [https://digital-library.theiet.org/doi/10.1049/ip-cdt%3A20000871](https://digital-library.theiet.org/doi/10.1049/ip-cdt%3A20000871)  
76. Hardware-Software Partitioning in FPGA Systems \- Fidus Systems, accessed on August 11, 2025, [https://fidus.com/blog/balancing-hardware-software-partitioning-in-fpga-based-systems/](https://fidus.com/blog/balancing-hardware-software-partitioning-in-fpga-based-systems/)  
77. Understanding The Ensemble Difference: Intelligent Partitioning ..., accessed on August 11, 2025, [https://alifsemi.com/understanding-the-ensemble-difference-intelligent-partitioning-extends-battery-run-time-in-edge-ai-devices/](https://alifsemi.com/understanding-the-ensemble-difference-intelligent-partitioning-extends-battery-run-time-in-edge-ai-devices/)  
78. (PDF) Cloud and Edge Computing for Connected and Automated Vehicles \- ResearchGate, accessed on August 11, 2025, [https://www.researchgate.net/publication/377404783\_Cloud\_and\_Edge\_Computing\_for\_Connected\_and\_Automated\_Vehicles](https://www.researchgate.net/publication/377404783_Cloud_and_Edge_Computing_for_Connected_and_Automated_Vehicles)  
79. Tackling Mixed-Criticality for Automotive | SYSGO, accessed on August 11, 2025, [https://www.sysgo.com/blog/article/tackling-mixed-criticality-for-automotive](https://www.sysgo.com/blog/article/tackling-mixed-criticality-for-automotive)  
80. A Survey on the Use of Partitioning in IoT-Edge-AI Applications \- arXiv, accessed on August 11, 2025, [https://arxiv.org/html/2406.00301v1](https://arxiv.org/html/2406.00301v1)