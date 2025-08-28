# Situation till 202508

We said we want to rewrite software in Rust because it offers fearless concurrency, memory safety, and zero-cost abstraction

So we started with thinking of writing applications or libraries which
- were rewrites of existing proven libraries or applications
- were new Rust implementations of a gap in the Rust ecosystem

But we realized that the linux kernel itself is a big hindrance to leveraging the maximal capabilities of Rust because it has jitter which takes away the advantage of fearless concurrency

