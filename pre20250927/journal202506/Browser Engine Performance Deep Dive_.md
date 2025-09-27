

# **A Legacy-Free Architecture for the Modern Web: A Feasibility Study on Achieving Order-of-Magnitude Performance Gains**

### **Executive Summary**

The modern web browser is a marvel of engineering, but it is also a prisoner of its own history. The dominant browser engines of today—Blink, Gecko, and WebKit—are built upon architectural foundations laid down in an era of static documents, single-core processors, and manually managed memory. Despite decades of brilliant optimization, these legacy constraints impose a fundamental ceiling on performance, security, and reliability. Incremental improvements are no longer sufficient to meet the demands of a new generation of highly interactive, data-intensive web applications, such as professional creative tools, real-time data visualizations, and complex simulations.

This report presents a feasibility study for a new, "legacy-free" browser engine designed from first principles to achieve a 10-40x performance improvement over current-generation browsers for these target applications. It posits that such gains are not possible through further optimization of existing architectures but require a radical paradigm shift in three core areas:

1. **The Runtime:** Replacing the Just-In-Time (JIT) compiled, garbage-collected JavaScript runtime with an Ahead-Of-Time (AOT) compiled model based on Rust and WebAssembly (WASM). This shift eliminates entire classes of performance bottlenecks, such as non-deterministic garbage collection pauses and JIT de-optimization, while providing compile-time guarantees of memory safety and data-race freedom.  
2. **The Rendering Model:** Abandoning the Document Object Model (DOM)—an API designed for text documents, not applications—in favor of a GPU-centric, immediate-mode rendering pipeline inspired by modern game engine architecture. By leveraging Data-Oriented Design (DOD) and low-level graphics APIs like WebGPU, this approach fundamentally realigns the engine with the memory access patterns of modern hardware, unlocking massive throughput gains.  
3. **The Concurrency Model:** Moving from a largely single-threaded core processing model to a massively parallel architecture, drawing lessons from the Servo project. By designing for fine-grained task and data parallelism from the outset, the engine can fully exploit the multi-core processors that are now ubiquitous.

The analysis concludes that the 10-40x performance target is architecturally plausible but is highly dependent on the application workload. The most significant gains will be realized in applications currently bottlenecked by rendering complexity, heavy client-side computation, and the need for predictable, low-latency execution. However, the greatest challenge is not technical but strategic. Attempting to build a general-purpose browser to compete with the incumbent monoculture is untenable due to the immense burden of web compatibility. Therefore, this report strongly recommends a focused strategy: to build a high-performance, *embeddable* engine. This engine would serve as a next-generation runtime for specialized applications, potentially integrating with frameworks like Tauri, rather than attempting to replace the browser wholesale. This approach de-risks the endeavor and provides a viable path to market for a technology that could enable a new class of applications on the web.

## **Part I: The Anatomy of Legacy Overhead in Modern Browsers**

To justify a new architecture, one must first perform a forensic analysis of the old. The performance limitations of modern browsers are not the result of incompetent engineering; on the contrary, they are monuments to the heroic efforts of thousands of engineers working to overcome foundational architectural decisions made decades ago. This section dissects the inherent sources of overhead in the incumbent browser engines, establishing the technical predicate for a paradigm shift.

### **Section 1: The Architectural Debt of Incumbent Engines**

The current browser engine market is less a diverse ecosystem and more a single family with a shared, and burdensome, inheritance. This genetic similarity is the root of the platform's architectural stagnation.

#### **1.1 A Tale of Three Engines: Blink, Gecko, and WebKit**

The web is rendered by a small handful of engines, but in practice, it is dominated by one architectural lineage. This has created a monoculture that reinforces the status quo and stifles radical innovation.1

* **Blink:** Developed by Google for Chromium, Blink is a fork of WebKit. This fork was motivated by the desire to implement a different multi-process architecture, which has allowed Google to innovate at a faster pace.1 Today, Blink is the engine for Chrome, Microsoft Edge, Opera, and numerous other browsers, giving it a market share of over 74%.2 It is the de facto standard for which web developers build and test, benefiting from massive investment by Google and contributions from a wide consortium of tech companies.1 Its performance is generally considered excellent, particularly in its efficient memory management, where its multi-process model allows it to release memory simply by terminating a tab's process—a significant advantage over the memory leak issues that have historically plagued single-process models.4  
* **WebKit:** The common ancestor of Blink, WebKit is primarily developed by Apple for the Safari browser.5 While sharing a common heritage with Blink, its development path has diverged. This divergence can lead to differences in feature support and performance characteristics, contributing to web compatibility challenges for developers.1 On iOS, Apple's policies mandate that all third-party browsers use WebKit, further cementing its importance on that platform but also limiting browser differentiation.1  
* **Gecko:** Developed by Mozilla for Firefox, Gecko represents the only major architectural alternative to the WebKit family.5 It has a long history of strong standards compliance and has pioneered significant technologies, such as the Stylo CSS engine, which is known for its high performance.7 However, Gecko's market share has been shrinking for years.4 This creates a vicious cycle: as fewer users are on Gecko, developers spend less time testing and optimizing for it. Consequently, users may encounter more bugs or perceive lower performance on Gecko-based browsers, further driving them toward the Blink ecosystem.4

The dominance of Blink has created a powerful feedback loop. The web is now implicitly designed for Blink's specific behaviors and performance characteristics. Any new engine, regardless of its technical merits, faces the monumental task of first achieving near-perfect compatibility with Blink's implementation details to render the modern web correctly. This effectively forces new entrants to replicate the very legacy architecture they might seek to replace, creating a formidable barrier to fundamental innovation.

#### **1.2 The Sisyphean Task of Refactoring: BlinkNG and LayoutNG**

Recognizing the limitations of their legacy codebase, the Chromium team has undertaken massive, multi-year refactoring projects. These efforts, known as BlinkNG and LayoutNG, are a testament to the scale of the architectural debt and illustrate that even with immense resources, the goal is to stabilize the existing paradigm, not replace it.8

The pre-NG architecture in Blink was a classic example of entropy in a large C++ system. The rendering pipeline was conceptually divided into phases like style, layout, and paint, but the boundaries between them were porous.8 Data was stored in long-lived, mutable objects, making it nearly impossible to reason about the state of the system at any given time.9 This led to a host of persistent and difficult-to-diagnose bugs:

* **Under-invalidation:** A part of the layout tree was considered "clean" when it actually needed to be re-computed, leading to incorrect rendering.  
* **Hysteresis:** Layout was not idempotent; toggling a CSS property could cause an element to grow incrementally with each cycle.  
* **General Brittleness:** The lack of clear contracts between components meant that fixing a bug in one area often caused regressions in another, seemingly unrelated part of the system.9

BlinkNG was the umbrella project to fix this. It introduced a formal DocumentLifecycle class to track and enforce the state of the rendering pipeline, ensuring that operations happen in the correct order and that data is not modified at inappropriate times.8

Within BlinkNG, **LayoutNG** was the specific project to overhaul the layout phase. It replaced the old "mutable tree" with a new architecture centered on an **immutable fragment tree**.9 In this model, layout is treated as a function that takes style and DOM information as input and produces a new, immutable fragment tree as output. This functional approach makes layout results cacheable and eliminates entire classes of bugs related to mutable state. While these projects have been enormously successful in improving the reliability, testability, and performance of the engine—and have enabled the implementation of powerful new features like container queries—they operate within the existing paradigm.8 They are a heroic effort to pave the cowpaths of a legacy design, not to chart a new course.

The following table provides a high-level comparison of the architectural philosophies of legacy engines, the experimental Servo engine, and the proposed legacy-free engine, illustrating the evolutionary path from the current state to the proposed future.

| Architectural Feature | Legacy Engine (Blink/Gecko) | Servo (Experimental) | Proposed Legacy-Free Engine |
| :---- | :---- | :---- | :---- |
| **Core Language** | C++ | Rust | Rust |
| **Concurrency Model** | Coarse-grained (Multi-process) | Fine-grained (Task Parallel) | Fine-grained (Task & Data Parallel) |
| **Layout Engine** | Mutable Layout Tree (pre-NG) / Retained Mode | Parallel Layout | DOD Scene Graph (Hybrid Mode) |
| **Memory Management** | Garbage Collection | Ownership/Borrowing | Ownership/Borrowing |
| **Scripting Runtime** | JavaScript (JIT) | JavaScript (via SpiderMonkey FFI) | WebAssembly (AOT) |

### **Section 2: The JavaScript Runtime: A High-Performance Engine Hitting Its Ceiling**

JavaScript is the lingua franca of the web, and its performance has improved dramatically over the last decade thanks to sophisticated Just-In-Time (JIT) compilers. However, the very design of this dynamic language and its runtime environment creates fundamental performance ceilings and trade-offs that cannot be overcome through further optimization alone.

#### **2.1 The JIT Compilation Trade-off**

Modern JavaScript engines like Google's V8 and Mozilla's SpiderMonkey do not simply interpret code. They employ a multi-stage compilation pipeline to transform JavaScript into highly optimized machine code at runtime.10 This JIT compilation is the source of JavaScript's impressive speed, but it comes with inherent costs.12

* **Advantages:** The key advantage of a JIT is its ability to perform profile-guided, speculative optimizations. By observing the code as it runs, the engine can make assumptions about variable types and object structures ("hidden classes").10 It can then generate specialized machine code that is much faster than generic code that must handle any possibility. For frequently executed "hot" code paths, the JIT can produce performance that approaches that of statically compiled languages.12  
* **Disadvantages:** This dynamism is a double-edged sword.  
  * **Startup Latency:** JIT compilation is not free; it consumes CPU cycles during the application's startup phase. To manage this, engines use a tiered approach: code is first interpreted, then compiled by a fast but less-optimizing baseline JIT, and only "hot" functions are passed to the slower, highly-optimizing JIT.11 This means an application has a "warm-up" period before it reaches peak performance.  
  * **Memory Overhead:** A JIT-based engine is memory-intensive. It must keep the original source code, an intermediate representation (bytecode), profiling data, and potentially multiple tiers of compiled machine code in memory simultaneously.12  
  * **Performance Cliffs (De-optimization):** The JIT's speculative optimizations are its greatest strength and its greatest weakness. If a runtime assumption is violated—for example, if the shape of an object changes unexpectedly—the highly optimized machine code must be discarded, and execution must fall back to a slower, non-optimized version. This "de-optimization" event can cause sudden, jarring performance drops, making it difficult to achieve consistently smooth frame rates in complex applications.12  
  * **Security Vulnerabilities:** The JIT compiler is one of the largest and most complex components of a browser engine, and it represents a significant attack surface. A single bug in the logic of an optimizing compiler can create subtle memory corruption vulnerabilities that are highly sought after by attackers.12

#### **2.2 The Hidden Tax of Automatic Memory Management (Garbage Collection)**

JavaScript relieves developers from the burden of manual memory management by employing an automatic garbage collector (GC). While this simplifies development, it introduces a "performance tax" in the form of unpredictable application pauses and CPU overhead, which are particularly detrimental to interactive, real-time applications.15

The core problem with most high-performance garbage collectors is the "stop-the-world" pause. To safely identify and reclaim unused memory, the GC must periodically halt the execution of the application's main thread.17 The duration of this pause is not determined by the amount of garbage being collected, but rather by the amount of

*live* memory that must be scanned.19 For an application with a large number of live objects, these pauses can last for many milliseconds, causing missed frames and perceptible "jank" or stuttering.

This issue is exacerbated in highly parallel environments. As an analysis of multi-threaded Java applications shows, even if garbage collection consumes only 1% of the total execution time, it can lead to a throughput loss of over 20% on a 32-processor system because all 32 threads must be suspended simultaneously.19

Furthermore, the continuous cycle of allocating and freeing memory blocks of various sizes leads to memory fragmentation. Over time, the heap can become a patchwork of used and free blocks, making it difficult to find a contiguous block of memory for a large new allocation. The solution is compaction, where the GC moves all live objects together to one end of the heap. However, compaction is a costly operation that significantly adds to the duration of the stop-the-world pause.19

The very mechanisms designed to make JavaScript fast and easy to use—the JIT compiler and the garbage collector—are locked in a performance-destroying feedback loop. The JIT's optimization processes, such as profiling and recompilation, generate a high volume of temporary objects. This object churn places significant pressure on the GC, forcing it to run more frequently. Each GC cycle, in turn, introduces a pause that interrupts not only the user's interaction with the application but also the JIT's own ongoing optimization work. Thus, the tool for improving throughput (the JIT) directly contributes to the source of latency spikes (the GC).

This interplay leads to a crucial conclusion: the performance of a complex JavaScript application is fundamentally probabilistic, not deterministic. The combination of unpredictable GC pauses and the potential for JIT de-optimization means that the execution time for a given piece of code is not constant. It can vary significantly based on the current state of the memory heap and the validity of the JIT's speculative assumptions. This lack of predictability is unacceptable for the next generation of professional, real-time web applications that require consistent, guaranteed performance.

### **Section 3: The Document Object Model: The Web's Foundational Bottleneck**

The most significant and deeply entrenched performance barrier in modern browsers is the Document Object Model (DOM). Conceived as an API for representing and manipulating structured text documents, it is an architecturally poor fit for the dynamic, state-driven graphical user interfaces of modern web applications. The entire ecosystem of modern frontend frameworks is, in essence, a complex and elaborate collection of workarounds for the DOM's fundamental inefficiencies.

#### **3.1 The High Cost of a Document-Oriented API**

The DOM represents a web page as a tree of objects. While conceptually simple, manipulating this tree is one of the most expensive operations a web application can perform.20

The primary performance killer is a process known as **reflow** (or layout). When a script changes a property that affects an element's geometry—such as its width, height, or position—the browser must recalculate the position and dimensions of not only that element but potentially all of its children, siblings, and ancestors.20 This cascading layout calculation is a synchronous, CPU-intensive, user-blocking operation. In a complex UI, a single DOM change can trigger a reflow that takes many milliseconds, leading directly to dropped frames and a sluggish user experience.

An even more insidious problem is **layout thrashing**. This occurs when a script alternates between writing to the DOM (e.g., element.style.width \= '100px') and reading a layout-dependent property from the DOM (e.g., let height \= element.offsetHeight). To return an accurate value for offsetHeight, the browser is forced to perform a synchronous reflow immediately, flushing its queue of pending layout changes. If this pattern occurs in a loop, the application will trigger dozens or hundreds of expensive reflows instead of a single, batched one, grinding performance to a halt.22

#### **3.2 The Virtual DOM: A Necessary but Insufficient Abstraction**

The rise of frontend frameworks like React and Vue was a direct response to the difficulty and performance pitfalls of direct DOM manipulation. Their central innovation was the **Virtual DOM (VDOM)**, an abstraction layer that allows developers to write declarative, state-driven UIs while the framework handles the messy details of optimizing DOM updates.23

It is a common misconception that the VDOM is "fast." As argued by the creator of the Svelte framework, the VDOM is, in fact, "pure overhead".25 The process works as follows: when application state changes, the framework re-renders a new VDOM—a lightweight representation of the UI as a JavaScript object tree. It then performs a "diffing" algorithm to compare the new VDOM tree with the previous one. Finally, it calculates the minimal set of imperative DOM operations (e.g.,

setAttribute, appendChild) needed to patch the real DOM to match the new state.25

This entire diffing and patching process consumes CPU and memory. It is a runtime cost that a compiler-based framework like Svelte avoids by generating highly optimized, direct DOM manipulation code at build time.25 The true value of the VDOM is not raw performance but developer ergonomics. It provides a declarative programming model that is vastly superior to imperative DOM manipulation. It allows developers to reason about their UI as a simple function of state (

UI \= f(state)), freeing them from the complex and error-prone task of manual state tracking and DOM updates.23

The current web UI stack is architecturally inverted. The DOM is a low-level, retained-mode graphics system: developers create objects (nodes), and the browser retains them, managing their state and rendering.26 To make this system manageable, the web development community built high-level, immediate-mode-style abstractions—like React's component model—on top of it in JavaScript.25 This is the reverse of high-performance systems like game engines, which provide a fundamental immediate-mode rendering loop and allow developers to build retained-mode abstractions (like scene graphs) on top only where necessary. This architectural inversion is the source of tremendous complexity and overhead, as the entire VDOM and diffing mechanism is essentially a user-land emulation of what the underlying platform should provide. A legacy-free engine has the opportunity to correct this inversion by providing the right low-level, immediate-mode primitives natively.

## **Part II: A Blueprint for a High-Performance, Legacy-Free Engine**

Having established the fundamental limitations of legacy architectures, this section outlines a new paradigm. This blueprint is not an incremental evolution but a radical rethinking of the browser engine's core components, designed to directly address the bottlenecks of the past and unlock the performance required for the applications of the future.

### **Section 4: The Core Language and Runtime: A Paradigm Shift to Rust and WebAssembly**

The foundation of any high-performance system is its language and runtime. The proposed engine abandons the dynamic, garbage-collected world of JavaScript in favor of the static, compiled, and memory-safe environment of Rust and WebAssembly.

#### **4.1 Rust as the Engine's Lingua Franca**

The choice of implementation language for a multi-million-line-of-code project like a browser engine has profound implications for security, reliability, and performance. The legacy choice of C++ has saddled existing engines with a constant, expensive battle against memory safety bugs and data races. Adopting Rust is a strategic decision to eliminate these entire classes of problems at the compiler level.27

* **Memory Safety without a Garbage Collector:** Rust's novel ownership and borrowing system provides compile-time guarantees of memory safety. It statically prevents common C++ pitfalls like use-after-free errors, dangling pointers, and buffer overflows.28 Crucially, it achieves this without the runtime performance overhead, non-deterministic pauses, and high memory usage of a garbage collector.19 The experience of the Servo project is telling: in over two years of development, they encountered zero use-after-free bugs in safe Rust code, a category of vulnerability that consistently plagues legacy engines.28  
* **Fearless Concurrency:** Building a massively parallel engine requires a language that can manage concurrency safely. Rust's type system extends its ownership model to threads, statically guaranteeing that code is free from data races.29 This allows engineers to write complex multi-threaded code with a high degree of confidence, a concept often referred to as "fearless concurrency." This is not merely a convenience; it is a prerequisite for the fine-grained parallelism that the new architecture requires.27

While Rust can offer better raw performance than JavaScript, its most significant advantage for an engine of this scale is not a marginal speedup in single-threaded code. It is the ability to build a reliable, secure, and massively concurrent system by construction. The engineering cost of achieving this level of reliability in C++ is astronomical. Rust fundamentally shifts this cost from expensive runtime testing, debugging, and patching to a one-time, upfront cost at compile time—a vastly more scalable and effective model for software engineering.

#### **4.2 WebAssembly (WASM) as the Universal Runtime**

The proposed engine makes a radical departure from the status quo: it treats WebAssembly as its primary, first-class runtime for application code. JavaScript is not abandoned but is demoted to a "guest" language, supported via a JS-to-WASM compiler. This inverts the current relationship and aligns the engine with a future of polyglot, high-performance web development.

Officially, WASM is positioned as a complement to JavaScript, a compilation target for performance-critical modules written in languages like C++ and Rust that run alongside the main JS application.30 However, this model has a critical flaw: the performance cost of the Foreign Function Interface (FFI) between JavaScript and WASM. Every call from JS to WASM, and especially every call from WASM back to JS to access a Web API like the DOM, incurs overhead.32 For applications with "chatty" communication between the two worlds, this interop tax can easily overwhelm any performance gains achieved within the WASM module itself.33

A truly legacy-free, WASM-native engine would solve this by exposing its core APIs—rendering, input, networking, etc.—directly to WebAssembly modules. An application written in Rust, C++, or any other WASM-compiling language could interact with the engine's core functionality without ever crossing a costly language boundary. This "WASM-first" architecture is the key to unlocking the full performance potential of WebAssembly.

#### **4.3 Lessons from the Trenches: The Zaplib Post-Mortem**

The story of Zaplib, an ambitious startup that aimed to build a Rust/WASM framework for high-performance web apps, serves as a crucial and sobering case study.34 Their post-mortem provides invaluable lessons for any project in this space.

Zaplib's initial pitch was to allow developers to incrementally port slow parts of their JavaScript applications to Rust. This strategy failed. Their analysis revealed that for many real-world workloads, the performance gain of Rust/WASM over a highly optimized V8 engine was not the promised 10-40x, but a more modest 2x, and in some cases as low as 5%.34 This marginal gain was insufficient to persuade developers to adopt the significant complexity and cognitive overhead of a new language and toolchain.

The post-mortem uncovered two critical truths. First, the most significant performance wins often came not from Rust itself, but from using a better architecture—specifically, their GPU-accelerated WebGL renderer. A well-architected JavaScript rewrite could have potentially achieved similar gains.34 Second, the "FFI tax" is real and punishing. The cost of data marshalling and function calls across the JS/WASM boundary is a primary architectural constraint.

The failure of Zaplib's incremental approach demonstrates that a new engine cannot succeed by merely offering a slightly faster runtime for isolated functions. To achieve order-of-magnitude gains, the application's entire performance-critical path, including the main application loop and rendering logic, must live *within* the WASM environment. The engine's architecture must be designed from the ground up to support this holistic, WASM-native model, minimizing boundary crossings to an absolute minimum.

### **Section 5: The Rendering Pipeline Reimagined: Applying Game Engine Principles**

The single greatest opportunity for performance improvement lies in completely replacing the DOM-based rendering model. The proposed engine will abandon the concept of a retained-mode document tree and instead adopt the GPU-centric, immediate-mode, data-oriented principles that have been perfected over decades in the high-performance world of game engines.35

#### **5.1 Beyond the DOM: A GPU-Centric, Immediate-Mode UI Paradigm**

The fundamental difference between a browser and a game engine is how they approach the task of drawing pixels to the screen. A browser's DOM-based pipeline is a complex, multi-stage, mostly CPU-bound process designed for document layout.35 A game engine's pipeline is a lean, GPU-bound process designed to render a complete scene from scratch 60 or more times per second.37

The new engine will be built on this game engine philosophy. Its core rendering API will not be a tree of objects but a direct, low-level interface to the GPU, built on top of the modern **WebGPU** standard.39 WebGPU provides the necessary primitives for this approach, including direct control over rendering pipelines, memory buffers, and, crucially, access to

**compute shaders**. Compute shaders allow general-purpose, massively parallel computations to be offloaded to the GPU, opening the door for GPU-accelerated layout, physics, and AI, directly within the engine.39

This GPU-centric foundation enables an **Immediate Mode GUI (IMGUI)** architecture.41 In an IMGUI system, the UI is not stored in a persistent data structure like the DOM. Instead, the application's UI-rendering code is executed every single frame. This code reads the current application state and issues a series of draw commands directly to the GPU.26 This model radically simplifies state management—the UI is always a pure, stateless function of the application data—and eliminates the need for the complex diffing and patching algorithms of VDOM-based frameworks.43

#### **5.2 Data-Oriented Design (DOD) for UI**

To make this immediate-mode approach performant, the engine must abandon the object-oriented design of the DOM in favor of **Data-Oriented Design (DOD)**. DOD is a programming paradigm that focuses on the layout of data in memory to maximize the efficiency of modern hardware, particularly CPU caches.44

The core technique of DOD is the transformation of data from an **Array of Structures (AoS)** to a **Structure of Arrays (SoA)**. In a traditional object-oriented (AoS) approach, data for a UI element might be stored as an array of objects: \[{pos\_x, pos\_y, color\_r, color\_g, color\_b},...\]. When the rendering system needs to process all the X-positions, the CPU must jump around in memory, fetching each object individually. This leads to poor spatial locality and frequent, slow cache misses.

In an SoA approach, the data is reorganized into parallel arrays of its constituent components: {x: \[pos\_x,...\], y: \[pos\_y,...\], r: \[color\_r,...\],...}. Now, when the system processes all X-positions, it can perform a single, linear scan over a contiguous block of memory. This is the most efficient possible access pattern for a modern CPU, as it maximizes the use of the cache and allows the hardware prefetcher to work effectively.44

This SoA layout also perfectly enables **vectorization** using SIMD (Single Instruction, Multiple Data) instructions. SIMD allows the CPU to perform the same operation on multiple pieces of data (e.g., four floating-point numbers) in a single instruction, providing another layer of parallelism that is critical for high-performance data processing.44 Performance is memory access. The 10-40x claim is fundamentally a statement about improving the efficiency of memory access patterns. The DOM's pointer-rich, object-oriented graph is architecturally antithetical to the way modern hardware works. Adopting DOD is not a minor optimization; it is the central architectural principle that makes the target performance gains achievable.

#### **5.3 A Hybrid Scene Graph Architecture**

While a pure immediate-mode system offers maximum performance, it can be too low-level for complex applications. A more practical approach is a hybrid model that combines the organizational benefits of a retained-mode **scene graph** with the performance of an immediate-mode renderer.45

A scene graph is a tree data structure that represents the hierarchical spatial relationships between elements in a scene.47 It simplifies transformations (moving a parent moves all its children) and enables efficient culling (quickly discarding elements that are not visible on screen). The proposed engine would feature a highly optimized, lightweight scene graph. However, unlike the DOM, this scene graph would not be a tree of heavyweight objects. Instead, it would be implemented using DOD principles: a collection of tightly packed SoA data tables representing the nodes and their properties (transforms, materials, etc.). Each frame, the engine would traverse this data-oriented scene graph in a highly efficient, cache-friendly manner, using the information to generate a linear command list that is then submitted to the GPU for immediate-mode rendering.48 This hybrid approach provides the best of both worlds: the declarative, hierarchical structure that makes complex UIs manageable, and the raw, data-oriented performance required to render them at high frame rates.

### **Section 6: A Natively Parallel Architecture: Lessons from Servo**

Modern CPUs are parallel processors, yet legacy browser engines remain fundamentally sequential in their core operations. To fully exploit modern hardware, a new engine must be designed for fine-grained parallelism from its inception, following the pioneering architectural work of the Servo project.

#### **6.1 Designing for Parallelism from First Principles**

CPU clock speeds have stagnated; performance improvements for the last decade have come from increasing the number of cores.50 Legacy browser architectures, which rely on a single "main thread" for critical-path operations like JavaScript execution and layout, are an anachronism in this multi-core world.35 They are unable to effectively utilize the hardware they run on.

The Servo project was initiated by Mozilla Research with the explicit goal of building a browser engine that could leverage parallelism at every level.27 It used the Rust programming language precisely because Rust's compile-time safety guarantees made it feasible to build such a complex, concurrent system without succumbing to an endless plague of data races and memory corruption bugs.28

#### **6.2 The Servo Pipeline: Decomposing Rendering into Concurrent Tasks**

Servo's most important architectural contribution was to decompose the monolithic, sequential rendering pipeline of traditional browsers into a set of independent tasks that communicate via message passing and can be executed in parallel across multiple CPU cores.27

The core of the Servo architecture is a pipeline consisting of three main tasks for each browser tab (or "constellation"):

1. **Script Task:** This task is responsible for the DOM tree and for executing JavaScript via the SpiderMonkey engine. It operates largely independently of the other tasks. When a script needs to query layout information (e.g., an element's size or position), it sends an asynchronous message to the Layout task and waits for a response, rather than blocking the entire pipeline.27  
2. **Layout Task:** This task performs styling and layout. It takes an immutable snapshot of the DOM from the Script task and computes the final positions and sizes of all elements. Critically, both style calculation (using the Stylo engine) and the layout process itself are designed to be parallelized. The output is a "display list"—a simple, sequential description of what needs to be painted.27  
3. **Compositor Task:** This task receives display lists from the Layout task and orchestrates the final rendering. It forwards the display lists to a GPU-based rendering backend (WebRender), which paints the elements into layers and composites them into the final image that appears on screen. The Compositor also receives user input events first, allowing it to handle actions like scrolling immediately for maximum responsiveness, even if the Script or Layout tasks are busy.27

This message-passing architecture avoids the need for complex and error-prone shared-memory synchronization (like locks and mutexes), which is a major source of bugs and performance bottlenecks in traditional multi-threaded C++ applications.28

While Servo as a complete browser replacement did not achieve its ultimate goal, it was a profoundly successful research project that proved the viability of a parallel browser architecture. Its most successful components, the **Stylo** parallel CSS engine and the **WebRender** GPU-based renderer, were so effective that they were successfully extracted and integrated back into Firefox, providing significant performance improvements to millions of users.53 This provides a powerful lesson: building modular, best-in-class components is a viable strategy. A new engine project can de-risk its development by focusing on creating components that are valuable and adoptable in their own right, even if the full engine takes years to mature.

## **Part III: Synthesis and Strategic Recommendations**

The preceding analysis demonstrates that a new browser engine architecture, based on Rust, WebAssembly, and game engine principles, is technically sound. This final part synthesizes these findings to provide a critical evaluation of the 10-40x performance claim and to propose a viable strategic pathway for bringing such an engine to market.

### **Section 7: The 10-40x Performance Claim: A Critical Feasibility Analysis**

The claim of a 10-40x performance improvement is ambitious but plausible. It is not predicated on a single breakthrough but on the multiplicative effect of several synergistic architectural shifts. However, this level of gain will not be universal; it will be concentrated in specific application archetypes that push the boundaries of what is currently possible on the web.

#### **7.1 Synthesizing the Multiplicative Gains**

The overall performance improvement is the product of gains achieved at each layer of the new architecture. The following table maps the identified legacy bottlenecks to their corresponding solutions in the proposed architecture, providing a framework for understanding the source of these gains.

| Identified Bottleneck | Root Cause in Legacy Architecture | Solution in Legacy-Free Architecture | Estimated Performance/Reliability Impact |
| :---- | :---- | :---- | :---- |
| GC Pauses & Jank | Non-deterministic memory reclamation | AOT Compilation & Rust's ownership model | Elimination of pauses (predictable latency) |
| DOM Reflow/Layout Thrashing | Retained-mode object graph for UI | GPU-accelerated immediate-mode rendering with DOD | 10x+ rendering speedup for complex scenes |
| JIT Warm-up & De-optimization | Speculative runtime compilation | AOT compilation to WASM | Deterministic execution speed |
| Data Race Bugs | Unmanaged shared-memory concurrency | Rust's compile-time data race prevention | "Fearless concurrency" |
| C++ Memory Safety Vulnerabilities | Manual memory management | Rust's memory safety guarantees | Elimination of entire bug classes |

A breakdown of the expected performance multipliers is as follows:

* **Language & Runtime (2-5x):** For CPU-bound computational tasks, the combination of Rust's performance and the elimination of GC and JIT overhead can provide a significant speedup. Benchmarks comparing highly optimized JavaScript with WASM often show a 1.5-2x improvement.54 However, for algorithms that are particularly stressful for a garbage collector or that can leverage Rust's control over memory layout (DOD), gains of 5x or more are feasible.34  
* **Rendering Pipeline (2-10x+):** This is the most significant source of potential improvement. For UIs with thousands of dynamic elements, the cost of DOM reflows can dominate the frame budget. A data-oriented, GPU-centric pipeline replaces these expensive CPU-bound calculations with massively parallel GPU operations. The difference can easily be an order of magnitude or more for visually complex applications.20  
* **Parallelism (2-4x):** By effectively distributing the work of layout and other rendering sub-tasks across 4 to 8 CPU cores, a parallel architecture can achieve a near-linear speedup for those tasks compared to the mostly single-threaded approach of legacy engines.27

The final performance gain is the product of these factors. For an application that is heavily bottlenecked by all three—complex client-side logic, a dynamic and complex UI, and work that can be parallelized—the combined effect could plausibly reach the 10-40x range (2×5×2=20x).

#### **7.2 Identifying Target Application Archetypes**

The benefits of this new architecture will not be distributed evenly. For many websites, the primary performance bottleneck is network latency, not runtime execution. The proposed engine is not designed to make static blogs load faster; it is designed to enable a new class of applications.

* **High-Impact Applications:**  
  * **Creative & CAD Tools:** Applications like Figma, Photoshop, or AutoCAD delivered via the web. These tools require both a highly responsive UI and the ability to render and manipulate extremely complex data sets (scene graphs) in real time.  
  * **Real-Time Data Visualization:** High-frequency financial trading dashboards, industrial IoT monitoring systems, and scientific visualization tools that must render thousands or millions of data points per second without lag.55  
  * **High-Fidelity Web Games & Simulations:** Immersive 3D experiences that are currently limited by the performance of WebGL/WebGPU and the overhead of the surrounding JavaScript and DOM environment.57  
  * **Web-based IDEs:** Next-generation code editors that combine a rich UI with computationally intensive backend tasks like real-time compilation, static analysis, and indexing.  
* **Low-Impact Applications:**  
  * **Document-Centric Websites:** News sites, blogs, e-commerce storefronts, and marketing pages. For these use cases, the traditional DOM-based architecture is adequate, and performance is primarily a function of asset optimization and network speed.

To properly validate the performance claims, a new suite of benchmarks must be developed. Existing benchmarks like Speedometer are designed to measure performance on common DOM-centric tasks.7 They are fundamentally tests of how well frameworks have optimized workarounds for the legacy architecture. A new engine requires benchmarks that measure its ability to perform tasks that are currently impossible or impractical on the web, directly reflecting the workloads of the target application archetypes.

### **Section 8: Strategic Pathways and Unavoidable Trade-offs**

Building a new browser engine is one of the most ambitious and difficult undertakings in software engineering. A sound technical architecture is necessary but not sufficient for success. A viable go-to-market strategy is equally critical.

#### **8.1 The Web Compatibility Dilemma**

The single greatest non-technical challenge is **web compatibility**. A truly "legacy-free" engine, by definition, will not support the decades of APIs, quirks, and proprietary extensions that make up the existing web. This leads to a stark strategic choice:

1. **The General-Purpose Browser (High Risk, Likely Failure):** Attempting to build a new browser to compete directly with Chrome, Firefox, and Safari is a path fraught with peril. The project would be saddled with the impossible task of achieving perfect, bug-for-bug compatibility with the Blink-dominated web while simultaneously trying to innovate. This approach would almost certainly fail due to the powerful monoculture feedback loop that favors the incumbent.4  
2. **The Embeddable Engine (Viable Strategy):** A far more pragmatic and promising strategy is to position the new engine not as a "browser," but as a high-performance **runtime for applications**. This engine could be embedded within native application shells, much like the Electron or Tauri frameworks.59 This approach neatly sidesteps the compatibility problem by focusing exclusively on the target application archetypes that need its performance and are willing to build specifically for its new, legacy-free APIs.

#### **8.2 Ecosystem and Tooling: The Hidden Mountain**

An engine is only as useful as the tools and libraries that support it. A new rendering and runtime paradigm requires an entirely new ecosystem to be built from the ground up. This effort should not be underestimated; it is likely an order of magnitude more work than building the engine itself. Key components would include:

* **Developer Tools:** A sophisticated suite of tools, analogous to Chrome DevTools, for debugging, profiling, and inspecting applications running on the new engine.61  
* **UI Framework:** A high-level, declarative UI framework, akin to React or Svelte, that provides an ergonomic abstraction over the engine's low-level, immediate-mode rendering APIs.62  
* **State Management Libraries:** New patterns and libraries for managing application state in a Rust/WASM-centric environment.  
* **Community and Documentation:** A sustained, long-term investment in building a developer community through high-quality documentation, tutorials, and outreach.

The rise of the Tauri framework presents a particularly compelling strategic opportunity. Tauri's architecture separates the application backend (written in Rust) from the frontend (rendered using the operating system's native WebView).59 While this makes Tauri applications vastly more lightweight and efficient than their Electron counterparts, it also means their performance and features are constrained by the capabilities of the underlying system WebView, which can be inconsistent across platforms.64

A new, embeddable engine could be positioned as a "supercharged WebView" for the Tauri ecosystem. It could be offered as a drop-in replacement for the system WebView, providing developers with guaranteed cross-platform rendering consistency and the order-of-magnitude performance gains of the legacy-free architecture. This creates a powerful symbiotic relationship: the new engine gains an immediate and receptive audience of Rust-focused developers, while the Tauri ecosystem gains a solution to its primary architectural limitation. This "Tauri model" represents a viable Trojan horse strategy for introducing a new rendering paradigm to the web ecosystem.

### **Conclusion: The Future of the Browser Engine**

The analysis presented in this report leads to a clear conclusion: achieving a 10-40x performance improvement for the next generation of web applications is architecturally plausible. It requires, however, a departure from the path of incremental optimization and a commitment to a new architecture built on three pillars: the safety and control of Rust, the universality of WebAssembly, and the raw performance of game engine rendering techniques.

The legacy engines that power today's web are the product of immense engineering talent, but they are ultimately constrained by their foundational design. The JIT/GC runtime, the DOM, and the single-threaded processing model are architectural cul-de-sacs that impose a hard ceiling on performance and predictability. A legacy-free engine, by shedding this historical baggage, can offer not just a quantitative leap in speed but a qualitative change in what is possible to build on the web.

However, technical viability does not guarantee success. The strategic challenges, particularly the insurmountable wall of web compatibility, are formidable. Therefore, the primary recommendation of this report is to reject the notion of building a new general-purpose browser. The viable path forward is to create a specialized, embeddable engine—a new runtime for a new class of applications.

By focusing on the needs of developers building creative tools, complex simulations, and high-performance visualizations, and by strategically aligning with growing ecosystems like Tauri, a legacy-free engine can cultivate a market where its unique advantages are not just a luxury but a necessity. The goal should not be to replace Chrome, but to create a new, parallel web platform for the applications of the future that are currently impossible to build. This is a long-term, ambitious vision, but one that is technically sound and strategically achievable.

#### **Works cited**

1. Appendix F: understanding the role of browser engines \- GOV.UK, accessed on July 24, 2025, [https://assets.publishing.service.gov.uk/media/61b86737e90e07043c35f5be/Appendix\_F\_-\_Understanding\_the\_role\_of\_browser\_engines.pdf](https://assets.publishing.service.gov.uk/media/61b86737e90e07043c35f5be/Appendix_F_-_Understanding_the_role_of_browser_engines.pdf)  
2. Battle of the Browsers \- The Blog of Random, accessed on July 24, 2025, [https://blog.zerolimits.dev/posts/browsers](https://blog.zerolimits.dev/posts/browsers)  
3. Developer FAQ \- Why Blink? \- The Chromium Projects, accessed on July 24, 2025, [https://www.chromium.org/blink/developer-faq/](https://www.chromium.org/blink/developer-faq/)  
4. Why Blink and not Gecko? \- Vivaldi Forum, accessed on July 24, 2025, [https://forum.vivaldi.net/topic/958/why-blink-and-not-gecko](https://forum.vivaldi.net/topic/958/why-blink-and-not-gecko)  
5. The Architecture of Web Browsers \- Quastor, accessed on July 24, 2025, [https://blog.quastor.org/p/architecture-web-browsers](https://blog.quastor.org/p/architecture-web-browsers)  
6. Which browser engine is better to use: Webkit or Gecko? \- Quora, accessed on July 24, 2025, [https://www.quora.com/Which-browser-engine-is-better-to-use-Webkit-or-Gecko](https://www.quora.com/Which-browser-engine-is-better-to-use-Webkit-or-Gecko)  
7. Are There Any Objective Performance Differences Between Blink and Gecko? \- Reddit, accessed on July 24, 2025, [https://www.reddit.com/r/browsers/comments/1jbcyy3/are\_there\_any\_objective\_performance\_differences/](https://www.reddit.com/r/browsers/comments/1jbcyy3/are_there_any_objective_performance_differences/)  
8. RenderingNG deep-dive: BlinkNG | Chromium \- Chrome for Developers, accessed on July 24, 2025, [https://developer.chrome.com/docs/chromium/blinkng](https://developer.chrome.com/docs/chromium/blinkng)  
9. RenderingNG deep-dive: LayoutNG | Chromium | Chrome for ..., accessed on July 24, 2025, [https://developer.chrome.com/docs/chromium/layoutng](https://developer.chrome.com/docs/chromium/layoutng)  
10. Embedded JavaScript Engines: Powering Your Applications with V8 and SpiderMonkey, accessed on July 24, 2025, [https://algocademy.com/blog/embedded-javascript-engines-powering-your-applications-with-v8-and-spidermonkey/](https://algocademy.com/blog/embedded-javascript-engines-powering-your-applications-with-v8-and-spidermonkey/)  
11. Deep Dive Into Javascript Engines — Blazingly Fast ⚡️ | by Doğukan Akkaya \- Medium, accessed on July 24, 2025, [https://medium.com/@dogukanakkaya/deep-dive-into-javascript-engines-blazingly-fast-%EF%B8%8F-fc47069e97a4](https://medium.com/@dogukanakkaya/deep-dive-into-javascript-engines-blazingly-fast-%EF%B8%8F-fc47069e97a4)  
12. design choice comparison \- What are the advantages and ..., accessed on July 24, 2025, [https://langdev.stackexchange.com/questions/981/what-are-the-advantages-and-disadvantages-of-just-in-time-compilation](https://langdev.stackexchange.com/questions/981/what-are-the-advantages-and-disadvantages-of-just-in-time-compilation)  
13. Leveraging property access optimization in the V8 JavaScript engine for improved runtime performance \- DiVA portal, accessed on July 24, 2025, [https://www.diva-portal.org/smash/get/diva2:1626575/FULLTEXT01.pdf](https://www.diva-portal.org/smash/get/diva2:1626575/FULLTEXT01.pdf)  
14. FuzzJIT: Oracle-Enhanced Fuzzing for JavaScript Engine JIT Compiler \- USENIX, accessed on July 24, 2025, [https://www.usenix.org/system/files/usenixsecurity23-wang-junjie.pdf](https://www.usenix.org/system/files/usenixsecurity23-wang-junjie.pdf)  
15. What's the benefit of having a garbage collector? \- Reddit, accessed on July 24, 2025, [https://www.reddit.com/r/learnprogramming/comments/17got8l/whats\_the\_benefit\_of\_having\_a\_garbage\_collector/](https://www.reddit.com/r/learnprogramming/comments/17got8l/whats_the_benefit_of_having_a_garbage_collector/)  
16. Does garbage collection affect performance? \- Stack Overflow, accessed on July 24, 2025, [https://stackoverflow.com/questions/25312568/does-garbage-collection-affect-performance](https://stackoverflow.com/questions/25312568/does-garbage-collection-affect-performance)  
17. How JavaScript's Garbage Collection Affects Application Performance \- DEV Community, accessed on July 24, 2025, [https://dev.to/rigalpatel001/how-javascripts-garbage-collection-affects-application-performance-4k6j](https://dev.to/rigalpatel001/how-javascripts-garbage-collection-affects-application-performance-4k6j)  
18. The impact of Garbage Collection. As you probably know Java applications… | by Björn Raupach | Medium, accessed on July 24, 2025, [https://medium.com/@raupach/the-impact-of-garbage-collection-c5c268ebb0ff](https://medium.com/@raupach/the-impact-of-garbage-collection-c5c268ebb0ff)  
19. Garbage Collection and Application Performance \- Dynatrace, accessed on July 24, 2025, [https://www.dynatrace.com/resources/ebooks/javabook/impact-of-garbage-collection-on-performance/](https://www.dynatrace.com/resources/ebooks/javabook/impact-of-garbage-collection-on-performance/)  
20. DOM performance case study \- Arek Nawo, accessed on July 24, 2025, [https://areknawo.com/dom-performance-case-study/](https://areknawo.com/dom-performance-case-study/)  
21. Taming huge collections of DOM nodes | by Hajime Yamasaki Vukelic \- codeburst, accessed on July 24, 2025, [https://codeburst.io/taming-huge-collections-of-dom-nodes-bebafdba332](https://codeburst.io/taming-huge-collections-of-dom-nodes-bebafdba332)  
22. Mastering DOM Manipulation: 10 Essential Tips for Efficient and High-Performance Web Development \- DEV Community, accessed on July 24, 2025, [https://dev.to/wizdomtek/mastering-dom-manipulation-10-essential-tips-for-efficient-and-high-performance-web-development-3mke](https://dev.to/wizdomtek/mastering-dom-manipulation-10-essential-tips-for-efficient-and-high-performance-web-development-3mke)  
23. Whats so wrong with direct DOM manipulation? : r/javascript \- Reddit, accessed on July 24, 2025, [https://www.reddit.com/r/javascript/comments/6btma7/whats\_so\_wrong\_with\_direct\_dom\_manipulation/](https://www.reddit.com/r/javascript/comments/6btma7/whats_so_wrong_with_direct_dom_manipulation/)  
24. Functional JS application from scratch \- part 2 \- virtual DOM \- codewithstyle.info, accessed on July 24, 2025, [https://codewithstyle.info/functional-js-application-scratch-part-2-virtual-dom/](https://codewithstyle.info/functional-js-application-scratch-part-2-virtual-dom/)  
25. Virtual DOM is pure overhead \- Svelte, accessed on July 24, 2025, [https://svelte.dev/blog/virtual-dom-is-pure-overhead](https://svelte.dev/blog/virtual-dom-is-pure-overhead)  
26. Some questions about rolling your own UI, immediate vs retained mode \- Reddit, accessed on July 24, 2025, [https://www.reddit.com/r/gameenginedevs/comments/1ew5djv/some\_questions\_about\_rolling\_your\_own\_ui/](https://www.reddit.com/r/gameenginedevs/comments/1ew5djv/some_questions_about_rolling_your_own_ui/)  
27. Architecture overview\* \- The Servo Book, accessed on July 24, 2025, [https://book.servo.org/architecture/overview.html](https://book.servo.org/architecture/overview.html)  
28. Engineering the Servo Web Browser Engine using Rust \- GitHub, accessed on July 24, 2025, [https://raw.githubusercontent.com/larsbergstrom/papers/master/icse16-servo-preprint.pdf](https://raw.githubusercontent.com/larsbergstrom/papers/master/icse16-servo-preprint.pdf)  
29. Experience Report: Developing the Servo Web Browser Engine using Rust, accessed on July 24, 2025, [https://kmcallister.github.io/papers/2015-servo-experience-report-draft1.pdf](https://kmcallister.github.io/papers/2015-servo-experience-report-draft1.pdf)  
30. What WebAssembly is Not, accessed on July 24, 2025, [https://learn-wasm.dev/tutorial/introduction/what-webassembly-is-not](https://learn-wasm.dev/tutorial/introduction/what-webassembly-is-not)  
31. WebAssembly concepts \- MDN Web Docs, accessed on July 24, 2025, [https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Concepts](https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Concepts)  
32. “Near-Native Performance”: Wasm is often described as having ..., accessed on July 24, 2025, [https://news.ycombinator.com/item?id=30156437](https://news.ycombinator.com/item?id=30156437)  
33. Zaplib post-mortem : r/rust \- Reddit, accessed on July 24, 2025, [https://www.reddit.com/r/rust/comments/ufcvk3/zaplib\_postmortem/](https://www.reddit.com/r/rust/comments/ufcvk3/zaplib_postmortem/)  
34. Zaplib post-mortem \- Zaplib docs, accessed on July 24, 2025, [https://zaplib.com/docs/blog\_post\_mortem.html](https://zaplib.com/docs/blog_post_mortem.html)  
35. Why can't browser fully render the DOM many times per second like game-engines do, without struggling with performance? \- Stack Overflow, accessed on July 24, 2025, [https://stackoverflow.com/questions/64065388/why-cant-browser-fully-render-the-dom-many-times-per-second-like-game-engines-d](https://stackoverflow.com/questions/64065388/why-cant-browser-fully-render-the-dom-many-times-per-second-like-game-engines-d)  
36. I think that eventually we might ditch DOM and use WebGL or canvas or something \- Hacker News, accessed on July 24, 2025, [https://news.ycombinator.com/item?id=9071465](https://news.ycombinator.com/item?id=9071465)  
37. Engine Architecture, accessed on July 24, 2025, [https://isetta.io/blogs/engine-architecture/](https://isetta.io/blogs/engine-architecture/)  
38. Building a JavaScript-Based Game Engine for the Web \- UI Talks, accessed on July 24, 2025, [https://talks.ui-patterns.com/videos/building-a-javascript-based-game-engine-for-the-web](https://talks.ui-patterns.com/videos/building-a-javascript-based-game-engine-for-the-web)  
39. The WebGPU Advantage: Faster, Smoother Graphics for Cross-Platform Game Development \- BairesDev, accessed on July 24, 2025, [https://www.bairesdev.com/blog/webgpu-game-development/](https://www.bairesdev.com/blog/webgpu-game-development/)  
40. What you can do with WebGPU? By Corentin Wallez, François Beaufort \- YouTube, accessed on July 24, 2025, [https://www.youtube.com/watch?v=RR4FZ9L4AF4](https://www.youtube.com/watch?v=RR4FZ9L4AF4)  
41. Immediate mode (computer graphics) \- Wikipedia, accessed on July 24, 2025, [https://en.wikipedia.org/wiki/Immediate\_mode\_(computer\_graphics)](https://en.wikipedia.org/wiki/Immediate_mode_\(computer_graphics\))  
42. Immediate UI vs Retained UI \- Collin Quinn's Portfolio \- GitLab, accessed on July 24, 2025, [https://collquinn.gitlab.io/portfolio/my-article.html](https://collquinn.gitlab.io/portfolio/my-article.html)  
43. Immediate GUI \- yae or nay? \[closed\] \- Game Development Stack Exchange, accessed on July 24, 2025, [https://gamedev.stackexchange.com/questions/24103/immediate-gui-yae-or-nay](https://gamedev.stackexchange.com/questions/24103/immediate-gui-yae-or-nay)  
44. Revolutionize Your Code: The Magic of Data-oriented Design (DOD ..., accessed on July 24, 2025, [https://www.orientsoftware.com/blog/dod-programming/](https://www.orientsoftware.com/blog/dod-programming/)  
45. Qt Quick Scene Graph \- Qt Documentation, accessed on July 24, 2025, [https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html)  
46. Scene Graph, just a question. : r/gamedev \- Reddit, accessed on July 24, 2025, [https://www.reddit.com/r/gamedev/comments/5exges/scene\_graph\_just\_a\_question/](https://www.reddit.com/r/gamedev/comments/5exges/scene_graph_just_a_question/)  
47. Scene Graph \- PixiJS, accessed on July 24, 2025, [https://pixijs.com/8.x/guides/concepts/scene-graph](https://pixijs.com/8.x/guides/concepts/scene-graph)  
48. Qt Quick Scene Graph Default Renderer \- Qt Documentation, accessed on July 24, 2025, [https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph-renderer.html](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph-renderer.html)  
49. Rolling my own scene graph \- Game Development Stack Exchange, accessed on July 24, 2025, [https://gamedev.stackexchange.com/questions/46452/rolling-my-own-scene-graph](https://gamedev.stackexchange.com/questions/46452/rolling-my-own-scene-graph)  
50. What is a GPU? The Engine Behind AI Acceleration | DigitalOcean, accessed on July 24, 2025, [https://www.digitalocean.com/resources/articles/what-is-gpu](https://www.digitalocean.com/resources/articles/what-is-gpu)  
51. What is GPU Parallel Computing? | OpenMetal IaaS, accessed on July 24, 2025, [https://openmetal.io/docs/product-guides/private-cloud/gpu-parallel-computing/](https://openmetal.io/docs/product-guides/private-cloud/gpu-parallel-computing/)  
52. Servo Architecture: Safety and Performance \- YouTube, accessed on July 24, 2025, [https://www.youtube.com/watch?v=an5abNFba4Q](https://www.youtube.com/watch?v=an5abNFba4Q)  
53. a web rendering engine for the future \- Servo, accessed on July 24, 2025, [https://servo.org/slides/2024-07-02-global-software-technology-summit/?print-pdf](https://servo.org/slides/2024-07-02-global-software-technology-summit/?print-pdf)  
54. Upcoming (serious) Web performance boost \- Godot Engine, accessed on July 24, 2025, [https://godotengine.org/article/upcoming-serious-web-performance-boost/](https://godotengine.org/article/upcoming-serious-web-performance-boost/)  
55. Performance Bottlenecks in Web Apps – How to Identify Them \- Blog \- Testriq, accessed on July 24, 2025, [https://testriq.com/blog/post/performance-bottlenecks-in-web-apps-how-to-identify-them](https://testriq.com/blog/post/performance-bottlenecks-in-web-apps-how-to-identify-them)  
56. What are the challenges of real-time data streaming? \- Milvus, accessed on July 24, 2025, [https://milvus.io/ai-quick-reference/what-are-the-challenges-of-realtime-data-streaming](https://milvus.io/ai-quick-reference/what-are-the-challenges-of-realtime-data-streaming)  
57. WebGL in Mobile Development: Challenges and Solutions \- PixelFreeStudio Blog, accessed on July 24, 2025, [https://blog.pixelfreestudio.com/webgl-in-mobile-development-challenges-and-solutions/](https://blog.pixelfreestudio.com/webgl-in-mobile-development-challenges-and-solutions/)  
58. 4 Limitations of WebGL for Publishing Real-Time 3D \- PureWeb, accessed on July 24, 2025, [https://www.pureweb.com/news-updates/4-limitations-of-webgl-for-publishing-real-time-3d/](https://www.pureweb.com/news-updates/4-limitations-of-webgl-for-publishing-real-time-3d/)  
59. Tauri vs. Electron: The Ultimate Desktop Framework Comparison, accessed on July 24, 2025, [https://peerlist.io/jagss/articles/tauri-vs-electron-a-deep-technical-comparison](https://peerlist.io/jagss/articles/tauri-vs-electron-a-deep-technical-comparison)  
60. Tauri vs. Electron: A Technical Comparison \- DEV Community, accessed on July 24, 2025, [https://dev.to/vorillaz/tauri-vs-electron-a-technical-comparison-5f37](https://dev.to/vorillaz/tauri-vs-electron-a-technical-comparison-5f37)  
61. Performance features reference | Chrome DevTools, accessed on July 24, 2025, [https://developer.chrome.com/docs/devtools/performance/reference](https://developer.chrome.com/docs/devtools/performance/reference)  
62. Building an app? These are the best JavaScript frameworks in 2025 \- Contentful, accessed on July 24, 2025, [https://www.contentful.com/blog/best-javascript-frameworks/](https://www.contentful.com/blog/best-javascript-frameworks/)  
63. Stop Chasing New JavaScript Frameworks: Build with Fundamentals Instead 🏗️, accessed on July 24, 2025, [https://dev.to/mattlewandowski93/stop-chasing-new-javascript-frameworks-build-with-fundamentals-instead-1lni](https://dev.to/mattlewandowski93/stop-chasing-new-javascript-frameworks-build-with-fundamentals-instead-1lni)  
64. Tauri VS. Electron \- Real world application, accessed on July 24, 2025, [https://www.levminer.com/blog/tauri-vs-electron](https://www.levminer.com/blog/tauri-vs-electron)