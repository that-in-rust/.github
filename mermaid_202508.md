# Architecture 1: Traditional Multi-Threaded Async I/O (Rust + OS Scheduler)

``` mermaid
flowchart TB
    main(Main Thread) -->|spawn 10 copy tasks| t1[Thread1: Copy File1]
    main -->|spawn| t2[Thread2: Copy File2]
    main -->|...| tN[Threads 3-10: Copy File3...File10]
    %% Threads perform I/O on shared disk
    t1 -- read/write --> Disk[(Disk / File System)]
    t2 -- read/write --> Disk
    tN -- read/write --> Disk
    %% Threads signal completion back to main
    t1 -->|done| main
    t2 -->|done| main
    tN -->|done| main

```
