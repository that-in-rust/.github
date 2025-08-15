

# RustHallows

The next significant leap in software performance necessitates a radical shift away from legacy, general-purpose operating systems and application stacks. The current model, with its monolithic kernels, costly privilege transitions, and abstraction layers that obscure hardware capabilities, has reached a plateau. To overcome this, a fundamental rethinking of the relationship between hardware, operating system, language, and application is essential. We introduce the **RustHallows**, a vertically integrated ecosystem built entirely in Rust, aiming for multiplicative performance gains (targeting 10-40x) through specialized operating system primitives, zero-cost abstractions, and a legacy-free design.

Each and every piece of software should be written in Rust


- Layer 1: **Real time Partition OS**: Inspired by unikernels, real time partitioned micro-kernel, this library operating system provides hardware-level isolation and deterministic, low-latency communication primitives. It prioritizes specialized, high-throughput execution environments over general-purpose functionality. For e.g. if a linux has 6 cores, it will give 4 cores to itself and 2 cores to the linux kernel, thus ensuring that the jittering of the linux kernel is not affecting the performance of the application. And it will run a version of its scheduler which is optimized for that application. Each application or service runs its own protected partition (memory space and CPU time slice) so that a fault in one cannot corrupt others. This will ensure predictable performance for critical tasks. This will improve the latency of the application.
    - Layer 2: Schedulers optimized for different types of applications
        - A scheduler optimized for Backend APIs
        - A scheduler optimized for UI rendering
        - A scheduler optimized for Database
        - A scheduler optimized for Kafka type of messaging
    - Layer 3: Customized applications and relevant frameworks for different type of applications
        - A backend framework inspired by Ruby on Rails, but with a Rust flavor
        - A UI framework inspired by React, but with a Rust flavor, 
            - A browser engine which is optimized for the UI framework DOM-free, HTML-free CSS-free JS-free
        - A database written in Rust for OLAP
        - A database written in Rust for OLTP
        - A messaging framework inspired by Kafka, but with a Rust flavor
    - Layer 4: Customized DSLs based on Parseltongue: A declarative, macro-driven Domain-Specific Language that unifies the entire stack. It acts as the lingua franca for defining services, data schemas, communication channels, and user interfaces, compiling directly to optimized Rust code with no runtime overhead.
        - Parseltongue will be type of RustLite or TypeRuby
            - It will simplify the idiomatic practices of Rust into macros, e.g. limited data types which take the max level of each type e.g. i64, f64, bool, string with the highest quality idiomatic practices of Rust ingrained into the macro language which is verbose to make sure it easily learnt by LLMs e.g. let_cow_var or let_mut_shared_var or some innovative keywords which might be longer but make the code readable
            - Parseltongue will have extensions according to use case
                - Basilisk for Backend APIs (Rails like)
                - Nagini for UI (React like)
                - Slytherin for Kafka like messaging

# Unclassified Ideas for further reasearch

## 