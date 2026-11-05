Read CLAUDE.md, content/AUTHORING.md, and SPEC sections 14.3, 18 and 19 in docs/SPEC.md first. Do Part 1, then Part 2. Don't stop to ask for my approval or show me samples. Keep going until all 182 articles are done.

PART 1: AUTOMATIC SEEDING ON ANY NEW DATABASE
Goal: when the API starts against any new, empty database, in any environment including Production, it creates the schema and seeds everything with no manual command. That includes every article in content/articles: the existing 300 and the 182 new ones.

1. Make Database:MigrateOnStartup and Seed:RunOnStartup true by default in every environment. Keep the manual `seed [--force]` command.
2. Include the content/ folder in `dotnet publish` and in the container image, and make Content:RootPath default to it, so Production doesn't need the repo.
3. Keep the seeder idempotent:
   - Later starts must never duplicate an article.
   - A re-import may change only an article's content and metadata, never its reactions, comments, saves or reads.
   - Adding a new folder under content/articles must be enough for that article to be seeded on the next start.
4. Demo users and demo data stay out of Production.
5. If a seeder fails, stop the start with a clear error, like a failed migration.
6. Verify this for real:
   - Publish to a separate folder and run it with Production settings against an empty database.
   - Confirm the published article count under @readin matches the number of published articles in content/articles.
   - Confirm @readin has its verified badge.
   - Start it again and confirm the count doesn't change.
   - Report how long the first start takes.
7. Update docs/setup/deployment.md, including the settings I must provide (such as Seed:SuperAdminPhone and Seed:SuperAdminPassword) and the health check allowance for a slow first start.

PART 2: WRITE THE ARTICLES
Write one article for every topic in docs/advanced-article-topics.md (182 topics).

Two versions of every article:
1. English (en.json): written entirely in English.
2. Egyptian Arabic (ar-EG.json): written in natural Egyptian dialect, the way an experienced Egyptian engineer explains something to a colleague.
   - It must not be a literal translation of the English version. Rewrite the sentences and examples so they read as if they were written in Egyptian Arabic first, while keeping the same facts, sections and code.
   - Keep technical terms in English, such as Connection Pool, Deadlock, Garbage Collector and Load Balancer. Don't translate them or write them in Arabic letters. Add a short Egyptian explanation the first time a difficult term appears.
   - Don't use formal Arabic (فصحى) or heavy slang. Any Arabic reader should understand it.
   - If a sentence sounds translated, rewrite it. This is the most important quality rule for the Arabic version.

Article rules:
- Follow content/AUTHORING.md: author @readin, "isAiAssisted": true, "level": "advanced".
- Add each article to plannedArticles in content/taxonomy.yaml first. If no topic fits, add a new one, such as operating-systems or data-analysis, and record which field you put it under.
- Write for experienced readers. Skip the basics, go into the internals, use a real example, and say when the approach is the wrong choice.
- Use 2 to 5 official or primary sources per article. Don't state a number or behavior that isn't in a source. Name the version the article applies to.
- Don't repeat an existing article in content/articles. If a topic overlaps one, link to it.
- Security topics: explain the flaw and how to defend against it, with no ready-to-use attack steps against real systems.

Images:
- Don't create custom images, diagrams or SVGs. They would take too long.
- Use only the standard cover from `node tools/content-covers/render.mjs --slug <slug>`, because validation requires cover.webp.

Process:
- Write all 182 articles in one continuous run, with no pause for my review. Use at most 3 agents at a time. Only you edit taxonomy.yaml.
- For each article, run compose, validate and render.mjs. An article isn't done until validate passes, including the code and link checks.
- Update any test or SPEC text that depends on the number 300 to the new total.

Repo rules for both parts:
- Work directly on dev in D:\freelancer\ReadIn, with no branches or worktrees. Don't touch main, don't force-push, and don't push ios-* tags. Never commit secrets.
- Another session works in this folder. Commit only your own files, by path. Use --artifacts-path if dotnet reports a file in use.
- After Part 1 and after every 10 finished articles: commit, push to dev, and update docs/handoff/PROGRESS.md with what's done, so any session can continue if this one stops.
- If an article fails validation and you can't fix it, or something else blocks you, record it in PROGRESS.md and continue with the next article.

When everything is done, send me a final report in simple Egyptian Arabic: how many articles are finished, any that failed and why, the new total, and what you need from me.

# Advanced Article Topics

Topics for advanced ReadIn articles, written for readers who already have experience in the field. None of them repeats an existing article in `content/articles`.

## Contents

| Section | Topics |
|---|---:|
| [Databases](#databases) | 17 |
| [Flutter and Dart](#flutter-and-dart) | 17 |
| [DevOps](#devops) | 7 |
| [Docker](#docker) | 15 |
| [Kubernetes](#kubernetes) | 22 |
| [Operating Systems](#operating-systems) | 15 |
| [Programming](#programming) | 2 |
| [Machine Learning](#machine-learning) | 16 |
| [Data Analysis](#data-analysis) | 16 |
| [Security](#security) | 16 |
| [System Design](#system-design) | 39 |
| **Total** | **182** |

## Databases

1. **MVCC internals:** row versions, VACUUM, and why tables bloat in PostgreSQL.
2. **WAL and crash recovery:** how data comes back after a power failure (ARIES and checkpoints).
3. **B-Tree page splits:** the fill factor and the real cost of writes.
4. **LSM-Trees vs B-Trees:** compaction and read, write, and space amplification.
5. **Write skew and SSI:** the problem with Snapshot Isolation and how PostgreSQL detects it.
6. **Join algorithms:** how the optimizer chooses between Hash, Merge, and Nested Loop.
7. **Correlated columns:** why estimates go wrong and how multi-column statistics help.
8. **Partitioning traps:** pruning, unique indexes, and when partitioning makes queries slower.
9. **Sharding and resharding:** consistent hashing, hot keys, and cross-shard transactions.
10. **Raft in databases:** quorum reads and leader leases.
11. **Replication anomalies:** read-your-writes, monotonic reads, and logical vs physical replication.
12. **Change Data Capture (CDC):** reading the WAL with Debezium, and ordering and duplication problems.
13. **Zero-downtime migrations:** expand/contract, changing a database under real load, and the lock queue that takes production down.
14. **Locks vs latches:** lock escalation, tempdb, and the version store in SQL Server.
15. **Columnstore:** vectorized execution and why OLAP is so much faster.
16. **Connection pooling:** PgBouncer transaction mode and choosing the right pool size.
17. **Spanner and TrueTime:** external consistency using clocks.

## Flutter and Dart

1. **Render pipeline:** from build to layout, paint, and composite, and writing your own `RenderBox`.
2. **Slivers internals:** `SliverConstraints`, `SliverGeometry`, and writing a custom sliver.
3. **Impeller vs Skia:** the shader jank problem and how it was solved.
4. **Reading the DevTools timeline:** diagnosing real jank step by step.
5. **`saveLayer` and `RepaintBoundary`:** the hidden cost and when they hurt instead of help.
6. **Dart GC:** the young space, the scavenger, and how allocations cause jank.
7. **Isolates:** the memory model, the cost of transfers, and `TransferableTypedData`.
8. **AOT and JIT:** the kernel, tree shaking, and analyzing app size.
9. **Scheduler:** frame phases, `Ticker`, and vsync.
10. **Gesture arena:** hit testing and resolving gesture conflicts.
11. **Platform Views:** Hybrid Composition vs Texture Layer and what each costs.
12. **`dart:ffi`:** `NativeCallable`, finalizers, threads, and zero-copy.
13. **Fragment shaders:** custom effects with `FragmentProgram`.
14. **Image memory:** `cacheWidth`, the image cache, and tracking leaks.
15. **Offline sync conflicts:** last-write-wins, CRDTs, and background sync.
16. **Add-to-app:** multiple engines and embedding Flutter in a native app.
17. **Semantics tree:** accessibility in custom painters.

## DevOps

1. **GitOps:** drift and secrets in Argo CD and Flux.
2. **Progressive delivery:** automated canaries that stay compatible with migrations.
3. **Terraform state:** locking, drift, and blast radius.
4. **Supply chain security:** SLSA, cosign, and SBOMs.
5. **eBPF:** observing production without changing code.
6. **OpenTelemetry sampling:** tail vs head sampling and the danger of high cardinality.
7. **Linux performance:** the USE method and flame graphs.

## Docker

1. **A container from scratch:** namespaces, cgroups v2, overlayfs, and `pivot_root`, with no Docker at all.
2. **Docker's components:** dockerd, containerd, runc, and shim, and what each one does.
3. **OverlayFS:** copy-up and why writing inside a container can slow down a database.
4. **PID 1:** signals, zombie processes, and why `docker stop` takes 10 seconds.
5. **Docker networking:** bridge, veth, iptables, and how the internal DNS works.
6. **BuildKit:** cache mounts, secrets, and remote cache in CI.
7. **Multi-arch images:** manifest lists, QEMU, and cross-compilation.
8. **Distroless and scratch:** shrinking the image and what it costs in debugging.
9. **OCI image internals:** the manifest, config, layers, and digest.
10. **Container security:** capabilities, seccomp, AppArmor, user namespaces, and rootless.
11. **Container escapes:** why `--privileged` and `docker.sock` are the same as root on the host.
12. **OOM in containers:** exit code 137, the page cache, and why the memory limit is misunderstood.
13. **Runtimes in containers:** how .NET, the JVM, and Node read cgroup limits.
14. **Storage drivers and volumes:** performance, permissions, and UID mapping.
15. **Logging drivers:** how logs can fill the disk or stall the application.

## Kubernetes

1. **Pod internals:** from `kubectl apply` until the container runs, step by step.
2. **Kubernetes scheduler:** filtering, scoring, affinity, taints, topology spread, and preemption.
3. **CPU throttling:** the CFS quota, how CPU limits quietly hurt latency, and whether to remove them at all.
4. **Kubernetes networking:** CNI and every path a packet takes from Pod to Pod.
5. **kube-proxy vs eBPF:** iptables, IPVS, Cilium, and conntrack exhaustion.
6. **CoreDNS:** `ndots:5` and why DNS adds hidden latency.
7. **Graceful shutdown:** `SIGTERM`, `preStop`, the race with EndpointSlices, and why 502s appear during a deploy.
8. **etcd:** Raft, compaction, size limits, and why the control plane goes down.
9. **Watch and Informers:** list-watch, `resourceVersion`, and the shared cache.
10. **API priority:** API Priority and Fairness, admission webhooks, and how one webhook can take down a cluster.
11. **Operators and CRDs:** reconcile loops, idempotency, finalizers, and common mistakes.
12. **QoS and eviction:** Guaranteed, Burstable, and BestEffort, and who gets evicted first.
13. **Autoscaling:** HPA, VPA, KEDA, and Karpenter, metric lag, cold starts, and why they react late under pressure.
14. **StatefulSets:** ordering, PVCs, and when running a database on them is a mistake.
15. **PodDisruptionBudgets:** drains, upgrades, and how a bad PDB blocks an upgrade.
16. **Deployment rollouts:** `maxSurge`, `maxUnavailable`, and why a rollout gets stuck.
17. **RBAC and tokens:** ServiceAccounts and the attack path from a compromised Pod to the whole cluster.
18. **NetworkPolicy:** why the default is open and how to lock it down without breaking anything.
19. **Secrets:** why base64 isn't encryption, etcd encryption, and External Secrets.
20. **Service mesh:** sidecar vs ambient and when it isn't worth the cost.
21. **Multi-tenancy:** why namespaces aren't real isolation, and the alternatives.
22. **Diagnosing CrashLoopBackOff:** from events to exit codes to ephemeral containers.

## Operating Systems

1. **Virtual memory:** page tables, the TLB, page faults, and why RSS misleads you.
2. **Linux scheduler:** CFS, EEVDF, and the real cost of a context switch.
3. **Page cache:** `fsync`, dirty pages, and why a `write` doesn't mean the data is saved.
4. **`mmap`:** when it beats `read` and why databases avoid it.
5. **System calls:** the switch into the kernel, its cost, and the vDSO.
6. **Kernel locks:** spinlocks, futexes, and priority inversion.
7. **`fork` and copy-on-write:** why Redis uses extra memory during a snapshot.
8. **`epoll` and `io_uring`:** real async I/O, thread pool starvation, and how one server handles a million connections.
9. **Filesystem internals:** inodes, journaling, and safe writes during a power failure.
10. **OOM killer:** overcommit and how it chooses what to kill.
11. **NUMA:** why a powerful server can end up slower.
12. **TCP in the kernel:** the backlog, `TIME_WAIT`, buffers, and how they take a server down.
13. **Signals:** why handlers are dangerous, and the classic `SIGTERM` mistakes.
14. **Virtualization:** the hypervisor, VT-x, and an honest comparison with containers.
15. **Boot process:** from pressing the power button to `systemd`.

## Programming

1. **False sharing:** the CPU cache and data-oriented design.
2. **Memory models:** happens-before, atomics, and the ABA problem.

## Machine Learning

1. **Gradient boosting internals:** XGBoost, LightGBM, and how a tree gets built.
2. **Probability calibration:** Platt scaling, isotonic regression, and measuring ECE.
3. **SHAP:** the mathematical basis and when it misleads you.
4. **Causal ML:** uplift modeling and double ML.
5. **Bayesian optimization:** why it beats grid search, and when it doesn't.
6. **Conformal prediction:** real confidence intervals for any model.
7. **Data drift and concept drift:** PSI, detection, and responding in production.
8. **Feature stores:** training-serving skew and point-in-time joins.
9. **Time series:** walk-forward validation and leakage in lag features.
10. **Ranking models:** LambdaMART, NDCG, and building a feed like ReadIn's.
11. **Recommender systems:** two-tower models, cold start, and feedback loops.
12. **Backpropagation from scratch:** autograd and vanishing gradients.
13. **Optimizers:** Adam vs SGD and learning rate schedules.
14. **Quantization and pruning:** shrinking a model and what it costs in accuracy.
15. **Fairness:** conflicting metrics and why you can't satisfy them all.
16. **Adversarial examples:** why small changes fool models.

## Data Analysis

1. **A/B testing done right:** power, sample size, and peeking.
2. **Simpson's paradox:** why aggregate numbers can lie.
3. **p-value:** what it doesn't mean, and p-hacking.
4. **Bootstrap:** confidence intervals without formulas.
5. **Bayesian vs Frequentist:** how to choose in practice.
6. **Survivorship and selection bias:** examples that led companies to bad decisions.
7. **Cohorts and retention:** analyzing them correctly and why MAU is misleading.
8. **Funnel analysis:** attribution and the conversion illusion.
9. **Advanced window functions:** sessionization and gaps and islands in SQL.
10. **Pandas internals:** memory, copy-on-write, and when to move to Polars.
11. **DuckDB:** analyzing millions of rows on a laptop.
12. **Parquet internals:** columnar storage and predicate pushdown.
13. **Outliers:** when to remove them and when they're the most important part of the data.
14. **Missing data:** MCAR, MAR, and MNAR, and why each needs different handling.
15. **Difference-in-differences:** measuring impact without an experiment.
16. **Data visualization lies:** how a chart can mislead without saying anything false.

## Security

1. **JWT attacks:** algorithm confusion, `none`, and key injection.
2. **OAuth attacks:** redirect URIs, PKCE, and token leakage.
3. **Passkeys and WebAuthn:** how they work and why they stop phishing.
4. **Session attacks:** fixation and refresh token reuse.
5. **TLS 1.3 internals:** the handshake and forward secrecy.
6. **Timing attacks:** leaking secrets through response time.
7. **Race conditions as vulnerabilities:** TOCTOU and redeeming a coupon 100 times.
8. **Prompt injection:** the security of LLM applications and agents.
9. **HTTP request smuggling:** disagreements between the proxy and the server.
10. **Deserialization attacks:** from JSON to remote code execution.
11. **Supply chain attacks:** dependency confusion and typosquatting.
12. **Practical threat modeling:** STRIDE on a real application.
13. **Business logic flaws:** the vulnerabilities scanners can't see.
14. **Encryption done right:** AES-GCM, nonce reuse, and envelope encryption.
15. **Mobile security:** certificate pinning, root detection, and their limits.
16. **Incident response:** the first 24 hours after a breach.

## System Design

### Foundations

1. **Back-of-the-envelope estimates:** load, storage, and cost before you design.
2. **Latency budgets:** dividing an SLO across every service in a request.
3. **Tail latency:** fan-out and why one service's p99 becomes the system's p50.
4. **Queueing theory:** why a system suddenly collapses at around 80% load.
5. **PACELC:** what CAP doesn't tell you about latency.
6. **Consistency models:** linearizable, sequential, and causal, with real examples.

### Data and Scale

7. **Consistent hashing:** virtual nodes and redistributing data.
8. **Hot keys:** the celebrity account problem and its solutions.
9. **Replication strategies:** leader-follower, multi-leader, and leaderless.
10. **Quorums:** R + W > N and why it doesn't guarantee everything.
11. **Conflict resolution:** last-write-wins, vector clocks, and CRDTs.
12. **Distributed IDs:** Snowflake, ULID, UUIDv7, and the clock problem.
13. **Multi-region:** active-active, where user data lives, RTO and RPO, split brain, and chaos engineering.
14. **Cache stampede:** request coalescing, jitter, and stale-while-revalidate.

### Service Communication

15. **Kafka internals:** partitions, consumer groups, and ordering.
16. **Queues vs event logs:** when to use RabbitMQ and when to use Kafka.
17. **Event sourcing:** its real benefits and the costs nobody mentions.
18. **Backpressure:** stopping a collapse before it spreads.
19. **Distributed rate limiting:** token bucket and sliding window across servers.
20. **API Gateway and BFF:** when they help and when they become a point of failure.
21. **gRPC vs REST vs GraphQL:** choosing based on the problem.
22. **API idempotency:** idempotency keys in payments.

### Reliability

23. **Failure modes:** cascading failures, blast radius, and cell-based architecture.
24. **Circuit breakers:** when they protect you and when they make things worse.
25. **Leader election:** leases, fencing tokens, and split brain.
26. **Distributed locks:** why Redlock is controversial, and the alternative.
27. **Metastable failures:** retry storms, load shedding, and why a system stays down after the cause is gone.

### Real System Designs

28. **URL shortener:** in depth, not the interview version.
29. **News feed:** fan-out on write vs read and the celebrity problem.
30. **Chat like WhatsApp:** WebSockets, ordering, and delivery.
31. **Notifications:** millions of notifications without duplicates.
32. **Search autocomplete:** tries, ranking, and latency.
33. **Payment system:** the double-entry ledger and reconciliation.
34. **Ride sharing:** geospatial indexes and location updates.
35. **Video streaming:** adaptive bitrate and CDNs.
36. **Collaborative editing:** OT vs CRDTs, like Google Docs.
37. **Ticket booking:** preventing double booking during a rush.
38. **Metrics system:** time-series storage and downsampling.
39. **Web crawler:** politeness and deduplication at scale.
