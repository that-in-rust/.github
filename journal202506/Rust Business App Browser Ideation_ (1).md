

# **Project Alchemize: A Blueprint for a Post-Web, Rust-Native UI Framework**

### **Part I: The Vision \- A New Paradigm for Business Applications**

The contemporary landscape of application development is dominated by technologies born from the web. While frameworks built on HTML, CSS, and JavaScript have enabled unprecedented reach, they carry with them decades of architectural compromises. These legacy constraints impose a fundamental ceiling on performance, security, and predictability, particularly for the demanding domain of modern business applications. This document presents the architectural blueprint for *Project Alchemize*, a ground-up reimagining of the UI stack. It proposes a self-contained, high-performance ecosystem built entirely in Rust, designed to transcend the limitations of the web by providing a new foundation for building the next generation of secure, reliable, and efficient business software.

#### **Section 1: The Lexicon of Magic**

A robust technical foundation is necessary but not sufficient for a new ecosystem to thrive. A strong, cohesive identity is paramount for fostering community engagement and differentiating the project in a crowded marketplace. Drawing inspiration from the rich and evocative world of *Harry Potter*, the Alchemize ecosystem adopts a thematic lexicon. This is not a superficial branding exercise; each name is carefully chosen to reflect the core architectural principles and philosophical goals of its corresponding component. The objective is to create what one thematically similar project, potterscript, calls an "enchanting programming experience"—one that is both immensely powerful and intuitively understandable.1 The following table establishes this lexicon, providing a consistent vocabulary for the entire project.

| Component | Proposed Name | Harry Potter Origin & Justification |
| :---- | :---- | :---- |
| **The Framework** | Alchemize | Alchemy is the magical art of transmutation. This name is justified by the framework's core function: to transmute declarative Rust code into a high-performance, pixel-perfect user interface, a transformation that appears almost magical to developers accustomed to the complexities of web technologies. |
| **The DSL** | Parseltongue | The rare language of serpents, understood by few but immensely powerful. This name reflects the DSL's nature as a specialized, potent language that "speaks directly to the metal" of the rendering engine, bypassing the "common tongue" of HTML/CSS/JS. The association of powerful, niche languages with Parseltongue is a recurring theme in developer communities.2 |
| **The Native Runtime** | The Pensieve | A magical basin used to store and review memories. This name is justified by the native runtime's advanced debugging capabilities, which will allow developers to inspect the "memory" of the application's state and rendering history frame-by-frame, providing unparalleled insight into application behavior. |
| **The Compiler** | The Horcrux Compiler | An object in which a wizard has concealed a fragment of their soul for protection. Architecturally, each UI component is compiled into a self-contained, cryptographically verifiable "shard." The final application is an assembly of these trusted shards, creating a security model where components are isolated by design, greatly enhancing the application's resilience. |
| **The CLI Tool** | accio | The Summoning Charm. This name is functionally descriptive; the command-line interface is used to "summon" new projects, components, and build artifacts (e.g., accio new my\_app). It is a common and intuitive naming convention for project scaffolding tools. |
| **Component Registry** | Diagon Alley | The central wizarding marketplace in London. This name establishes the official component registry as the trusted, central hub for the community to share, discover, and acquire third-party Alchemize components, fostering a vibrant ecosystem. |

#### **Section 2: The Parselmouth DSL: A Declarative Rust Experience**

The developer's primary interface with the Alchemize framework is Parseltongue, a Domain-Specific Language (DSL) designed to provide the ergonomic, declarative experience of modern UI frameworks like React, but with the full power and safety of native Rust. This is achieved not by interpreting a new language at runtime, but through a sophisticated compile-time code generation system.

The power of Parseltongue lies in its implementation using Rust's **procedural macros**.3 Procedural macros are a feature of the Rust compiler that allows developers to write code that operates on other code at compile time.5 When a developer writes UI code within a

parsel\! macro block, the Rust compiler invokes the Alchemize macro processor. This processor parses the custom, JSX-like syntax and transforms it directly into highly optimized, imperative Rust code that interacts with the rendering engine.6 This approach offers the best of both worlds: a clean, declarative syntax for the developer and a zero-overhead, pre-compiled render function for the machine.

The component model will feel familiar to developers with experience in frameworks like React or Yew.7 Below is a conceptual comparison of a simple component.

* **React JSX Example:**  
  JavaScript  
  function LoginComponent({ username, setUsername, onLogin }) {  
    return (  
      \<div\>  
        \<label\>Username:\</label\>  
        \<input value\={username} onChange\={e \=\> setUsername(e.target.value)} /\>  
        \<button onClick\={onLogin}\>Log In\</button\>  
      \</div\>  
    );  
  }

* **Parseltongue DSL Example:**  
  Rust  
  // Assumes component state is managed in a parent struct  
  parsel\! {  
      Window(title: "Login") {  
          VStack(spacing: 8) {  
              Text(value: "Username:")  
              TextInput(bind: self.username)  
              Button(on\_press: self.handle\_login) {  
                  Text(value: "Log In")  
              }  
          }  
      }  
  }

A pivotal architectural decision in Alchemize is its approach to state management. Frameworks like React were designed for JavaScript, a language with a garbage collector. Their state management patterns and hook systems are built around this assumption. Alchemize, being pure Rust, must manage state without a garbage collector and the associated non-deterministic performance pauses.8 It achieves this by leveraging Rust's core principles of ownership and borrowing. State is not a free-floating entity; it is owned data within a component's

struct. When an event handler mutates this state, the framework triggers a re-render of only the affected component and its children. The Rust compiler, at compile time, statically guarantees that all access to this state is free of data races and memory safety violations, providing a level of reliability that is difficult to achieve in garbage-collected languages.

This compile-time approach yields a fundamental performance advantage. The modern web UI stack is architecturally inverted: it uses a low-level, retained-mode graphics system (the DOM) and builds a high-level, immediate-mode abstraction (the Virtual DOM) on top of it in a dynamic language.8 This VDOM exists purely to calculate the difference between two states at runtime and then generate the minimal set of imperative commands to patch the DOM. This entire diffing process is, as the creator of Svelte noted, "pure overhead".9

Alchemize corrects this inversion. Because it has no DOM to interact with, it has no need for a VDOM. The parsel\! macro does not generate a data structure to be diffed at runtime. Instead, the procedural macro acts as a compile-time renderer. It analyzes the declarative component tree and generates the specific, imperative Rust code that will directly manipulate the rendering engine's command buffer. The "diffing" is effectively handled by the framework's reactive state model and Rust's own compilation process. This means the translation from declarative UI to optimized drawing commands happens once, at compile time, resulting in a render function with zero runtime interpretation overhead.

### **Part II: The Engine of Sorcery \- The CPU-Only Rendering Architecture**

The technical core of Project Alchemize is its from-scratch rendering engine. This engine is defined by two critical constraints: it must be written in pure Rust with no GPU dependency, and it must support compilation to both native desktop binaries and WebAssembly modules for in-browser execution. This section details the architecture that makes this possible, with a deep focus on the two most complex sub-problems: 2D graphics and text rendering.

#### **Section 3: The Canvas as a Portkey: Dual-Target Rendering**

A single Alchemize application codebase is designed to be compiled for two distinct environments, enabling broad deployment without compromising the core architecture.

The primary target is a native desktop application, executed by **The Pensieve** runtime. For this target, the application is compiled into a standard executable binary. The runtime will leverage a mature, cross-platform windowing library to create and manage the application window on the host operating system. The ideal choice for this is winit, a pure-Rust library that provides the necessary low-level abstractions for window creation and event handling across Windows, macOS, and Linux.10 The

Alchemize rendering engine will then draw its pixel buffer directly into the memory region provided by the winit window, ensuring maximum performance and seamless integration with the native desktop environment.

The secondary target enables Alchemize applications to run within any modern web browser. This is achieved by compiling the entire Rust application into a **WebAssembly (WASM)** module. To display the UI, a minimal JavaScript "shim" is used. This shim's sole responsibilities are to load the WASM module and provide it with a reference to an HTML \<canvas\> element on the page.11 From the perspective of the Rust code, this canvas is treated as a simple, raw pixel buffer (a framebuffer). At the end of each render cycle, the completed pixel data is passed from WASM to the JavaScript shim, which uses the

putImageData API to blit the frame onto the canvas. While WASM execution itself is highly performant, the function calls across the boundary between JavaScript and WASM introduce significant overhead.14 This "FFI tax" is a primary architectural constraint that must be actively managed. User input events, such as mouse clicks and keyboard presses, are captured by the browser's standard JavaScript event loop. These events must then be efficiently marshaled and passed into the WASM module, where they are processed by the

Alchemize framework's internal event system.

The performance characteristics of the JS-WASM bridge, combined with lessons from other modern systems like the AccessKit accessibility framework 17, lead to a unified architectural pattern for the entire engine: a

**unidirectional data push** model. To minimize costly cross-boundary communication, the core application logic, running entirely within Rust/WASM, must be the single source of truth. It should never block or wait for a synchronous response from the "platform" (be it the browser's JavaScript environment or the native OS). Instead, the platform's role is to feed a stream of raw input events *into* the Alchemize core. The core processes these events in its own event loop, updates its internal state, and, at the end of a frame, *pushes* complete, self-contained data artifacts—such as a pixel buffer for rendering or an accessibility tree—*out* to the platform for final presentation. This asynchronous, push-based model avoids blocking, simplifies state management, and is the most performant design for both native and WASM targets.

#### **Section 4: The Rendering Engine: A Pure-CPU 2D Graphics Pipeline**

At the heart of Alchemize is a custom 2D rendering pipeline, built from the ground up in pure Rust and designed exclusively for CPU execution. This deliberate choice avoids the complexity and platform variance of GPU drivers, ensuring that Alchemize applications are portable, predictable, and can run on a wide range of hardware, including low-power devices without dedicated graphics processors.

The existence of the tiny-skia library is a powerful proof-of-concept for this entire endeavor. tiny-skia is a pure-Rust port of a subset of Google's Skia, the industry-standard 2D graphics library used in Chrome and Android.18 It provides a high-quality, performant, CPU-only 2D rasterizer that is small, easy to compile, and produces pixel-perfect results identical to its parent library.18 Its API is low-level, offering the fundamental primitives—paths, fills, strokes, and gradients—necessary to build a sophisticated, higher-level rendering engine.19

The Alchemize rendering pipeline, built atop tiny-skia, will consist of several distinct stages:

1. **Layout Engine:** The framework will implement its own layout engine to position components. For the target domain of business applications, a simplified, Rust-native implementation of the **Flexbox** constraint-based model is the most suitable choice. This engine will traverse the component tree and calculate the final size and position of every UI element.  
2. **Culling and Layering:** Before any drawing occurs, the engine will perform view-frustum culling to discard any elements that fall outside the visible area of the window. It will also manage a layering system, analogous to z-index, to ensure elements are drawn in the correct order.  
3. **Command Buffer Generation:** The processed component tree is then translated into a linear list of drawing commands. This command buffer is an intermediate representation, containing simple instructions like DrawRect, DrawPath, and DrawText, along with their associated parameters (coordinates, colors, etc.).  
4. **Rasterization:** The command buffer is consumed by the rasterizer module. This module, powered by tiny-skia, iterates through the command list and draws the corresponding pixels into an in-memory framebuffer.  
5. **Presentation:** Finally, the completed framebuffer is "presented" to the screen. In the native Pensieve runtime, this involves blitting the pixel data to the winit window. In the WASM target, it involves pushing the data to the JavaScript shim to be drawn onto the HTML canvas.

During the architectural analysis of this pipeline, a critical challenge emerged. The documentation for tiny-skia makes it explicit that **text rendering is out of scope**.18 This is not a minor omission; it is a reflection of the immense complexity of the task. The issue tracker for

tiny-skia details the necessary components for a complete text solution: a font parser, a text shaping engine, a font database with fallback mechanisms, and a high-quality glyph rasterizer.21 This discovery reveals that

Alchemize cannot simply *use* a single library for rendering. It must architect and build a complete, multi-stage text rendering subsystem by integrating several specialized, independent Rust crates. This represents the single greatest technical risk and engineering effort within the entire project and demands a dedicated architectural solution.

#### **Section 5: The Quill of a Thousand Scribes: The Text Rendering Subsystem**

To address the critical need for text rendering, the Alchemize engine will incorporate a sophisticated, multi-stage subsystem. This subsystem is responsible for the entire journey from a string of characters to correctly shaped and rendered pixels on the screen. The pipeline is composed of three distinct pillars, each handled by a carefully selected, best-in-class Rust library.

The three pillars of the text rendering pipeline are:

1. **Font Parsing & Management:** This stage involves loading font files (e.g., .ttf, .otf) from memory, parsing their binary structure, and providing access to their internal tables, such as glyph maps and metrics.  
2. **Text Shaping:** This is the complex process of converting a sequence of Unicode characters into a correctly positioned sequence of glyphs. This includes handling ligatures (e.g., 'f' \+ 'i' → 'ﬁ'), kerning (adjusting space between specific character pairs), and laying out complex scripts that require reordering or contextual forms, such as Arabic or Devanagari.  
3. **Glyph Rasterization & Caching:** This final stage takes the vector outline of a single glyph, as determined by the shaper, and converts it into a bitmap of pixels that can be drawn to the screen. These bitmaps are typically cached in a "glyph atlas" (a single large texture) for performance.

The Rust ecosystem for text rendering is fragmented, with several libraries specializing in different parts of this pipeline.22 A careful selection process is required to build a cohesive and high-quality system. The following table outlines the chosen libraries for the

Alchemize text stack, based on a comparative analysis of their features, maturity, and architectural fit.

| Stage | Primary Candidate | Secondary Candidate | Rationale for Selection | Snippet Evidence |
| :---- | :---- | :---- | :---- | :---- |
| **Font Parsing** | allsorts | fontdue | allsorts is a production-grade library that provides comprehensive support for OpenType, WOFF, and WOFF2 formats, including modern features like variable fonts. Its active development and use in the Prince XML engine demonstrate its robustness, making it the superior choice for a professional-grade framework. | 25 |
| **Text Shaping** | rustybuzz | allsorts | rustybuzz is a pure-Rust port of HarfBuzz, the industry gold standard for text shaping used in Chrome, Android, and GNOME. Its high level of conformance with HarfBuzz ensures the highest quality layout for international and complex scripts, a non-negotiable feature for business applications. | 28 |
| **Glyph Rasterization** | ab\_glyph | fontdue | ab\_glyph is a high-performance rewrite of the older rusttype library, focusing specifically on fast glyph rasterization. Its focused API and superior performance for both .ttf and .otf fonts make it an ideal final stage for our pipeline, where speed is critical. | 31 |

These three libraries will be integrated to form a complete text rendering pipeline within the Alchemize engine. The process for rendering a string of text will be as follows: First, allsorts will be used to load the required font file and parse its data. Second, the application's text string and the parsed font object will be passed to rustybuzz. rustybuzz will perform the shaping operation, returning a vector of glyph identifiers along with their precise x and y positions. Finally, the engine will iterate through this list of positioned glyphs. For each glyph, it will call upon ab\_glyph to rasterize its vector outline into a pixel bitmap. These bitmaps will be cached in a glyph atlas to avoid re-rasterizing common characters, and then drawn into the main application framebuffer by the tiny-skia rendering backend.

### **Part III: The Ministry of Magic \- Ecosystem, Tooling, and Governance**

A successful framework is more than just its core engine; it is a complete ecosystem that empowers developers. This final part of the blueprint addresses the critical non-functional requirements and strategic considerations necessary for Project Alchemize to achieve viability and adoption. This includes a robust solution for accessibility, a clear positioning within the existing market, and a suite of powerful developer tools.

#### **Section 6: The Marauder's Map of Accessibility**

Accessibility is a foundational, non-negotiable requirement for any modern UI framework, and it is especially critical in the context of business applications, which are often subject to legal and corporate accessibility mandates. By design, Alchemize bypasses the entire browser rendering stack, including the Document Object Model (DOM). Since the DOM is the primary data source for assistive technologies like screen readers, this architectural choice renders Alchemize applications completely inaccessible by default. This challenge cannot be an afterthought; it must be solved at the deepest architectural level.

The definitive solution for this self-imposed problem is the direct integration of the **AccessKit** library.17

AccessKit is a pure-Rust accessibility infrastructure designed specifically for the use case of UI toolkits that perform their own rendering, such as GUI frameworks drawing to a canvas or a native window. Its architecture is a perfect match for Alchemize.

The integration will work as follows: the Alchemize framework will act as an AccessKit "provider." As it builds the UI component tree, it will simultaneously construct a parallel tree of accessibility nodes. This tree mirrors the semantic structure of the UI—describing roles (button, label, text input), names, values, and states. This accessibility tree is then pushed to the AccessKit platform adapter. AccessKit provides adapters for all major desktop platforms (Windows, macOS, and Linux), which handle the complex, platform-specific task of translating this abstract accessibility tree into the native APIs that screen readers and other assistive technologies consume.17

To make this seamless for developers, accessibility properties will be a first-class part of the Parseltongue DSL. This ensures that accessibility is not an opt-in feature but an integral part of component design.

Rust

parsel\! {  
    Button(  
        on\_press: self.handle\_login,  
        // Accessibility properties are integrated directly into the DSL  
        access\_role: "button",  
        access\_label: "Log in to your account"  
    ) {  
        Text(value: "Log In")  
    }  
}

The Horcrux Compiler will parse these access\_\* attributes and use them to populate the AccessKit node tree during UI compilation, ensuring that what the user sees is perfectly synchronized with what the assistive technology understands.

#### **Section 7: A Comparative Analysis of Magical Arts**

To succeed, Alchemize must have a clearly defined value proposition and occupy a unique niche within the growing Rust GUI ecosystem. It is not intended to be a general-purpose replacement for all other frameworks but a specialized tool for a specific set of problems. The following analysis compares Alchemize to the most prominent existing frameworks to highlight its strategic positioning.

| Feature | Alchemize (Proposed) | Tauri | Iced | egui |
| :---- | :---- | :---- | :---- | :---- |
| **Core Paradigm** | Declarative, Retained Mode | Webview (HTML/CSS/JS) | Reactive (Elm-inspired) | Immediate Mode |
| **Rendering** | Pure CPU (via tiny-skia) | OS Webview (Blink/WebKit) | GPU (wgpu) | GPU (OpenGL/WebGL) |
| **Dependencies** | Pure Rust \+ winit | OS Webview, JS Frontend | wgpu, winit | glow, winit |
| **Security Model** | Strong (Rust \+ no JS) | Weaker (JS surface) | Strong (Rust) | Strong (Rust) |
| **Accessibility** | Excellent (via AccessKit) | Good (via Webview) | In-progress | In-progress |
| **Best For** | Secure, predictable business apps | Leveraging web skills for desktop | Data-centric, reactive apps | Fast, simple tools & debug UIs |
| **Snippet Evidence** | (This Report) | 23 | 23 | 23 |

This comparison reveals the core trade-offs. **Tauri** 23 offers the lowest barrier to entry for web developers by leveraging the existing web ecosystem, but it inherits the performance, memory usage, and security surface of a full web browser.

**Iced** and **egui** 23 are pure-Rust, GPU-accelerated frameworks that are excellent for their respective reactive and immediate-mode paradigms but are still evolving their accessibility and widget stories.

Alchemize differentiates itself by making a different set of trade-offs. It intentionally sacrifices the ease of using web technologies to gain unparalleled security, predictability, and performance within its niche. Its pure-CPU rendering ensures it runs everywhere, and its foundational integration with AccessKit aims to provide best-in-class accessibility, a critical feature for its target market of enterprise and business applications.

#### **Section 8: The Room of Requirement: Developer Tooling**

A powerful framework is rendered useless by a poor developer experience. To ensure Alchemize is not just powerful but also productive, a suite of dedicated tooling is a mandatory part of the ecosystem.

* **The Pensieve Debugger:** Fulfilling the promise of its name, the native Pensieve runtime will include a sophisticated, built-in UI inspector and debugger. This is not an external tool but an integrated part of the runtime itself. It will provide developers with a "Marauder's Map" of their running application, allowing them to:  
  * Visually inspect the component hierarchy and its relationship to the rendered output.  
  * Select any component on screen and view its current state, properties, and computed layout.  
  * Visualize layout boundaries, padding, and rendering layers to debug visual issues.  
  * Most powerfully, it will feature a state-history scrubber, allowing a developer to move backward and forward in time through state changes, observing how the UI reacts. This provides an unprecedented level of insight into the application's lifecycle.  
* **Hot Reloading:** A fast, iterative development cycle is essential for UI engineering. The Alchemize toolchain will include a hot-reloading server. A file-watching process will monitor the project's source code. When a change is detected, it will trigger a fast, incremental recompile of only the affected component "shard" and its dependencies. This newly compiled code will then be dynamically injected into the running Pensieve application, updating the UI in place without requiring a full application restart.  
* **The accio CLI:** A powerful and intuitive command-line interface is the entry point for most developer workflows. The accio tool will streamline project management with a set of simple commands:  
  * accio new my-app: Scaffolds a new, complete Alchemize application with a default project structure.  
  * accio build \--target native: Compiles the project into a release-ready native binary for the host platform.  
  * accio build \--target wasm: Compiles the project into a WASM module and generates the necessary JavaScript shim for web deployment.  
  * accio serve: Launches a local development server that runs the Pensieve runtime and enables the hot-reloading functionality.

### **Conclusion: A Phased Roadmap to a New Reality**

Project Alchemize represents an ambitious but architecturally sound vision for the future of business application development. By deliberately shedding the historical baggage of the web stack, it offers a new paradigm focused on three core tenets: performance, security, and predictability. Its pure-Rust foundation, CPU-only rendering pipeline, and compile-time DSL provide a level of control and reliability that is unattainable with traditional web technologies. While the engineering challenges, particularly in creating a complete text rendering subsystem, are significant, they are solvable with the mature and growing Rust ecosystem.

The path to realizing this vision must be pragmatic and phased. A successful implementation should follow a structured roadmap:

* **Phase 1: The Core Engine (MVP):** The initial focus must be on the foundational technology. This phase involves building the Parseltongue DSL compiler using procedural macros and implementing the core CPU rendering pipeline on top of tiny-skia. The top priority within this phase is the successful integration of the text rendering subsystem (allsorts, rustybuzz, ab\_glyph). The initial target will be a native winit-based application only.  
* **Phase 2: The Browser Portkey and Accessibility:** With the core engine stable, the next phase is to expand the platform support. This involves developing the WASM compilation target, creating the minimal JavaScript/Canvas bridge, and ensuring performant data marshaling. In parallel, the AccessKit library will be integrated to provide a robust, cross-platform accessibility foundation.  
* **Phase 3: The Ecosystem:** The final phase focuses on developer experience. This includes building the Pensieve debugger and its UI inspector, implementing the accio CLI with its full feature set, enabling the hot-reloading development server, and establishing the Diagon Alley public component registry to begin fostering a community.

The goal of Alchemize is not to replace the web, but to provide a superior alternative for a specific, high-value class of applications where the trade-offs of the web are no longer acceptable. It is a long-term vision, but one that is technically sound, strategically positioned, and capable of creating a new and valuable reality for application developers.

#### **Works cited**

1. fmiras/potterscript: The Wizarding World Programming ... \- GitHub, accessed on July 25, 2025, [https://github.com/fmiras/potterscript](https://github.com/fmiras/potterscript)  
2. If programming languages were Harry Potter characters | Hacker News, accessed on July 24, 2025, [https://news.ycombinator.com/item?id=9150853](https://news.ycombinator.com/item?id=9150853)  
3. DSL (Domain Specific Languages) \- Rust By Example, accessed on July 24, 2025, [https://doc.rust-lang.org/rust-by-example/macros/dsl.html](https://doc.rust-lang.org/rust-by-example/macros/dsl.html)  
4. A gentle introduction to procedural macros \- Sam Van Overmeire | EuroRust 2024, accessed on July 24, 2025, [https://www.youtube.com/watch?v=02vpyrR1hqk](https://www.youtube.com/watch?v=02vpyrR1hqk)  
5. Guide to Rust procedural macros | developerlife.com, accessed on July 25, 2025, [https://developerlife.com/2022/03/30/rust-proc-macro/](https://developerlife.com/2022/03/30/rust-proc-macro/)  
6. What is the state of the art for creating domain-specific languages (DSLs) with Rust? \- Reddit, accessed on July 24, 2025, [https://www.reddit.com/r/rust/comments/14f5zzj/what\_is\_the\_state\_of\_the\_art\_for\_creating/](https://www.reddit.com/r/rust/comments/14f5zzj/what_is_the_state_of_the_art_for_creating/)  
7. yewstack/yew: Rust / Wasm framework for creating reliable and efficient web applications \- GitHub, accessed on July 24, 2025, [https://github.com/yewstack/yew](https://github.com/yewstack/yew)  
8. Browser202507p1.txt  
9. native\_windows\_gui \- Rust \- Docs.rs, accessed on July 24, 2025, [https://docs.rs/native-windows-gui](https://docs.rs/native-windows-gui)  
10. rust-windowing/winit: Window handling library in pure Rust \- GitHub, accessed on July 25, 2025, [https://github.com/rust-windowing/winit](https://github.com/rust-windowing/winit)  
11. Tiny rendering engine (WASM \+ canvas) \- code review \- The Rust ..., accessed on July 25, 2025, [https://users.rust-lang.org/t/tiny-rendering-engine-wasm-canvas/129402](https://users.rust-lang.org/t/tiny-rendering-engine-wasm-canvas/129402)  
12. Render WASM Graphics to Custom HTML Canvas \- Stack Overflow, accessed on July 24, 2025, [https://stackoverflow.com/questions/75432139/render-wasm-graphics-to-custom-html-canvas](https://stackoverflow.com/questions/75432139/render-wasm-graphics-to-custom-html-canvas)  
13. Reactive Canvas with Rust/WebAssembly and web-sys \- DEV Community, accessed on July 24, 2025, [https://dev.to/deciduously/reactive-canvas-with-rust-webassembly-and-web-sys-2hg2](https://dev.to/deciduously/reactive-canvas-with-rust-webassembly-and-web-sys-2hg2)  
14. WebAssembly: The Bridge Between High-Performance and Web Development \- Medium, accessed on July 24, 2025, [https://medium.com/@trek007/webassembly-the-bridge-between-high-performance-and-web-development-18b0f3dea321](https://medium.com/@trek007/webassembly-the-bridge-between-high-performance-and-web-development-18b0f3dea321)  
15. “Near-Native Performance”: Wasm is often described as having “near-native perf... | Hacker News, accessed on July 24, 2025, [https://news.ycombinator.com/item?id=30156437](https://news.ycombinator.com/item?id=30156437)  
16. WebAssembly vs JavaScript: Which is Better in 2025? \- GraffersID, accessed on July 24, 2025, [https://graffersid.com/webassembly-vs-javascript/](https://graffersid.com/webassembly-vs-javascript/)  
17. AccessKit/accesskit: Accessibility infrastructure for UI toolkits \- GitHub, accessed on July 25, 2025, [https://github.com/AccessKit/accesskit](https://github.com/AccessKit/accesskit)  
18. A tiny Skia subset ported to Rust \- GitHub, accessed on July 25, 2025, [https://github.com/linebender/tiny-skia](https://github.com/linebender/tiny-skia)  
19. tiny\_skia \- Rust \- Docs.rs, accessed on July 24, 2025, [https://docs.rs/tiny-skia/](https://docs.rs/tiny-skia/)  
20. tiny-skia \- crates.io: Rust Package Registry, accessed on July 25, 2025, [https://crates.io/crates/tiny-skia/0.6.4](https://crates.io/crates/tiny-skia/0.6.4)  
21. Issue \#1 · linebender/tiny-skia \- Text rendering \- GitHub, accessed on July 25, 2025, [https://github.com/RazrFalcon/tiny-skia/issues/1](https://github.com/RazrFalcon/tiny-skia/issues/1)  
22. Text Rendering | Are we game yet?, accessed on July 25, 2025, [https://arewegameyet.rs/ecosystem/textrendering/](https://arewegameyet.rs/ecosystem/textrendering/)  
23. Tauri vs Iced vs egui: Rust GUI framework performance comparison (including startup time, input lag, resize tests) \- Lukasʼ Blog, accessed on July 24, 2025, [http://lukaskalbertodt.github.io/2023/02/03/tauri-iced-egui-performance-comparison.html](http://lukaskalbertodt.github.io/2023/02/03/tauri-iced-egui-performance-comparison.html)  
24. The state of Rust GUI libraries \- LogRocket Blog, accessed on July 24, 2025, [https://blog.logrocket.com/state-rust-gui-libraries/](https://blog.logrocket.com/state-rust-gui-libraries/)  
25. yeslogic/allsorts: Font parser, shaping engine, and subsetter implemented in Rust \- GitHub, accessed on July 25, 2025, [https://github.com/yeslogic/allsorts](https://github.com/yeslogic/allsorts)  
26. allsorts \- Rust \- Docs.rs, accessed on July 25, 2025, [https://docs.rs/allsorts](https://docs.rs/allsorts)  
27. Allsorts Font Shaping Engine 0.15 Release \- YesLogic, accessed on July 25, 2025, [https://yeslogic.com/blog/allsorts-rust-font-shaping-engine-0-15-0/](https://yeslogic.com/blog/allsorts-rust-font-shaping-engine-0-15-0/)  
28. rustybuzz — Rust text processing library // Lib.rs, accessed on July 25, 2025, [https://lib.rs/crates/rustybuzz](https://lib.rs/crates/rustybuzz)  
29. harfbuzz/rustybuzz: A complete harfbuzz's shaping algorithm port to Rust \- GitHub, accessed on July 25, 2025, [https://github.com/harfbuzz/rustybuzz](https://github.com/harfbuzz/rustybuzz)  
30. rustybuzz \- crates.io: Rust Package Registry, accessed on July 25, 2025, [https://crates.io/crates/rustybuzz/0.7.0](https://crates.io/crates/rustybuzz/0.7.0)  
31. ab\_glyph \- crates.io: Rust Package Registry, accessed on July 25, 2025, [https://crates.io/crates/ab\_glyph](https://crates.io/crates/ab_glyph)  
32. ab\_glyph \- Rust \- Docs.rs, accessed on July 25, 2025, [https://docs.rs/ab\_glyph](https://docs.rs/ab_glyph)  
33. ab\_glyph\_rasterizer \- crates.io: Rust Package Registry, accessed on July 25, 2025, [https://crates.io/crates/ab\_glyph\_rasterizer](https://crates.io/crates/ab_glyph_rasterizer)  
34. Exploring the top Rust web frameworks \- DEV Community, accessed on July 24, 2025, [https://dev.to/logrocket/exploring-the-top-rust-web-frameworks-2865](https://dev.to/logrocket/exploring-the-top-rust-web-frameworks-2865)