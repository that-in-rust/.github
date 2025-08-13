

# **An Architectural Blueprint for a Productive, High-Performance Frontend DSL**

## **Deconstruction of the Core Vision: A Triad of Paradigms**

The proposal for a new Domain-Specific Language (DSL) for frontend business websites rests on the synthesis of three powerful, yet distinct, software development paradigms. This section deconstructs each of these foundational pillars—the "Productive Safety" of Ferrum, the server-centric simplicity of HTMX, and the declarative component model of JSX—to establish a set of concrete design principles. By analyzing their individual strengths and the tensions that arise from their combination, a coherent vision for the proposed DSL emerges.

### **The Ferrum Principle: "Productive Safety"**

The philosophical core of the proposed DSL is derived from Ferrum, a backend framework designed to merge two traditionally opposed worlds: the high-productivity, developer-friendly environment of frameworks like Ruby on Rails, and the uncompromising performance and safety guarantees of Rust \[Image 2\]. Ferrum's central thesis is that it is possible to achieve "Productive Safety" by providing a higher-level DSL that abstracts away Rust's most challenging features without sacrificing its core benefits.

As illustrated in its competitive analysis, Ferrum targets a unique niche that balances initial productivity, performance, type safety, and memory control, positioning itself against pure Rust, Go, and Ruby on Rails \[Image 3\]. It accomplishes this through a mechanism of "Transparent Compilation." Ferrum code is not interpreted; rather, it is transformed via Rust's powerful procedural macro system into clean, idiomatic, and human-readable Rust code \[Image 3\]. This approach provides an "ejection path," allowing developers to transition from the DSL to raw Rust if a project's complexity outgrows the DSL's abstractions.

A key innovation in Ferrum's design is how it addresses Rust's infamous borrow checker and lifetime system, which represent a significant cognitive load for developers, especially those coming from garbage-collected or more permissive languages.1 Instead of forcing developers to master concepts like

Arc\<Mutex\<T\>\> for shared mutable data, Ferrum introduces a small set of explicit, purpose-driven keywords: let\_local, let\_cow, let\_shared\_immutable, and let\_shared\_mutable \[Image 2\]. Each keyword maps to a specific Rust ownership pattern (let x \=..., Cow\<T\>, Arc\<T\>, Arc\<Mutex\<T\>\> respectively), allowing the developer to declare their *intent* for the data, while the compiler handles the complex implementation details.

The relevance of this principle to a frontend DSL is profound. Ferrum's own roadmap includes a plan to target WebAssembly, explicitly validating the concept of extending this philosophy to the client side \[Image 3\]. The core takeaway is that the proposed frontend DSL should be compiler-centric, designed not merely to *use* Rust, but to actively *manage its complexity* on behalf of the developer, thereby unlocking its performance and safety for a broader audience.

### **The HTMX Principle: "Hypermedia as the Engine of Application State"**

The second pillar of the vision comes from HTMX, a library that challenges the prevailing conventions of modern, JavaScript-heavy frontend development. HTMX's motivation stems from a desire to "complete HTML as a hypertext" by removing what it sees as artificial limitations on the language \[Image 1\]. In standard HTML, only \<a\> tags and \<form\> elements can make HTTP requests, and they are generally limited to GET and POST methods that replace the entire screen.

HTMX extends these capabilities to any HTML element. Using simple attributes, a developer can specify that a \<div\>, \<span\>, or \<button\> should issue a PUT, DELETE, or any other HTTP request in response to any DOM event (e.g., click, mouseover, keyup). Crucially, the response from the server, which is typically a fragment of HTML, can then be used to replace the content of any element on the page, not just the element that triggered the request \[Image 1\].

This model promotes a philosophy known as "Hypermedia as the Engine of Application State" (HATEOAS). It radically simplifies the client-side architecture by positioning the server as the single source of truth for UI state. Instead of building complex state management machines in JavaScript to track application state, many state transitions are reduced to a simple server round-trip that returns a new piece of UI. The client becomes dumber, and the server becomes smarter about its presentation logic. This approach has been shown to reduce codebase size significantly when compared to frameworks like React \[Image 1\]. For the proposed DSL, this principle provides a powerful directive: prioritize a server-centric state model to reduce client-side complexity wherever possible.

### **The JSX Principle: "Declarative, Composable UI"**

The third and final pillar is the developer experience (DX) and architectural pattern embodied by JSX. As demonstrated in the example of a reusable \<SortingHat /\> component, JSX provides an ergonomic, declarative syntax that allows developers to write HTML-like structures directly within their programming language (historically, JavaScript) \[Image 4\]. This approach has become the bedrock of modern frontend frameworks like React, Yew, and Dioxus for several key reasons.4

The primary power of JSX lies in its component model. It encourages the creation of small, reusable, and self-contained units of UI. Each component encapsulates its own appearance (the markup), its logic (the functions and event handlers), and its state. These components can then be composed, nested, and reused throughout an application, making it possible to build large, complex user interfaces from simple, manageable building blocks.4 The co-location of logic and markup in a single, readable unit is considered a major advancement in UI development ergonomics.

For the proposed DSL, the JSX principle establishes the target for the developer experience. Developers should think and build in terms of components, passing data down through properties (props) and managing encapsulated logic. This proven model for structuring UIs is essential for achieving the goal of rapid development, especially for the complex business websites the DSL aims to serve. Frameworks like Yew and Dioxus have already demonstrated the successful adaptation of this JSX-like syntax to the Rust ecosystem through procedural macros named html\! and rsx\! respectively, proving its viability.4

### **Synthesizing the Vision: Conceptual Synergies and Tensions**

Fusing these three principles into a single, coherent DSL creates both powerful synergies and inherent architectural tensions that must be resolved.

The primary synergy lies in the potential for these paradigms to complement each other's weaknesses. The component model of JSX can serve as the perfect container for the hypermedia controls of HTMX. A single, self-contained component could manage its own internal, client-only state (e.g., the current value of a text input) while also containing declarative attributes that trigger server interactions to fetch or update data. Ferrum's compilation model provides the underlying mechanism to translate this hybrid component definition into highly efficient and safe Rust code, which can then be compiled to WebAssembly for the browser.

However, a significant tension exists between the client-centric state management model that is idiomatic in JSX-based frameworks like React and the server-centric model promoted by HTMX. React applications often build elaborate trees of client-side state, whereas HTMX aims to eliminate as much of that as possible. A core architectural challenge for the proposed DSL will be to define a clear and intuitive boundary. The DSL must provide guidance on which state is ephemeral and belongs on the client, and which state is canonical and should be driven by the server.

Resolving this tension leads to a more nuanced understanding of the project's goals. The "best of HTMX" should not be interpreted as a literal implementation of hx- attributes within a JSX-like syntax. A more powerful and idiomatic approach exists within the modern Rust full-stack ecosystem: the "server function." Frameworks like Leptos and Dioxus have pioneered this concept, where a Rust function, annotated with a \#\[server\] macro, can be written directly alongside frontend component code.7 Despite its co-location in the source file, this function is compiled

*only* for the server. When this function is called from the client-side code (e.g., in a button's onclick handler), the macro automatically generates the necessary RPC-style network request (a fetch call to a dynamically created API endpoint) to execute it on the server.7 This mechanism achieves the exact philosophical goal of HTMX—declarative, co-located server interactions—but does so in a manner that is fully type-safe from the frontend call signature to the backend database query. The compiler guarantees the entire contract, eliminating a whole class of errors common in traditional REST API or

hx- attribute implementations. Therefore, the true synthesis of these ideas involves embracing the server function pattern as the type-safe, Rust-idiomatic successor to the HTMX model.

Similarly, a deeper look at Ferrum's design provides a blueprint for frontend state management. Ferrum's keywords (let\_cow, let\_shared\_mutable, etc.) were created to solve the backend problem of managing data ownership and concurrency \[Image 2\]. Frontend development faces an analogous problem in managing UI state: determining if state is a simple value, if it needs to be shared between components, or if it must be mutable and reactive. The Rust frontend ecosystem has largely converged on "signals" as the primary primitive for ergonomic state management.10 Signals, particularly the

Copy \+ 'static variants pioneered by Leptos, are designed to solve the exact ownership and lifetime issues that make UI programming in raw Rust difficult.11 These signals are, in effect, a specialized form of shared, mutable state, conceptually similar to what Ferrum's

let\_shared\_mutable provides for the backend. The proposed DSL can therefore adopt Ferrum's approach by providing high-level keywords like let\_signal or let\_memo, which would compile down to the appropriate, battle-tested signal types. This would deliver the same "Productive Safety" for frontend state management that Ferrum offers for backend data, directly addressing a primary pain point for developers adopting Rust for UI development.14

## **A Proposed Architecture for "Ferrum-JSX"**

Building upon the synthesized vision, this section outlines a tangible architectural blueprint for the proposed DSL, provisionally named "Ferrum-JSX" or "Fe-JSX." This architecture aims to translate the philosophical principles into a concrete set of syntax rules, state management models, and client-server communication protocols.

### **DSL Syntax: Merging JSX and Server Functions**

The developer-facing syntax of Fe-JSX will be a cornerstone of its productivity. The proposal is to implement it as a Rust-based procedural macro, following the successful precedent set by Dioxus's rsx\! and Yew's html\! macros.4 This allows for an ergonomic, JSX-like templating language to be embedded directly within Rust functions, providing a familiar and declarative way to build UI structures.

The key innovation will be the seamless integration of the state management and server communication primitives directly into this syntax. The following conceptual example illustrates how these elements would work in concert:

Rust

// Fictional Fe-JSX Syntax  
\#\[component\]  
fn UserProfile(user\_id: u32) \-\> Element {  
    // State declaration using Ferrum-inspired keywords.  
    // This creates a reactive signal populated by a server function call.  
    let\_signal user\_name \= use\_server\_future(move |

| get\_user\_name(user\_id));  
      
    // This creates a simple, client-side signal for a controlled input.  
    let\_signal new\_name \= use\_signal(|| "".to\_string());

    rsx\! {  
        div {  
            // Reading from the signal automatically subscribes the UI to updates.  
            h1 { "Profile for: {user\_name.read()}" }  
              
            input {  
                // Two-way data binding is explicit.  
                value: "{new\_name.read()}",  
                oninput: move |evt| new\_name.set(evt.value),  
            }  
              
            // The "HTMX" part, realized as a type-safe server function call.  
            button {  
                onclick: move |\_| {  
                    // We can spawn an async task to call the server function.  
                    spawn\_local(async move {  
                        // The call looks like a normal async function call.  
                        let \_ \= update\_user\_name(user\_id, new\_name.read().clone()).await;  
                          
                        // After updating, we can invalidate the original data source  
                        // to trigger a refetch and update the UI.  
                        user\_name.invalidate();  
                    });  
                },  
                "Update Name"  
            }  
        }  
    }  
}

// The server function is co-located for developer convenience  
// but is only compiled for and executed on the server.  
\#\[server\]  
async fn get\_user\_name(id: u32) \-\> Result\<String, ServerFnError\> {  
    // Server-only logic, e.g., database access using a crate like sqlx.  
    // This code will not be included in the Wasm binary.  
    //... database logic...  
    Ok("Example User".to\_string())  
}

\#\[server\]  
async fn update\_user\_name(id: u32, new\_name: String) \-\> Result\<(), ServerFnError\> {  
    // Server-only logic to update the database.  
    //... database update logic...  
    Ok(())  
}

This conceptual syntax directly embodies the triad of principles. It uses a JSX-like syntax (rsx\!) for declarative UI composition \[Image 4\]. It employs Ferrum-inspired keywords (let\_signal) for a simplified and productive approach to state management \[Image 2\]. Finally, it replaces the literal HTMX model with the more powerful and type-safe server function pattern, which achieves the same goal of server-driven interactions in a way that is native to the Rust ecosystem.7

### **The Component and State Model**

The state management system is critical to the ergonomics and performance of the framework. A careful analysis of the existing Rust frontend ecosystem reveals a clear architectural path that aligns with the goals of Fe-JSX.

While the user query mentions a "React-type frontend," which might suggest a Virtual DOM (VDOM) architecture like that used in React, Yew, and Dioxus 4, a deeper consideration of the project's goals points in a different direction. The "best of HTMX" philosophy encourages small, targeted DOM updates initiated by server interactions. A full VDOM diff, where the entire component's output is re-calculated and compared against the previous version, can be an inefficient mechanism for simply replacing a single text node or updating an attribute.

Frameworks like Leptos and Sycamore have adopted a more direct approach called "fine-grained reactivity".12 In this model, components are functions that run

*once* to create the initial DOM nodes. Alongside these nodes, they establish a reactive graph of signals and effects. When a signal's value is updated, it doesn't re-run the entire component function. Instead, it triggers only the specific "effect" that is subscribed to it, which then performs a direct, minimal manipulation of the DOM (e.g., updating a single text node's content).11 This model is a much better philosophical fit for the HTMX principle of targeted updates. Performance benchmarks also consistently show that fine-grained frameworks are exceptionally fast, often outperforming VDOM-based ones, particularly in scenarios involving many small, independent updates.17 Therefore, Fe-JSX should be built upon a fine-grained reactive runtime to best achieve its goals of speed and architectural simplicity.

The core primitive of this reactive system will be the **signal**. Following the clear trend and proven ergonomics of Leptos and Dioxus (which uses signals for state management even with a VDOM), signals elegantly solve many of the lifetime and ownership issues that can make Rust UI development challenging.10 Specifically, by adopting the

Copy \+ 'static signal pattern from Leptos, state management becomes much simpler for developers, as signals can be easily moved into event handler closures without complex lifetime annotations, a common source of frustration.11

The state model will be tiered:

* **Local State:** Managed by signals created within a component using the let\_signal keyword. This state is ephemeral and tied to the component's lifecycle.  
* **Shared State:** For state that needs to be accessible across different component subtrees, the framework will provide a "context" system, a standard pattern found in all major Rust frameworks that allows for dependency-injection-like sharing of signals or other data.10  
* **Server State:** This is state that originates from the backend. It will be managed via asynchronous "resources" or "futures" that are populated by server function calls. This pattern, seen in both Leptos and Dioxus, provides a declarative way to handle data fetching, loading states, error states, and caching.8

### **The Client-Server Contract: Powered by Server Functions**

The bridge between the client and server is the most critical piece of the "hypermedia-enhanced component" model. Fe-JSX will adopt the server function architecture, as implemented in Leptos and Dioxus, as a first-class, core feature.7

The \#\[server\] macro will be the engine of this contract, handling a complex series of transformations transparently for the developer:

1. **Argument Serialization:** The macro will analyze the server function's signature and generate a new struct to hold its arguments. It will ensure that all argument types are serializable (e.g., they implement serde::Serialize and serde::Deserialize).20  
2. **Client-Side Stub Generation:** When compiling for the client (Wasm), the macro will completely remove the original function body. In its place, it will generate an asynchronous "stub" function. When this stub is called, it will serialize the provided arguments into a specific encoding (e.g., URL-encoded for GET requests, JSON or Cbor for POST requests) and make an HTTP fetch request to a unique, auto-generated API endpoint.7 It will then await the response, deserialize it into the function's return type, and return it to the caller.  
3. **Server-Side Handler Generation:** When compiling for the server, the macro will keep the original function body and wrap it in an HTTP handler compatible with a backend framework like Axum or Actix Web.8 This handler will be responsible for deserializing the incoming request, executing the original function logic (e.g., the database query), and serializing the result back into an HTTP response.

This architecture provides a seamless, end-to-end type-safe RPC bridge. It eliminates vast amounts of boilerplate code related to defining API endpoints, handling serialization, and writing fetch logic. It also allows developers to use server-only dependencies, like database clients, directly within their server function bodies, as this code is never compiled into the client's Wasm binary.7 This powerful abstraction is the key to delivering on the promise of a productive, full-stack development experience.

## **The Compilation Pipeline: From Fe-JSX to Rust and Wasm**

The transformation of the high-level Fe-JSX language into executable code is the most technically complex aspect of this proposal. The entire value proposition hinges on a sophisticated compilation pipeline that is both powerful and transparent. This process follows the model set by Ferrum, leveraging Rust's own metaprogramming capabilities to create a seamless developer experience \[Image 3\].

### **The Compiler Core: Rust Procedural Macros**

The Fe-JSX "compiler" will not be a standalone executable but will be implemented as a set of Rust procedural macros. This is a standard and powerful technique in the Rust ecosystem for creating DSLs and extending the language's syntax.21 The primary tools for this task are a trio of well-established crates:

* proc\_macro2: Provides a more robust and versatile API for working with token streams than the standard library's proc\_macro. It is the foundation upon which the other tools are built.21  
* syn: A comprehensive parser for Rust source code. It is used to parse the TokenStream passed into a procedural macro into a structured, navigable Abstract Syntax Tree (AST).21  
* quote: The inverse of syn. It provides a quasi-quoting macro, quote\!, that allows for the programmatic generation of new Rust code (as a TokenStream) from an AST or other data structures.21

The compilation process for a piece of Fe-JSX code will follow these distinct phases:

1. **Parsing:** When the Rust compiler encounters an Fe-JSX macro, such as rsx\!{...} or a function annotated with \#\[component\], it passes the enclosed code to the macro as a proc\_macro::TokenStream. The macro's first job is to use syn to parse this stream of raw tokens into a well-defined AST that represents the UI structure, its attributes, and its logic.22  
2. **Semantic Analysis & IR Transformation:** Once parsed, the compiler analyzes the AST to understand its meaning. It identifies component definitions, state declarations (let\_signal), event handlers, and server function calls. To manage complexity and improve maintainability, it is a highly recommended practice to transform this initial AST into a custom Intermediate Representation (IR).24 This IR is a set of structs and enums designed specifically to represent the concepts of the Fe-JSX language, separating the concerns of parsing the syntax from the concerns of generating the output code.  
3. **Code Generation:** The final phase involves traversing the custom IR and using the quote macro to generate the target Rust code. This generated code will be a new proc\_macro::TokenStream that represents the expanded, idiomatic Rust implementation of the original Fe-JSX component. This final token stream is then handed back to the Rust compiler (rustc) for the standard compilation process.

### **Generating "Productive" Rust: Taming the Borrow Checker**

The single greatest challenge—and the most critical measure of the DSL's success—is its ability to generate Rust code that is guaranteed to compile without forcing the developer into "lifetime hell".2 Rust's strictness is its superpower, leading to highly robust and performant applications, but it is also a significant barrier to entry and can make initial, exploratory "draft coding" very difficult.1 A DSL that merely provides syntactic sugar but still generates code that produces arcane borrow checker errors has failed in its primary mission.

Therefore, the Fe-JSX compiler must be highly opinionated, leveraging the hard-won patterns from mature Rust frontend frameworks to guide the developer onto a "golden path." This is where the DSL's true value is realized: it is not just a code generator, but an *ownership and lifetime architect*.

* **State Management:** The compiler will enforce that all reactive state is managed through signals. The let\_signal keyword will expand to a call like let my\_signal \= use\_signal(...). The key is that the chosen signal implementation, like that in Leptos, will produce a type that is Copy.11 This is a crucial ergonomic win. Because the signal identifier itself is a simple, copyable value (like an index into a central state store), it can be freely  
  moved into closures—such as onclick event handlers—without triggering any of Rust's complex borrowing or lifetime rules. This single design choice elegantly bypasses the most common and frustrating category of borrow checker errors encountered in UI programming.  
* **Error Handling:** The compiler will enforce the contract that all \#\[server\] functions must return a Result\<T, ServerFnError\>.7 This makes failure an explicit part of the client-server contract, forcing developers to consider and handle potential network issues, serialization errors, or server-side exceptions.  
* **The Ejection Path:** A fundamental principle, inherited from Ferrum, is the provision of a clear "ejection path" \[Image 3\]. The Rust code generated by the Fe-JSX macros must be clean, idiomatic, and human-readable. This is not merely an aesthetic concern; it is a critical feature for de-risking adoption. Developers can use standard Rust tooling, such as cargo-expand or the macro expansion features in IDEs, to inspect the generated code.24 If a project's requirements ever exceed the capabilities of the DSL, the team is not trapped. They can take the expanded, human-readable Rust code, commit it to their source control, and continue development by hand. This safety net provides confidence that choosing the high-productivity DSL at the start of a project does not lock them into a "golden cage," which is a powerful selling point for experienced engineering teams wary of "magic" frameworks.

### **The Bridge to the Browser: wasm-pack and wasm-bindgen**

After the Fe-JSX macros have generated idiomatic Rust code, the final step is to compile it for the browser. The standard, and most robust, toolchain for this is wasm-pack.26

wasm-pack is an integrated build tool that orchestrates the entire process: it invokes the Rust compiler (rustc) with the correct wasm32-unknown-unknown target, runs wasm-bindgen to generate the necessary JavaScript interface, and can even package the final output into a ready-to-publish npm package.26

The role of wasm-bindgen in this pipeline is non-negotiable and absolutely critical. WebAssembly, by itself, has a very primitive interface with its host environment (the JavaScript VM in the browser). It can only pass basic numeric types (integers and floats) back and forth.29 It has no built-in knowledge of strings, objects, or, most importantly, the Document Object Model (DOM).

wasm-bindgen bridges this gap by generating "glue" code.27 For every Rust function exported to JavaScript with a

\#\[wasm\_bindgen\] attribute, it generates a corresponding JavaScript wrapper. This wrapper knows how to take complex JavaScript types (like a string), encode them into a format Wasm understands (like a pointer and length into the Wasm linear memory), call the Wasm function with those numbers, and handle memory management.30 Conversely, when Rust code needs to call a browser API (like

console.log or document.createElement), it calls an imported function, also marked with \#\[wasm\_bindgen\]. wasm-bindgen ensures that the necessary JavaScript shim exists to receive this call from Wasm and forward it to the actual browser API.

The Rust code generated by the Fe-JSX compiler will therefore be heavily annotated with \#\[wasm\_bindgen\] attributes. Component functions will be exported so they can be rendered, and any necessary browser APIs will be imported. This wasm-bindgen layer is what makes a rich, interactive application possible, transforming the raw computational power of Wasm into a tool that can actively manipulate a web page.

## **A Critical Analysis of the Performance Hypothesis**

A central motivation behind the proposed DSL is the assumption that because it compiles to Rust, and Rust compiles to WebAssembly, the resulting frontend application "would be fast." This section critically examines this hypothesis, dissecting the nuances of web performance to provide a more accurate and actionable understanding. The analysis reveals that while Rust/Wasm offers significant advantages, performance is a product of architecture, not just language choice.

### **The Two Halves of Performance: Computation vs. DOM Manipulation**

Web application performance can be broadly divided into two distinct domains: pure computation and DOM manipulation. The performance characteristics of WebAssembly differ dramatically between them.

For **computation-heavy tasks**, the performance hypothesis holds true. WebAssembly is a pre-compiled binary format that is designed for efficient decoding and execution by the browser's engine.32 For workloads involving complex mathematics, data processing, physics simulations, or cryptography, Wasm consistently and significantly outperforms JavaScript. The performance gains can range from a modest 2-3x to a staggering 40-60x, depending on the specific task and how well it maps to Wasm's strengths, such as linear memory access and predictable performance without garbage collection pauses.33 In these scenarios, Rust code compiled to Wasm runs at near-native speed.

For **DOM manipulation**, however, the story is far more complex and represents the primary performance bottleneck for most UI-centric applications. WebAssembly, by design, runs in a sandboxed environment and has no direct access to the Document Object Model or any other browser Web APIs.33 To create an element, change a style, or attach an event listener, the Wasm module must make a function call out to JavaScript. This transition across the Wasm-JS boundary is handled by the "glue" code generated by tools like

wasm-bindgen. While modern browser engines have made this boundary crossing significantly faster than it used to be, it still imposes a non-zero overhead.37 Every single DOM operation initiated from Rust/Wasm must pay this "FFI (Foreign Function Interface) tax."

The verdict is clear: for UI-heavy applications, the raw execution speed of Rust within the Wasm VM is often overshadowed by the cost of communicating with the DOM via JavaScript. Therefore, an application's perceived speed is less about the language's computational efficiency and more about how intelligently it manages its interactions with the DOM. This reality creates strong architectural pressure to design a system that minimizes the number of boundary crossings. A "chatty" interface, where the Wasm module makes hundreds of small, individual calls to the DOM in a tight loop, will suffer from the accumulated overhead of these calls. In contrast, a "chunky" interface, where the Wasm module performs a large amount of computation and then makes a single, batched call to JavaScript to update the DOM, will be far more performant. This principle must be a first-class design constraint for the Fe-JSX runtime, encouraging update batching and efficient data transfer patterns.

### **Learning from the Benchmarks**

To move from theory to empirical data, one can turn to the de facto standard for comparing web framework performance: the JS Framework Benchmark.17 This benchmark measures various DOM manipulation operations, such as creating, updating, swapping, and deleting thousands of rows in a table.

Analysis of the benchmark results provides several critical takeaways:

* **Rust/Wasm is Highly Competitive:** Top-tier Rust/Wasm frameworks, particularly those using fine-grained reactivity like Leptos and Sycamore, are not just viable; they are highly competitive with the fastest JavaScript frameworks available, such as SolidJS and Svelte. They consistently and significantly outperform popular VDOM-based frameworks like React and Angular.17  
* **The DOM is the Ultimate Bottleneck:** The absolute fastest entries in the benchmark are often minimal, vanilla JavaScript libraries that are hand-optimized for the specific benchmark tasks.18 This demonstrates that once a certain level of optimization is reached, the performance of the framework becomes less important than the inherent speed of the browser's DOM implementation itself.  
* **Architecture Trumps Language:** The most crucial observation is that the key determinant of performance among the top frameworks is not the language (Rust vs. JavaScript) but the **rendering architecture**. The fastest frameworks from *both* ecosystems (Leptos, SolidJS) use a fine-grained reactive model. The slightly slower frameworks (Dioxus, React) use a Virtual DOM.

This leads to a refined performance justification for Fe-JSX. The primary driver of its potential speed is the architectural decision to build it upon a fine-grained reactive runtime. The benefit of using Rust is not a "free" or "magical" speed boost over JavaScript for DOM operations. Instead, the benefit is the ability to construct this highly optimized, fine-grained architecture with the unparalleled guarantees of type safety, memory safety, and fearless concurrency that Rust provides. This allows for the creation of more robust, maintainable, and predictable high-performance code. The strategic positioning should therefore shift from a simplistic "fast because it's Rust" to a more nuanced and accurate "as fast as the world's fastest JS frameworks, but with the industrial-strength safety and power of Rust."

### **Beyond Raw Speed: Bundle Size and Time-to-Interactive (TTI)**

Raw execution speed is only one component of perceived performance. Two other critical metrics for business websites are initial bundle size and Time-to-Interactive (TTI).

**Bundle Size** has historically been a significant challenge for WebAssembly. A minimal "hello world" application compiled from Rust to Wasm, including the necessary JavaScript glue, is often larger than a comparable application written in a highly optimized JS framework like Svelte or SolidJS.41 This is because the Wasm binary must often include parts of Rust's standard library and the memory allocator. While advanced techniques like code size optimization (

wee\_alloc, lto, opt-level='z') can mitigate this, it remains a key consideration. Modern frameworks are actively addressing this; for example, Leptos's "islands architecture" is a direct response, allowing developers to build multi-page apps where the Wasm binary is only shipped for the interactive "islands" on a page, while the rest is static, server-rendered HTML.43

**Time-to-Interactive (TTI)** is an area where Wasm has a potential structural advantage. A JavaScript file must be fully downloaded, then parsed, and then fed to the JIT (Just-In-Time) compiler before it can be executed. This entire process can take hundreds of milliseconds or even seconds on slower devices.41 In contrast, a Wasm binary is already compiled. The browser can begin executing Wasm code much more quickly, sometimes even streaming the compilation and execution as the file downloads. This could lead to a noticeably faster startup time and a quicker TTI for Wasm-based applications, even if their total bundle size is slightly larger.41

The developer must weigh this trade-off: the potentially larger initial download size of the Wasm binary against its faster startup and execution time once downloaded. For business applications where users may have repeated sessions, the faster execution on subsequent visits can be a compelling advantage.

## **Strategic Positioning in the Competitive Landscape**

The decision to create a new DSL, even one with a compelling vision, must be justified by its ability to occupy a unique and valuable niche within the existing market. The Rust frontend ecosystem, while younger than its JavaScript counterpart, is maturing rapidly with several strong contenders. A strategic analysis is required to identify where Fe-JSX would fit and what its unique selling proposition would be.

### **Comparative Analysis of Leading Frameworks**

To understand the current landscape, a detailed comparison of the leading Rust frontend frameworks—Yew, Dioxus, Leptos, and Sycamore—is necessary. These frameworks represent the primary architectural approaches and philosophies in the ecosystem today.44

* **Yew:** As one of the most mature frameworks, Yew is heavily inspired by React.5 It uses a component-based architecture, a JSX-like  
  html\! macro, and a Virtual DOM for rendering.4 Its state management is based on hooks, similar to React's. Yew's primary focus is on building client-side rendered web applications, and while server-side rendering is possible, full-stack integration requires more manual setup using external crates like  
  gloo-net for fetching data.4 Its target audience is clearly developers with a React background looking to build web apps in Rust.  
* **Dioxus:** Dioxus positions itself as a cross-platform framework for building UIs for web, desktop, mobile, and more, all from a single codebase.15 Architecturally, it also uses a VDOM and a React-like component model with an  
  rsx\! macro.6 Its state management has evolved to heavily feature signals, though it still operates within a VDOM paradigm.10 Dioxus's key differentiator is its renderer-agnostic design and its first-class support for platforms beyond the web.15 It has also integrated a full-stack solution with server functions, borrowing the implementation from the Leptos ecosystem to provide a seamless client-server experience.8  
* **Leptos:** Leptos is a full-stack, isomorphic web framework built from the ground up on the principle of fine-grained reactivity.13 It eschews a VDOM in favor of creating DOM nodes once and updating them surgically via a highly optimized reactive system based on signals.11 Its  
  Copy \+ 'static signal design provides exceptional ergonomics, solving many common ownership and lifetime issues.13 Leptos is "web-first" and deeply focused on holistic web performance, with built-in support for features like streaming server-side rendering and an islands architecture to minimize Wasm bundle size.13 Its server functions are a core, deeply integrated primitive.7  
* **Sycamore:** Sycamore shares its core philosophy with Leptos, being built on fine-grained reactivity and inspired by SolidJS.12 It provides a reactive system and a templating DSL to build highly performant web applications. While the core library is focused on the client side, the Perseus framework is built on top of Sycamore to provide a full-stack, opinionated solution with features like SSR and static site generation.45

This analysis can be summarized in the following table to highlight the architectural trade-offs and identify the potential niche for Fe-JSX.

| Feature | Yew | Dioxus | Leptos | Sycamore | Proposed Fe-JSX |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **Core Paradigm** | Component-Based (React-like) | Component-Based (React-like) | Fine-Grained Reactive | Fine-Grained Reactive | **Hybrid (Component \+ Hypermedia)** |
| **Rendering Model** | Virtual DOM | Virtual DOM | Fine-Grained Updates | Fine-Grained Updates | **Fine-Grained Updates** |
| **State Management** | Hooks | Hooks & Signals | Signals (Copy \+ 'static) | Signals | **Ferrum-inspired Signals** |
| **Platform Target** | Web | Cross-Platform (Web, Desktop, Mobile) | Full-Stack Web | Web (Perseus for Full-Stack) | **Full-Stack Web** |
| **Server Comms** | Manual Fetch (gloo-net) | Integrated Server Functions | Integrated Server Functions | (via Perseus framework) | **Core: Integrated Server Functions** |
| **Primary Goal** | Ergonomic Web Apps for React Devs | Portable UIs for All Platforms | Performant, Ergonomic Full-Stack Web | Performant, Reactive Web Apps | **Productive, Safe, Server-Centric Web Apps** |

### **Identifying the Niche: "Hypermedia-Enhanced Components"**

The comparative analysis reveals a clear opportunity. While Dioxus and Leptos offer excellent server function support, their fundamental mental model remains that of a client-side application that is capable of *calling* the server. Their architecture is optimized for building Single-Page Applications (SPAs) that can be server-rendered for the initial load.

Fe-JSX, by deeply embracing the HTMX philosophy as its guiding principle, can position itself differently. It would not be just another framework for building SPAs, but a framework for building **server-centric applications with rich, component-based islands of interactivity.** This is a subtle but profound distinction in philosophy and target audience. It appeals directly to developers who appreciate the simplicity and robustness of traditional server-rendered applications (built with frameworks like Ruby on Rails, Django, or Laravel) but desire the modern developer experience of a component-based UI and the performance benefits of a compiled language.

This reframing reveals that the true competitors for Fe-JSX are not necessarily the other Rust frontend frameworks. Instead, its primary competition is the *development model* offered by frameworks like **Ruby on Rails with Hotwire** or **PHP/Laravel with Livewire**. These successful ecosystems also aim to keep state and rendering logic on the server, using WebSockets or AJAX to "sprinkle" interactivity onto server-generated HTML, thus minimizing client-side JavaScript.

Fe-JSX's unique selling proposition becomes incredibly compelling in this context. It offers a path to build applications using that same productive, server-centric model, but with two transformative advantages that are impossible in the Ruby or PHP ecosystems:

1. **End-to-End Type Safety:** Thanks to Rust and the server function pattern, the entire application, from the database query to the button click handler, is covered by a single, unified type system. This eliminates a vast category of runtime errors, integration bugs, and API mismatches.  
2. **Compiled Performance:** The entire stack is compiled to highly efficient machine code on the server and WebAssembly on the client, offering performance characteristics that interpreted languages cannot match.

Therefore, the strategic position of Fe-JSX is not merely as "another Rust frontend framework," but as a next-generation, type-safe, and compiled alternative to the entire Rails/Hotwire and Laravel/Livewire paradigm. It targets full-stack developers looking for a step-change in reliability and performance without sacrificing the productivity of a server-centric workflow.

## **Synthesis and Strategic Recommendations**

The exploration of a new frontend DSL built on the principles of Ferrum, HTMX, and JSX presents a compelling, albeit challenging, vision. This final section synthesizes the preceding analysis to deliver a clear verdict on the project's feasibility, identify the primary risks involved, and propose a strategic path forward for its development.

### **Feasibility Verdict: Ambitious but Viable**

The proposal to create Fe-JSX is highly ambitious. It requires deep, cross-disciplinary expertise in compiler design, Rust metaprogramming, frontend framework architecture, and the intricacies of the WebAssembly ecosystem. The effort to build a robust, ergonomic, and performant DSL from the ground up should not be underestimated.

Despite the ambition, the project is **technically viable**. The analysis confirms that the foundational technologies required are mature and battle-tested.

* Rust's procedural macro system, powered by crates like syn and quote, is a proven mechanism for creating sophisticated DSLs.21  
* The wasm-pack and wasm-bindgen toolchain provides a stable and well-supported pipeline for compiling Rust to browser-ready WebAssembly with the necessary JavaScript interoperability.26  
* The architectural patterns for high-performance, ergonomic frontend development in Rust have been pioneered and validated by existing frameworks like Leptos, Dioxus, and Sycamore. Their success demonstrates that it is possible to overcome Rust's inherent complexities, such as lifetime management, to create a productive UI development experience.13

The proposed synthesis is not a leap into the unknown but a novel combination of existing, successful concepts. The viability of Fe-JSX therefore depends less on technological possibility and more on the quality of execution and the commitment of resources to the development effort.

### **Key Risks and Mitigation Strategies**

Any project of this scale carries significant risks. A proactive approach to identifying and mitigating these risks is crucial for success.

* **Risk 1: Compiler Complexity and Developer Experience.** The single greatest technical risk is the difficulty of building the DSL's compiler. A naive implementation could easily produce cryptic, unhelpful error messages, replacing the borrow checker's "lifetime hell" with a new "macro expansion hell".2 This would defeat the project's primary goal of improving productivity.  
  * **Mitigation Strategy:**  
    1. **Incremental Development:** Begin with a minimal, well-defined feature set and expand gradually. Resist the temptation to build all features at once.  
    2. **Leverage the Ecosystem:** Rely heavily on the mature syn, quote, and proc-macro2 crates to handle the low-level parsing and code generation.21  
    3. **Prioritize Error Reporting:** From the very beginning of development, invest heavily in providing clear, actionable error messages. Use libraries like proc-macro-error and custom logic to map compilation failures back to the user's original source code with helpful suggestions.22  
    4. **Maintain the Ejection Path:** Ensure the generated Rust code is always human-readable, providing a crucial safety valve for developers.24  
* **Risk 2: The Rust Learning Curve.** Even with an abstraction layer, developers will still be operating within the Rust ecosystem. They will need to use Cargo, understand basic Rust types, and interact with Rust-based tooling. The learning curve, though flattened by the DSL, will still be steeper than that of a JavaScript framework.1  
  * **Mitigation Strategy:**  
    1. **Architectural Guardrails:** The DSL's design must be opinionated, guiding developers towards patterns (like Copy signals) that inherently avoid the most common ownership and lifetime pitfalls. The compiler's primary job is to make doing the right thing easy.  
    2. **Exceptional Documentation:** Investment in high-quality documentation, tutorials, and real-world examples is not optional; it is a core feature of the product. The documentation should focus on teaching the Fe-JSX patterns, not on teaching the entirety of Rust.  
* **Risk 3: Ecosystem Maturity.** The Rust/Wasm frontend ecosystem, while growing rapidly, is a fraction of the size of the JavaScript ecosystem in terms of available libraries, components, and community support.28 A project may require a specific component (e.g., a complex charting library or a specialized UI widget) that does not yet have a mature Rust equivalent.  
  * **Mitigation Strategy:**  
    1. **Embrace a "Batteries-Included" Philosophy:** Instead of trying to compete with the breadth of the npm ecosystem, focus on providing a complete, vertically integrated, and highly polished experience for the core task of building data-driven business applications. This approach, similar to what the Loco framework does for the backend, provides immense value by solving the most common problems out of the box.52  
    2. **Seamless JS Interop:** Make the process of integrating existing JavaScript libraries as smooth as possible. While the goal is to write as much as possible in Rust, providing a clean and well-documented path for using wasm-bindgen to call out to a necessary JS library is a pragmatic escape hatch.

### **Recommended Path Forward**

A phased, iterative approach is recommended to manage the project's complexity and validate its core assumptions at each stage.

* **Phase 1: Proof-of-Concept (PoC) — "The Vertical Slice"**  
  * **Objective:** To validate the end-to-end compilation pipeline and the core client-server communication model.  
  * **Key Tasks:**  
    1. Implement a minimal rsx\! macro capable of rendering a basic component with static text and attributes.  
    2. Implement a single, client-side state primitive (let\_signal) that can be updated by a simple event handler (e.g., a button click).  
    3. Implement the \#\[server\] macro for a single, simple function that takes a primitive type and returns a Result\<String, ServerFnError\>.  
    4. Build a simple application that uses these three features together: a component that calls the server function, receives a string, and displays it using a signal.  
  * **Success Criterion:** The application compiles from Fe-JSX to Rust to Wasm and runs correctly in a web browser.  
* **Phase 2: Architectural Refinement — "Building a Real Application"**  
  * **Objective:** To expand the DSL's capabilities and refine its ergonomics by using it to build a small but non-trivial application (e.g., a to-do list, a simple dashboard).  
  * **Key Tasks:**  
    1. Solidify the state management API, introducing derived signals (memos) and asynchronous resources for data fetching.  
    2. Expand the \#\[server\] macro's capabilities to support different argument/response encodings (e.g., JSON) and a basic middleware or extractor pattern for concerns like authentication.8  
    3. Develop a basic routing solution.  
  * **Success Criterion:** The DSL is expressive and ergonomic enough to build a representative business application without needing to drop down to raw Rust.  
* **Phase 3: Ecosystem and Community Growth — "Lowering the Barrier to Entry"**  
  * **Objective:** To make the framework accessible and attractive to a wider audience.  
  * **Key Tasks:**  
    1. Write comprehensive documentation, including a "getting started" guide, tutorials for common patterns, and detailed API references.  
    2. Create a library of official, reusable components for common UI needs (e.g., forms, modals, data tables).  
    3. Establish community channels (e.g., Discord, GitHub Discussions) to foster user engagement and support.  
    4. Refine the CLI tooling for a polished "out-of-the-box" developer experience.  
  * **Success Criterion:** A new developer can successfully build and deploy their first Fe-JSX application within a few hours, and a clear path exists for community contribution and growth.

#### **Works cited**

1. Rust has a reputation for being a hard/challenging programming language, and while there's some merit to that view, I think the tradeoffs Rust provides far outweigh the steep learning curve to mastering the language and tooling. Do you agree? \- Reddit, accessed on July 25, 2025, [https://www.reddit.com/r/rust/comments/1b1a25a/rust\_has\_a\_reputation\_for\_being\_a\_hardchallenging/](https://www.reddit.com/r/rust/comments/1b1a25a/rust_has_a_reputation_for_being_a_hardchallenging/)  
2. Rust is too hard to learn \- help \- The Rust Programming Language Forum, accessed on July 25, 2025, [https://users.rust-lang.org/t/rust-is-too-hard-to-learn/54637](https://users.rust-lang.org/t/rust-is-too-hard-to-learn/54637)  
3. Using Rust at a startup: A cautionary tale | by Matt Welsh | Medium, accessed on July 25, 2025, [https://mdwdotla.medium.com/using-rust-at-a-startup-a-cautionary-tale-42ab823d9454](https://mdwdotla.medium.com/using-rust-at-a-startup-a-cautionary-tale-42ab823d9454)  
4. Tutorial | Yew, accessed on July 25, 2025, [https://yew.rs/docs/tutorial](https://yew.rs/docs/tutorial)  
5. Yew, accessed on July 25, 2025, [https://yew.rs/](https://yew.rs/)  
6. dioxus \- Rust \- Docs.rs, accessed on July 25, 2025, [https://docs.rs/dioxus](https://docs.rs/dioxus)  
7. Server Functions \- Leptos Book, accessed on July 25, 2025, [https://book.leptos.dev/server/25\_server\_functions.html](https://book.leptos.dev/server/25_server_functions.html)  
8. server in dioxus\_fullstack::prelude \- Rust \- Docs.rs, accessed on July 25, 2025, [https://docs.rs/dioxus-fullstack/latest/dioxus\_fullstack/prelude/attr.server.html](https://docs.rs/dioxus-fullstack/latest/dioxus_fullstack/prelude/attr.server.html)  
9. Project Structure \- Dioxus | Fullstack crossplatform app framework ..., accessed on July 25, 2025, [https://dioxuslabs.com/learn/0.6/contributing/project\_structure](https://dioxuslabs.com/learn/0.6/contributing/project_structure)  
10. Project Structure \- Dioxus | Fullstack crossplatform app framework for Rust, accessed on July 25, 2025, [https://dioxuslabs.com/learn/0.6/contributing/project\_structure/](https://dioxuslabs.com/learn/0.6/contributing/project_structure/)  
11. leptos/ARCHITECTURE.md at main \- GitHub, accessed on July 25, 2025, [https://github.com/leptos-rs/leptos/blob/main/ARCHITECTURE.md](https://github.com/leptos-rs/leptos/blob/main/ARCHITECTURE.md)  
12. Contributing to Sycamore, accessed on July 25, 2025, [https://sycamore.dev/book/contributing](https://sycamore.dev/book/contributing)  
13. leptos-rs/leptos: Build fast web applications with Rust. \- GitHub, accessed on July 25, 2025, [https://github.com/leptos-rs/leptos](https://github.com/leptos-rs/leptos)  
14. Dioxus | 38, Layout. We can use layout to always show a… | by Mike Code \- Medium, accessed on July 25, 2025, [https://medium.com/@mikecode/dioxus-38-layout-f279dbbef5d7](https://medium.com/@mikecode/dioxus-38-layout-f279dbbef5d7)  
15. DioxusLabs/dioxus: Fullstack app framework for web, desktop, and mobile. \- GitHub, accessed on July 25, 2025, [https://github.com/DioxusLabs/dioxus](https://github.com/DioxusLabs/dioxus)  
16. sycamore-rs/sycamore: A library for creating reactive web apps in Rust and WebAssembly \- GitHub, accessed on July 25, 2025, [https://github.com/sycamore-rs/sycamore](https://github.com/sycamore-rs/sycamore)  
17. Full Stack Rust with Leptos \- benwis, accessed on July 25, 2025, [https://benw.is/posts/full-stack-rust-with-leptos](https://benw.is/posts/full-stack-rust-with-leptos)  
18. Using WebAssembly to turn Rust crates into fast TypeScript libraries | Hacker News, accessed on July 25, 2025, [https://news.ycombinator.com/item?id=36556668](https://news.ycombinator.com/item?id=36556668)  
19. leptos\_server \- Rust \- Docs.rs, accessed on July 25, 2025, [https://docs.rs/leptos\_server](https://docs.rs/leptos_server)  
20. server in leptos \- Rust \- Docs.rs, accessed on July 25, 2025, [https://docs.rs/leptos/latest/leptos/attr.server.html](https://docs.rs/leptos/latest/leptos/attr.server.html)  
21. Procedural macros — list of Rust libraries/crates // Lib.rs, accessed on July 25, 2025, [https://lib.rs/development-tools/procedural-macro-helpers](https://lib.rs/development-tools/procedural-macro-helpers)  
22. Creating your own custom derive macro \- cetra3, accessed on July 25, 2025, [https://cetra3.github.io/blog/creating-your-own-derive-macro/](https://cetra3.github.io/blog/creating-your-own-derive-macro/)  
23. Implementing Domain Specific Languages in Rust: A Practical Guide \- Codedamn, accessed on July 25, 2025, [https://codedamn.com/news/rust/implementing-domain-specific-languages-rust-practical-guide](https://codedamn.com/news/rust/implementing-domain-specific-languages-rust-practical-guide)  
24. Learning Rust by making a tiny DSL with procedural macros — what helped you keep macro code manageable? \- Reddit, accessed on July 25, 2025, [https://www.reddit.com/r/rust/comments/1kph9xx/learning\_rust\_by\_making\_a\_tiny\_dsl\_with/](https://www.reddit.com/r/rust/comments/1kph9xx/learning_rust_by_making_a_tiny_dsl_with/)  
25. leptos\_server \- crates.io: Rust Package Registry, accessed on July 25, 2025, [https://crates.io/crates/leptos\_server](https://crates.io/crates/leptos_server)  
26. 4 Ways of Compiling Rust into WASM including Post-Compilation Tools | by Barış Güler, accessed on July 25, 2025, [https://hwclass.medium.com/4-ways-of-compiling-rust-into-wasm-including-post-compilation-tools-9d4c87023e6c](https://hwclass.medium.com/4-ways-of-compiling-rust-into-wasm-including-post-compilation-tools-9d4c87023e6c)  
27. Compiling from Rust to WebAssembly \- MDN Web Docs, accessed on July 25, 2025, [https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Rust\_to\_Wasm](https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Rust_to_Wasm)  
28. Yew: The Top Rust Front End Framework for 2024 \- OpenReplay Blog, accessed on July 25, 2025, [https://blog.openreplay.com/yew--the-top-rust-front-end-framework-for-2024/](https://blog.openreplay.com/yew--the-top-rust-front-end-framework-for-2024/)  
29. Rust to WebAssembly the hard way \- surma.dev, accessed on July 25, 2025, [https://surma.dev/things/rust-to-webassembly/](https://surma.dev/things/rust-to-webassembly/)  
30. Is wasm-bindgen that essential? : r/rust \- Reddit, accessed on July 25, 2025, [https://www.reddit.com/r/rust/comments/1ahaa7v/is\_wasmbindgen\_that\_essential/](https://www.reddit.com/r/rust/comments/1ahaa7v/is_wasmbindgen_that_essential/)  
31. Introduction \- The \`wasm-bindgen\` Guide \- Rust and WebAssembly, accessed on July 25, 2025, [https://rustwasm.github.io/wasm-bindgen/](https://rustwasm.github.io/wasm-bindgen/)  
32. I was understanding WASM all wrong\! | by Yuji Isobe \- Medium, accessed on July 25, 2025, [https://medium.com/@yujiisobe/i-was-understanding-wasm-all-wrong-e4bcab8d077c](https://medium.com/@yujiisobe/i-was-understanding-wasm-all-wrong-e4bcab8d077c)  
33. Webassembly vs JavaScript : Performance, Which is Better? \- Aalpha Information Systems, accessed on July 25, 2025, [https://www.aalpha.net/blog/webassembly-vs-javascript-which-is-better/](https://www.aalpha.net/blog/webassembly-vs-javascript-which-is-better/)  
34. webassembly is faster than javascript Everyone says this, but I would dispute \- Hacker News, accessed on July 25, 2025, [https://news.ycombinator.com/item?id=23776976](https://news.ycombinator.com/item?id=23776976)  
35. Switching to Wasm for 10x Speedup \- Penrose, accessed on July 25, 2025, [https://penrose.cs.cmu.edu/blog/wasm](https://penrose.cs.cmu.edu/blog/wasm)  
36. I Tried Replacing JavaScript with Rust \+ WASM for Frontend. Here's What Happened., accessed on July 25, 2025, [https://dev.to/xinjie\_zou\_d67d2805538130/i-tried-replacing-javascript-with-rust-wasm-for-frontend-heres-what-happened-47f1](https://dev.to/xinjie_zou_d67d2805538130/i-tried-replacing-javascript-with-rust-wasm-for-frontend-heres-what-happened-47f1)  
37. I thought it was the DOM API that was glacially slow? Would WASM directly access... | Hacker News, accessed on July 25, 2025, [https://news.ycombinator.com/item?id=39996590](https://news.ycombinator.com/item?id=39996590)  
38. Does manipulating DOM from WASM have the same performance as direct JS now?, accessed on July 25, 2025, [https://stackoverflow.com/questions/73041957/does-manipulating-dom-from-wasm-have-the-same-performance-as-direct-js-now](https://stackoverflow.com/questions/73041957/does-manipulating-dom-from-wasm-have-the-same-performance-as-direct-js-now)  
39. wasm-bindgen benchmarks \- Rust and WebAssembly, accessed on July 25, 2025, [https://rustwasm.github.io/wasm-bindgen/benchmarks/](https://rustwasm.github.io/wasm-bindgen/benchmarks/)  
40. Perhaps. As mentioned I'm into benchmarking. And WASM just isn't faster for D... \- DEV Community, accessed on July 25, 2025, [https://dev.to/ryansolid/comment/lb0m](https://dev.to/ryansolid/comment/lb0m)  
41. WASM isn't necessarily faster than JS : r/webdev \- Reddit, accessed on July 25, 2025, [https://www.reddit.com/r/webdev/comments/uj8ivc/wasm\_isnt\_necessarily\_faster\_than\_js/](https://www.reddit.com/r/webdev/comments/uj8ivc/wasm_isnt_necessarily_faster_than_js/)  
42. JavaScript UI Compilers: Comparing Svelte and Solid | by Ryan Carniato \- Medium, accessed on July 25, 2025, [https://ryansolid.medium.com/javascript-ui-compilers-comparing-svelte-and-solid-cbcba2120cea](https://ryansolid.medium.com/javascript-ui-compilers-comparing-svelte-and-solid-cbcba2120cea)  
43. Guide: Islands \- Leptos Book, accessed on July 25, 2025, [https://book.leptos.dev/islands.html](https://book.leptos.dev/islands.html)  
44. Web Frameworks » AWWY?, accessed on July 25, 2025, [https://www.arewewebyet.org/topics/frameworks/](https://www.arewewebyet.org/topics/frameworks/)  
45. Exploring the top Rust web frameworks \- LogRocket Blog, accessed on July 25, 2025, [https://blog.logrocket.com/top-rust-web-frameworks/](https://blog.logrocket.com/top-rust-web-frameworks/)  
46. What Is Yew Framework? \- Next LVL Programming \- YouTube, accessed on July 25, 2025, [https://www.youtube.com/watch?v=VIWcJvPoeM8](https://www.youtube.com/watch?v=VIWcJvPoeM8)  
47. Dioxus | Fullstack crossplatform app framework for Rust, accessed on July 25, 2025, [https://dioxuslabs.com/](https://dioxuslabs.com/)  
48. What is the most fully-featured rust frontend framework? \- Reddit, accessed on July 25, 2025, [https://www.reddit.com/r/rust/comments/12xhccz/what\_is\_the\_most\_fullyfeatured\_rust\_frontend/](https://www.reddit.com/r/rust/comments/12xhccz/what_is_the_most_fullyfeatured_rust_frontend/)  
49. Guides \- Dioxus | Fullstack crossplatform app framework for Rust, accessed on July 25, 2025, [https://dioxuslabs.com/learn/0.6/guides/](https://dioxuslabs.com/learn/0.6/guides/)  
50. Leptos Web Framework \- Build fast web applications with Rust \- Eric David Smith, accessed on July 25, 2025, [https://ericdavidsmith.com/blog/software/leptos-web-framework](https://ericdavidsmith.com/blog/software/leptos-web-framework)  
51. Frequently Asked Questions \- Sycamore, accessed on July 25, 2025, [https://sycamore-rs.netlify.app/docs/v0.6/getting\_started/faq](https://sycamore-rs.netlify.app/docs/v0.6/getting_started/faq)  
52. Which web framework do you use in Rust? \- Reddit, accessed on July 25, 2025, [https://www.reddit.com/r/rust/comments/18ogwtl/which\_web\_framework\_do\_you\_use\_in\_rust/](https://www.reddit.com/r/rust/comments/18ogwtl/which_web_framework_do_you_use_in_rust/)