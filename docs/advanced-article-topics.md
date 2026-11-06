Read CLAUDE.md, content/AUTHORING.md, and SPEC sections 14.3, 18 and 19 in docs/SPEC.md first. Do Part 1, then Part 2. Don't stop to ask for my approval or show me samples. Keep going until all 352 articles are done.

PART 1: AUTOMATIC SEEDING ON ANY NEW DATABASE
Goal: when the API starts against any new, empty database, in any environment including Production, it creates the schema and seeds everything with no manual command. That includes every article in content/articles: the existing 300 and the 352 new ones.

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
Write one article for every topic in docs/advanced-article-topics.md (352 topics).

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
- Psychology topics: add a `psychology` topic under the `science` field and use peer-reviewed sources. Say plainly when the evidence is weak, disputed or failed to replicate. Give no diagnosis or treatment advice, and tell readers with a real problem to see a specialist.
- Relationship topics: use the same `psychology` topic and the same rules. Say when a study's samples are mostly Western and may not apply everywhere. Never tell a reader to stay in or leave a relationship. In any topic that touches abuse, safety comes first, and readers are told to seek qualified local help. Don't invent phone numbers or organizations. Attachment styles are tendencies, not diagnoses or fixed labels, so articles must not present them as a way to diagnose yourself or your partner.
- Public health topics: use the `public-health` field, with a new topic where needed. Use sources such as WHO, national health agencies and peer-reviewed research, and give the year of any number, since these figures change. Give no personal medical advice, and tell readers to ask a doctor about their own case.
- Everyday Health topics: these are the exception to "level": "advanced" and to skipping the basics. Use `public-health`, "level": "intermediate", and practical language for general readers, with the Public Health rules above. Give no medicine or supplement doses, and send readers to a doctor or pharmacist for those. Don't promise cures, and call out popular claims the evidence doesn't support.
- Business and Commerce topics: these are also an exception to "level": "advanced". Use the `business` field with one topic per section below, "level": "intermediate", and practical language for students and new graduates. Use the Egyptian context where it fits, naming the law or standard and its year, because laws, tax rates and prices change. Give no personal investment, tax or legal advice, promise no profits, and tell readers to ask a qualified accountant or lawyer about their own case.
- Engineering topics: use the `engineering` field, with one topic for each engineering branch below. Explain the principles and name the relevant standards where you can. Give no step-by-step instructions for dangerous work, such as high voltage, pressure vessels or chemical reactions, and say when a licensed engineer is required.

Images:
- Don't create custom images, diagrams or SVGs. They would take too long.
- Use only the standard cover from `node tools/content-covers/render.mjs --slug <slug>`, because validation requires cover.webp.

Process:
- Write all 352 articles in one continuous run, with no pause for my review. Use at most 3 agents at a time. Only you edit taxonomy.yaml.
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
| [Psychology](#psychology) | 20 |
| [Psychology of Relationships](#psychology-of-relationships) | 20 |
| [Attachment and Relationships](#attachment-and-relationships) | 20 |
| [Public Health](#public-health) | 20 |
| [Everyday Health](#everyday-health) | 20 |
| [Engineering](#engineering) | 30 |
| [Business and Commerce](#business-and-commerce) | 40 |
| **Total** | **352** |

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

## Psychology

1. **The replication crisis:** what failed to replicate, why effect sizes shrink, preregistration, and how to read a psychology study.
2. **Dual-process theory:** System 1 and System 2, and why many researchers think the split is too simple.
3. **Prospect theory:** reference points, loss aversion, and the debate over how large the effect really is.
4. **Working memory:** Baddeley's model, Cowan's capacity limit, and why "7 ± 2" is out of date.
5. **Cognitive load theory:** intrinsic and extraneous load, and the expertise reversal effect.
6. **Retrieval practice and spacing:** the testing effect, the forgetting curve, and desirable difficulties.
7. **Predictive processing:** the brain as a prediction machine, and what the evidence doesn't show yet.
8. **Dopamine and reward prediction error:** variable rewards, and what "dopamine detox" gets wrong.
9. **Habit formation:** context cues, habitual vs goal-directed behavior, and why "21 days" is a myth.
10. **Ego depletion:** how the willpower-as-a-resource idea failed large replications.
11. **Self-determination theory:** autonomy, competence, relatedness, and when rewards reduce motivation.
12. **Adult attachment:** what the research supports and what the popular version gets wrong.
13. **Stress physiology:** the HPA axis, allostatic load, and the limits of the Yerkes-Dodson curve.
14. **False memories:** reconsolidation, Loftus's experiments, and why memory isn't a recording.
15. **Conformity and obedience:** Asch, new readings of Milgram, and the critiques of the Stanford Prison Experiment.
16. **Implicit bias and the IAT:** reliability, and what the test can and can't predict.
17. **Personality science:** the Big Five and HEXACO, how stable traits are, and why MBTI is weak science.
18. **Task switching:** the real cost of interruptions, attention residue, and the myth of multitasking.
19. **Burnout:** Maslach's model, its overlap with depression, and why the causes are often in the workplace.
20. **The Dunning-Kruger effect:** the original finding, and the argument that much of it is a statistical artifact.

## Psychology of Relationships

1. **The Four Horsemen:** criticism, contempt, defensiveness, and stonewalling, and how far Gottman's divorce predictions really hold up.
2. **The demand-withdraw pattern:** why one partner pushes, the other pulls away, and each reaction feeds the other.
3. **Repair attempts:** how couples recover during a fight, and positive sentiment override.
4. **Perceived partner responsiveness:** why feeling understood and cared for predicts relationship quality.
5. **Capitalization:** how you respond to your partner's good news, and why it can matter as much as support in hard times.
6. **The anxious-avoidant cycle:** how two attachment styles trigger each other in a marriage.
7. **The investment model:** satisfaction, alternatives, and investment, and why people stay or leave.
8. **The vulnerability-stress-adaptation model:** why outside stress changes how couples treat each other.
9. **Dyadic coping:** how partners handle stress together, and how work stress spills into the home.
10. **Marital satisfaction over time:** the decline after the honeymoon, and the debate over the U-shaped curve.
11. **The transition to parenthood:** what changes in a marriage after a first child, and what protects it.
12. **Household labor and fairness:** the mental load, and why perceived fairness can matter more than exact shares.
13. **Money conflict:** why arguments about money run hotter and last longer, and what they are really about.
14. **Family of origin and in-laws:** Bowen's differentiation of self, and setting boundaries while staying close.
15. **Forgiveness:** what it is and isn't, and when forgiving can make things worse.
16. **Jealousy and digital monitoring:** what the research says about checking a partner's phone, and how trust erodes.
17. **Desire discrepancy:** different levels of sexual desire in long-term relationships, and how couples talk about it.
18. **The five love languages:** a popular idea tested against the research.
19. **Couples therapy:** the evidence for Emotionally Focused and Integrative Behavioral Couple Therapy, what they can't fix, and when they aren't suitable.
20. **Coercive control:** how abuse differs from ordinary conflict, and why safety comes before couples therapy.

## Attachment and Relationships

### Attachment and Its Types

1. **Bowlby's attachment theory:** its evolutionary roots and internal working models.
2. **The Strange Situation:** how Ainsworth identified secure, avoidant, and ambivalent infants, and the critiques of the test.
3. **Disorganized attachment:** what Main and Solomon found, and why it must not be used to judge parents.
4. **Types or dimensions:** why the research treats adult attachment as levels of anxiety and avoidance, not fixed boxes.
5. **Secure attachment:** the secure base and safe haven, and why secure doesn't mean perfect.
6. **Anxious attachment:** hyperactivating strategies, protest behavior, and the fear of abandonment.
7. **Dismissive-avoidant attachment:** deactivating strategies, and what the studies show about emotions kept out of sight.
8. **Fearful-avoidant attachment:** wanting closeness and fearing it, its links to early adversity, and the limits of the evidence.
9. **Stability and change:** how much attachment shifts over life, and what "earned security" means.
10. **Measuring attachment:** the Adult Attachment Interview vs self-report scales, and why they often disagree.
11. **Passing attachment across generations:** parental sensitivity and the "transmission gap".
12. **Genes and attachment:** what twin studies show from infancy to adolescence.
13. **Attachment across cultures:** the debate over whether the theory is universal.
14. **Oxytocin:** what the research shows about bonding, and why "the love hormone" is misleading.

### Relationships

15. **Attachment injuries:** how a moment of betrayal damages trust, and how couples work to rebuild it.
16. **Breakups:** grief, rumination, and what recovery looks like over time.
17. **Infidelity:** what predicts it, what recovery looks like, and the problem with the data.
18. **Perpetual problems:** the claim that most couple conflicts never get solved, and what the evidence behind it is.
19. **Trauma bonding:** what the research supports, what the popular term gets wrong, and why safety comes first.
20. **Self-expansion:** why new experiences together can keep a long relationship alive.

## Public Health

1. **Study designs:** cohort, case-control, and randomized trials, and how each one can mislead.
2. **R0 and Rt:** what reproduction numbers really measure and how they get misread.
3. **Herd immunity:** why the threshold isn't one fixed number.
4. **Vaccine efficacy vs effectiveness:** how each is measured, and what waning protection means.
5. **Screening and base rates:** false positives, overdiagnosis, and why testing everyone can backfire.
6. **Nutrition epidemiology:** confounding, self-reported diets, and why food studies keep contradicting each other.
7. **Relative vs absolute risk:** how headlines make a small risk sound huge.
8. **Antimicrobial resistance:** how it spreads between people, animals, and the environment, and the One Health approach.
9. **Social determinants of health:** how income, education, and housing affect health.
10. **Air pollution:** how PM2.5 harms the body, and what the dose-response evidence shows.
11. **Water and sanitation:** what clean water and sanitation achieved, and where they fall short.
12. **Obesity at population level:** the food environment, and the evidence on sugar taxes and labeling.
13. **Tobacco control:** which policies worked, and the dispute over vaping.
14. **Egypt's hepatitis C program:** how national screening and treatment worked at scale.
15. **Health misinformation:** why it spreads, and the evidence for prebunking.
16. **Disease surveillance:** sentinel sites, syndromic data, and wastewater monitoring.
17. **Heat and health:** how heat waves kill, who is most at risk, and what adaptation works.
18. **Mental health at population scale:** measuring prevalence, stigma, and task-sharing.
19. **QALYs and DALYs:** how health systems compare interventions, and the ethics of those comparisons.
20. **Pandemic measures:** what the evidence from COVID-19 shows about masks, closures, and communication.

## Everyday Health

### Immunity

1. **"Boosting" your immunity:** what the phrase gets wrong, what really supports the immune system, and why an overactive one is a problem too.
2. **Immunity supplements:** what the evidence says about vitamin C, vitamin D, and zinc, and when they can harm.
3. **Sleep and immunity:** what lost sleep does to your defenses.
4. **Exercise and infections:** how regular activity helps, and the debate over hard training.
5. **Chronic stress and immunity:** how long-term stress changes the immune response.
6. **Gut bacteria and probiotics:** what is known, and where the marketing runs ahead of the science.
7. **Adult vaccines:** why vaccination doesn't end in childhood, and how to ask your doctor what you need.

### Smoking

8. **What smoking does to the body:** cancer, heart, lungs, and the less known effects.
9. **What happens after you quit:** how the body recovers over hours, months, and years.
10. **Nicotine addiction:** why quitting is hard, and what withdrawal really is.
11. **How to quit smoking:** what the evidence says about counseling, nicotine replacement, and prescription medicines.
12. **Relapse:** triggers, slips, and why one failed attempt doesn't mean you can't quit.
13. **Shisha:** why the water doesn't make it safe, and how it compares with cigarettes.
14. **Vaping and heated tobacco:** what is known about the risks, for smokers and for people who never smoked.
15. **Secondhand smoke:** the effects on children, pregnancy, and people who live with smokers.

### Daily Health

16. **High blood pressure:** why it is silent, how to measure it at home correctly, and the role of salt.
17. **Preventing type 2 diabetes:** what prediabetes means, and what prevention trials showed about lifestyle change.
18. **Physical activity:** what WHO recommends, and the risks of sitting too long.
19. **Sleep:** how much adults need, and what the evidence says about improving it.
20. **Antibiotics:** when they don't help, and the harm of taking them without a prescription.

## Engineering

### Mechanical Engineering

1. **Fatigue failure:** S-N curves, and why parts break well below their yield strength.
2. **Tribology:** friction, wear, lubrication regimes, and the Stribeck curve.
3. **Heat exchanger design:** LMTD vs ε-NTU, fouling, and the real trade-offs.

### Electrical Engineering

4. **Power system stability:** frequency, inertia, and how cascading blackouts happen.
5. **Power electronics:** IGBT vs SiC, switching losses, and inverter design.
6. **Renewables on the grid:** grid-following vs grid-forming inverters.

### Civil Engineering

7. **Reinforced concrete durability:** cracking, chloride attack, and rebar corrosion.
8. **Seismic design:** ductility, base isolation, and why buildings are designed to be damaged but not collapse.
9. **Soil liquefaction:** how solid ground behaves like a liquid, and what it means for foundations.

### Chemical Engineering

10. **Thermal runaway in reactors:** heat balance, past industrial disasters, and layers of protection.
11. **Distillation:** McCabe-Thiele, azeotropes, and why it consumes so much energy.
12. **Catalyst deactivation:** poisoning, sintering, and fouling, with Haber-Bosch as an example.

### Aerospace Engineering

13. **Transonic flight:** shock waves, wave drag, and supercritical wings.
14. **Orbital mechanics:** delta-v, Hohmann transfers, and gravity assists.
15. **Flutter:** how airflow and structure feed each other, and how it is tested safely.

### Biomedical Engineering

16. **MRI physics:** spin, T1 and T2, and how a signal becomes an image.
17. **Implant biocompatibility:** the foreign body response, and why materials fail inside the body.
18. **Medical device safety:** Therac-25, risk management, and safety-critical software.

### Materials Engineering

19. **Creep and superalloys:** why turbine blades survive near their melting point.
20. **Lithium-ion degradation:** SEI growth, lithium plating, and dendrites.
21. **Composite failure:** delamination, and why damage can be invisible.

### Industrial Engineering

22. **Theory of Constraints:** bottlenecks, and queueing in real factories.
23. **Statistical process control:** control charts, process capability, and the limits of Six Sigma.
24. **Reliability engineering:** the bathtub curve, Weibull analysis, and FMEA.

### Environmental Engineering

25. **Desalination:** reverse osmosis, its minimum energy limit, and what to do with the brine.
26. **Wastewater treatment:** activated sludge, nutrient removal, and water reuse.
27. **Life cycle assessment:** system boundaries, and why results can be argued either way.

### Control and Robotics Engineering

28. **PID control in practice:** tuning, phase margin, integral windup, and when PID isn't enough.
29. **The Kalman filter:** sensor fusion, its assumptions, and how it fails.
30. **Robot kinematics:** inverse kinematics, singularities, and motion planning.

## Business and Commerce

### Accounting

1. **Profit vs cash:** accrual accounting, and how a profitable company can still run out of cash.
2. **Reading financial statements:** the income statement, balance sheet, and cash flow statement, and how they connect.
3. **Depreciation:** the common methods, and how the choice changes reported profit.
4. **Inventory costing:** FIFO vs weighted average, and why IFRS doesn't allow LIFO.
5. **IFRS and Egyptian Accounting Standards:** how they relate and where they differ.
6. **Auditing:** what an auditor's opinion really means, and what it doesn't promise.
7. **Cost accounting:** fixed and variable costs, and break-even analysis.
8. **CMA, CPA, or ACCA:** what each certificate is for, and how to choose.

### Finance and Investment

9. **Time value of money:** why a pound today is worth more than a pound next year.
10. **NPV vs IRR:** how companies choose projects, and when IRR misleads.
11. **Financial ratios:** liquidity, profitability, and debt, and how to avoid misreading them.
12. **Working capital:** why growing too fast can sink a company.
13. **Stocks, bonds, and funds:** how each one works, and the risk each carries.
14. **Diversification and risk:** why risk and return go together, and what "guaranteed returns" should make you ask.
15. **Interest rates and inflation:** how central bank decisions reach your salary, loans, and savings.
16. **Valuing a startup:** how investors put a number on a company with no profit.

### Marketing

17. **From the 4Ps to the 7Ps:** what the marketing mix means for products and services.
18. **Segmentation and positioning:** why "everyone" isn't a target market.
19. **Customer acquisition cost and lifetime value:** the numbers behind any marketing budget.
20. **Pricing psychology:** anchoring, discounts, and charm prices, and what the evidence supports.
21. **Digital marketing funnels:** awareness to purchase, and how to read ad metrics.
22. **Brand building:** what a brand really is, and how long it takes.

### Management

23. **Porter's Five Forces:** analyzing an industry, and where the model falls short.
24. **SWOT analysis:** why most SWOTs are useless, and how to make one lead to decisions.
25. **KPIs and OKRs:** the difference, and how measuring the wrong thing backfires.
26. **Change management:** why so many change efforts fail.
27. **Project management:** Agile vs Waterfall outside software.

### Human Resources

28. **Hiring:** what predicts job performance, and why unstructured interviews do it poorly.
29. **Pay and motivation:** what money can and can't do, and how pay structures work.
30. **Egyptian labor law basics:** contracts, leave, and termination, as every employee and manager should know them.

### Economics

31. **Inflation:** its causes, how it's measured, and who gets hurt most.
32. **Exchange rates:** what a devaluation does to prices, exports, and companies.
33. **GDP:** what it measures and what it misses.
34. **Supply and demand in real markets:** price controls, shortages, and black markets.

### Tax and Business Law

35. **Tax basics in Egypt:** VAT, income tax, and corporate tax, and how they differ.
36. **E-invoicing in Egypt:** how the system works, and what companies must do.
37. **Choosing a company type:** sole proprietorship, partnership, and LLC, and what each means for your liability.

### Careers

38. **Choosing a specialization:** accounting, finance, marketing, or HR, and what the work is really like.
39. **Your first job:** the Excel and practical skills employers ask of new graduates.
40. **Personal finance for new graduates:** budgeting, saving, and debt on a first salary.
