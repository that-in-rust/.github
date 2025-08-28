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
        - Minimal Jitter
        - Maximal predictability of availability of CPU Cores and resources
        - Guaranteed P99.99 percentile latency because predictability of resources

