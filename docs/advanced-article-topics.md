Read CLAUDE.md, content/AUTHORING.md, and SPEC sections 14.3, 18 and 19 in docs/SPEC.md first. Do Part 1, then Part 2. Don't stop to ask for my approval or show me samples. Keep going until all 422 articles are done, starting with the 40 Learning Roadmaps.

PART 1: AUTOMATIC SEEDING ON ANY NEW DATABASE
Goal: when the API starts against any new, empty database, in any environment including Production, it creates the schema and seeds everything with no manual command. That includes every article in content/articles: the existing 300 and the 422 new ones.

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
Write one article for every topic in docs/advanced-article-topics.md (422 topics). The Learning Roadmaps section comes first (see Process).

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
- Learning Roadmaps topics: each one takes a reader from zero to senior in one track. They are the third exception to "level": "advanced": use "level": "beginner", because the reader may start from nothing.
  - Field: put each roadmap in its track's field, under a new `roadmaps` topic ("خريطة التعلم" / "Learning Roadmaps"), for example `dotnet`, `frontend`, `mobile`, `devops-cloud`, `software-architecture`, `security`, `databases`, `machine-learning`, `ai-fundamentals` or `testing`. Tracks with no field of their own (Java, Node.js, Python, Go, PHP, embedded, data analysis and data engineering, and the two Start Here articles) go under `education` with the same topic. Tag every roadmap `roadmap`.
  - Misconception: the most common wrong belief about learning that track, for example that you must finish every course before you build anything, or that knowing the framework is enough.
  - Structure: what the job really involves; then the stages from zero to senior in one `:::steps` block. Each stage says what to learn and why, what to postpone, one project to build, and how to know you're ready for the next stage. Then a books table (title, authors, edition and year, the stage it fits, free or paid), the common mistakes, how to show your work, and a "next on ReadIn" part that links the ReadIn articles and learning paths for each stage.
  - Books: name real books only. Check each title, author and edition on the publisher's page and link to that page, never to a pirated copy. Say when a book is old and which parts still hold, and point to the official free docs where a book has aged (for example angular.dev and react.dev). The books in each topic below are suggestions: drop one you can't verify, or replace it with a better or newer one. Book links don't count toward the 2–5 sources.
  - Give durations only as ranges that depend on hours per week. No salary figures, no job promises and no affiliate links. Name each certification with its official page, and say that exam codes change.
  - Once a book has its own article in Book Summaries, the roadmaps that recommend it link to that summary.
- Book Summaries topics: one article per book that explains its main ideas in your own words, so the reader knows what the book says, whether it's worth their time and where to start in it.
  - Field: the book's closest field (for example `software-architecture`, `testing`, `devops-cloud`, `dotnet` or `frontend`), under a new `book-summaries` topic ("ملخصات كتب" / "Book Summaries"). General and computer science books go under `education` with the same topic. Tag every one `book-summary`. Use the book's own level: "beginner", "intermediate" or "advanced".
  - Misconception: a common wrong belief about the book or its main idea, for example that Clean Code demands four-line functions, or that design patterns should be used wherever they fit.
  - Structure: the book in one paragraph (authors, year, the edition you summarize and the problem it solves); its 5 to 8 key ideas, each with your own example (in code where that helps); what has aged and what critics dispute, with sources; who should read it and who can skip it; which chapters to read first; and the related ReadIn articles and roadmaps.
  - Copyright: summarize in your own words. Quote at most two short sentences in the whole article, in quotation marks with the chapter. Don't copy the book's code, figures, tables or exercises, and don't summarize it chapter by chapter in a way that replaces reading it. Link only to the publisher's or the author's page, never to a pirated copy.
  - Sources: the publisher's or author's page, plus 1 to 4 primary sources for the criticism and updates (the author's own later talks or posts count). Say when a newer edition exists.

Images:
- Don't create custom images, diagrams or SVGs. They would take too long.
- Use only the standard cover from `node tools/content-covers/render.mjs --slug <slug>`, because validation requires cover.webp.

Process:
- Write all 422 articles in one continuous run, with no pause for my review. Use at most 3 agents at a time. Only you edit taxonomy.yaml.
- Priority (user decision, 2026-11-07): write and seed the Learning Roadmaps section first, all 40, before any other section, starting with the full-stack .NET and Angular roadmap. They are the first four batches of 10: each batch is validated, committed, pushed and seeded before the next batch starts. If seeding is blocked, they still come first in the writing order.
- For each article, run compose, validate and render.mjs. An article isn't done until validate passes, including the code and link checks.
- Update any test or SPEC text that depends on the number 300 to the new total.

Repo rules for both parts:
- Work directly on dev in D:\freelancer\ReadIn, with no branches or worktrees. Don't touch main, don't force-push, and don't push ios-* tags. Never commit secrets.
- Another session works in this folder. Commit only your own files, by path. Use --artifacts-path if dotnet reports a file in use.
- After Part 1 and after every 10 finished articles: commit, push to dev, and update docs/handoff/PROGRESS.md with what's done, so any session can continue if this one stops.
- If an article fails validation and you can't fix it, or something else blocks you, record it in PROGRESS.md and continue with the next article.

When everything is done, send me a final report in simple Egyptian Arabic: how many articles are finished, any that failed and why, the new total, and what you need from me.

# Advanced Article Topics

Topics for ReadIn articles. Most are advanced, written for readers who already have experience in the field; Learning Roadmaps, Book Summaries, Everyday Health and Business and Commerce say otherwise. None of them repeats an existing article in `content/articles`.

## Contents

| Section | Topics |
|---|---:|
| [Learning Roadmaps](#learning-roadmaps) (written and seeded first) | 40 |
| [Book Summaries](#book-summaries) | 30 |
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
| **Total** | **422** |

## Learning Roadmaps

**Priority: these 40 are written and seeded before every other section, starting with number 3 (full-stack .NET and Angular), then 1, 2 and 4 to 40 in order.** Each one takes a reader from zero to senior in one track, stage by stage, with the books worth reading at each stage. The rules are under "Learning Roadmaps topics" at the top of this file.

### Start Here

1. **Where to start in software:** the computer science basics every track needs (how a computer runs a program, data structures and algorithms, operating systems, networking and Git), in what order, and what can wait. Books: *Code* (Charles Petzold), *Grokking Algorithms* (Aditya Bhargava), *Computer Systems: A Programmer's Perspective* (Randal E. Bryant, David R. O'Hallaron), *Operating Systems: Three Easy Pieces* (Remzi and Andrea Arpaci-Dusseau, free online), *Computer Networking: A Top-Down Approach* (James Kurose, Keith Ross).
2. **Choosing your track:** what backend, frontend, full-stack, mobile, DevOps, security, data, AI, QA and embedded engineers really do all day, how to pick one, and when to switch. It links to every roadmap in this section. Books: *The Pragmatic Programmer* (David Thomas, Andrew Hunt), *The Software Engineer's Guidebook* (Gergely Orosz).

### Full-Stack

3. **Full-stack .NET and Angular (the first article):** C#, ASP.NET Core Web APIs, EF Core and SQL Server, and authentication; then TypeScript and Angular (signals, RxJS, routing, forms); testing on both sides, deploying both, and one complete project at the end. Books: Mark J. Price's *Modern Cross-Platform Development Fundamentals* (the newest C# and .NET edition), *ASP.NET Core in Action* (Andrew Lock), *Entity Framework Core in Action* (Jon P Smith), *Effective TypeScript* (Dan Vanderkam), *Learning Angular* (Aristeidis Bampakos, Pablo Deeleman).
4. **Full-stack .NET and React:** the same .NET backend path, with React, routing or Next.js, and server data on the front. Books: *ASP.NET Core in Action*, *Entity Framework Core in Action*, *Effective TypeScript*, *Learning React* (Alex Banks, Eve Porcello) next to react.dev.
5. **Full-stack JavaScript and TypeScript:** Node.js with NestJS or Express, PostgreSQL, and React with Next.js: one language from end to end, and where that hurts. Books: *Eloquent JavaScript* (Marijn Haverbeke, free online), *Effective TypeScript*, *Node.js Design Patterns* (Mario Casciaro, Luciano Mammino), *Fluent React* (Tejas Kumar).
6. **Full-stack PHP with Laravel and Vue:** modern PHP, Laravel (Eloquent, queues and testing), MySQL, and Vue with Inertia or Livewire. Books: *PHP & MySQL: Server-side Web Development* (Jon Duckett), *Laravel: Up & Running* (Matt Stauffer), *PHP 8 Objects, Patterns, and Practice* (Matt Zandstra).

### Backend

7. **Backend fundamentals for any language:** HTTP and REST, SQL and data modeling, indexes, transactions, caching, queues, authentication, logging, testing and deployment: the part you keep when you change languages. Books: *Designing Data-Intensive Applications* (Martin Kleppmann; check for the second edition with Chris Riccomini), *Learning SQL* (Alan Beaulieu), *SQL Performance Explained* (Markus Winand), *Unit Testing Principles, Practices, and Patterns* (Vladimir Khorikov).
8. **.NET backend from zero to senior:** C# and the CLR, ASP.NET Core (middleware, DI, minimal APIs vs controllers), EF Core and Dapper, background jobs, messaging, caching, observability, performance and memory, and clean architecture without overdoing it. Books: *C# in Depth* (Jon Skeet), *ASP.NET Core in Action*, *Dependency Injection Principles, Practices, and Patterns* (Steven van Deursen, Mark Seemann), *Concurrency in C# Cookbook* (Stephen Cleary), *Pro .NET Memory Management* (Konrad Kokosa), *CLR via C#* (Jeffrey Richter; old, read it for the runtime chapters).
9. **Java backend with Spring Boot:** modern Java, Spring Boot, Spring Data JPA, Spring Security, testing, and the JVM. Books: *Head First Java* (Kathy Sierra, Bert Bates, Trisha Gee), *Effective Java* (Joshua Bloch), *Spring in Action* (Craig Walls), *Java Concurrency in Practice* (Brian Goetz and others).
10. **Node.js backend:** the event loop, TypeScript, NestJS, databases with an ORM and with raw SQL, streams, worker threads, and scaling Node. Books: *Node.js Design Patterns*, *Distributed Systems with Node.js* (Thomas Hunter II), *Effective TypeScript*.
11. **Python backend:** Python itself, Django vs FastAPI, the ORM, async, background jobs with Celery, testing and packaging. Books: *Python Crash Course* (Eric Matthes), *Fluent Python* (Luciano Ramalho), *Architecture Patterns with Python* (Harry Percival, Bob Gregory, free online), *Two Scoops of Django* (Daniel and Audrey Feldroy).
12. **Go backend:** the language, goroutines and channels, `net/http`, databases, tooling, and when Go is the right choice. Books: *Learning Go* (Jon Bodner), *The Go Programming Language* (Alan Donovan, Brian Kernighan), *Concurrency in Go* (Katherine Cox-Buday), *100 Go Mistakes and How to Avoid Them* (Teiva Harsanyi).

### Frontend

13. **Frontend fundamentals:** semantic HTML, modern CSS layout, JavaScript in depth, how the browser works, accessibility and web performance, all before any framework. Books: *Eloquent JavaScript*, *CSS: The Definitive Guide* (Eric Meyer, Estelle Weyl), *You Don't Know JS Yet* (Kyle Simpson, free online), *High Performance Browser Networking* (Ilya Grigorik, free online).
14. **Angular from zero to senior:** TypeScript, components and signals, RxJS, routing, forms, state, SSR, testing, performance and structuring a large app. Books: *Learning Angular*, *Effective TypeScript*, with angular.dev as the main source, since books age with every major version.
15. **React and Next.js from zero to senior:** components and state, Effects, data fetching, routing, Next.js server components, testing and performance. Books: *Learning React*, *Fluent React*, with react.dev and nextjs.org as the main sources.

### Mobile

16. **Flutter from zero to senior:** Dart, widgets and layout, state management, navigation, networking and offline, testing, performance, platform channels, and publishing to both stores. Books: *Dart Apprentice* and *Flutter Apprentice* (Kodeco), with the official Flutter app architecture guide.
17. **Native Android with Kotlin:** Kotlin, Jetpack Compose, coroutines and Flow, the architecture components, Room, testing and a Play Store release. Books: *Kotlin in Action* (Sebastian Aigner, Roman Elizarov, Svetlana Isakova, Dmitry Jemerov), *Kotlin Coroutines: Deep Dive* (Marcin Moskała), *Android Programming: The Big Nerd Ranch Guide*, and Google's free Android Basics with Compose course.
18. **Native iOS with Swift:** Swift, SwiftUI then UIKit, Swift concurrency, persistence, testing and an App Store release. Books: *The Swift Programming Language* (Apple, free), *Thinking in SwiftUI* and *Advanced Swift* (objc.io), and Paul Hudson's free *100 Days of SwiftUI* course.
19. **React Native:** React first, then React Native and Expo, native modules, performance and release, and when it beats Flutter or native and when it doesn't. Books: *Learning React*, *Effective TypeScript*, with reactnative.dev and the Expo docs as the main sources.
20. **Senior mobile engineer, beyond the framework:** app architecture, offline sync, performance, security (OWASP MASVS), accessibility, CI/CD for apps, crash monitoring, store review rules and staged rollouts. Books: *Building Mobile Apps at Scale* (Gergely Orosz), the OWASP MASTG (free), *Clean Architecture* (Robert C. Martin; read it critically).

### System Design and Architecture

21. **System design from zero to senior:** growing one server step by step, then caches, queues, replication, partitioning, consistency and reliability, with a study plan for system design interviews. Books: *Designing Data-Intensive Applications*, *System Design Interview* volumes 1 and 2 (Alex Xu; volume 2 with Sahn Lam), *Understanding Distributed Systems* (Roberto Vitillo), *Release It!* (Michael Nygard), *Database Internals* (Alex Petrov).
22. **Software design, from clean code to design patterns:** OOP done right, SOLID, the classic patterns and when they're overkill, refactoring, and working with legacy code. Books: *Head First Design Patterns* (Eric Freeman, Elisabeth Robson), *Design Patterns* (Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides), *Refactoring* (Martin Fowler), *A Philosophy of Software Design* (John Ousterhout), *Working Effectively with Legacy Code* (Michael Feathers).
23. **Software architecture: DDD, modular monoliths and microservices:** architecture styles and their trade-offs, DDD, events and integration, and how to decide. Books: *Fundamentals of Software Architecture* (Mark Richards, Neal Ford), *Learning Domain-Driven Design* (Vlad Khononov), *Domain-Driven Design* (Eric Evans), *Building Microservices* (Sam Newman), *Software Architecture: The Hard Parts* (Neal Ford, Mark Richards, Pramod Sadalage, Zhamak Dehghani), *Enterprise Integration Patterns* (Gregor Hohpe, Bobby Woolf).

### DevOps and Cloud

24. **DevOps engineer from zero:** Linux, networking, scripting, Git, CI/CD, Docker, Kubernetes, infrastructure as code, monitoring, and the culture behind them. Books: *The Linux Command Line* (William Shotts, free online), *The Phoenix Project* (Gene Kim, Kevin Behr, George Spafford), *The DevOps Handbook* (Gene Kim, Jez Humble, Patrick Debois, John Willis, Nicole Forsgren), *Continuous Delivery* (Jez Humble, David Farley), *Accelerate* (Nicole Forsgren, Jez Humble, Gene Kim), *Terraform: Up & Running* (Yevgeniy Brikman).
25. **Kubernetes and platform engineering:** containers in depth, Kubernetes for developers and then for operators, Helm, GitOps, and building an internal platform; the CKAD, CKA and CKS exams. Books: *Docker Deep Dive* (Nigel Poulton), *Kubernetes: Up and Running* (Brendan Burns, Joe Beda, Kelsey Hightower, Lachlan Evenson), *Kubernetes in Action* (Marko Lukša), *Production Kubernetes* (Josh Rosso, Rich Lander, Alex Brand, John Harris), *Platform Engineering* (Camille Fournier, Ian Nowland), *Team Topologies* (Matthew Skelton, Manuel Pais).
26. **Site reliability engineering (SRE):** SLOs and error budgets, on-call, incident response, observability, capacity and performance. Books: *Site Reliability Engineering* and *The Site Reliability Workbook* (Google, free online), *Observability Engineering* (Charity Majors, Liz Fong-Jones, George Miranda), *Implementing Service Level Objectives* (Alex Hidalgo), *Systems Performance* (Brendan Gregg).
27. **Azure cloud engineer:** core services, networking, identity, cost and the Well-Architected Framework, with the certification path (AZ-900, AZ-104, AZ-204, AZ-305, AZ-400) and which one fits which job. Sources: Microsoft Learn and the Azure Architecture Center. Cloud books age fast, so name only one whose edition matches the current exam.
28. **AWS cloud engineer:** core services, networking, IAM, cost and the Well-Architected Framework, with the certification path (Cloud Practitioner, then the Associate and Professional exams) and which one fits which job. Sources: AWS Skill Builder and the AWS Well-Architected Framework. Same rule for books.

### Security

29. **Cybersecurity from zero:** the tracks (application security, penetration testing, SOC, cloud security and GRC), the networking and Linux base they all need, legal practice labs, and the entry certifications (CompTIA Security+, ISC2 CC). Books: *Computer Networking: A Top-Down Approach*, *Linux Basics for Hackers* (OccupyTheWeb), *Security Engineering* (Ross Anderson).
30. **Application security for developers:** the OWASP Top 10 and ASVS, secure design, threat modeling, secure code review, and dependency and secret scanning. Books: *Alice and Bob Learn Application Security* (Tanya Janca), *Web Application Security* (Andrew Hoffman), *Threat Modeling: Designing for Security* (Adam Shostack), *API Security in Action* (Neil Madden), *Designing Secure Software* (Loren Kohnfelder).
31. **Penetration testing and bug bounty, legally:** the methodology, web and network testing in legal labs and in-scope programs only, writing reports, and the eJPT and OSCP exams. Books: *Penetration Testing* (Georgia Weidman), *Real-World Bug Hunting* (Peter Yaworski), *Bug Bounty Bootcamp* (Vickie Li), *Black Hat Python* (Justin Seitz, Tim Arnold), and PortSwigger's free Web Security Academy.
32. **SOC analyst and blue team:** logs and SIEM, detection, MITRE ATT&CK, incident response, threat hunting and basic malware analysis. Books: *Blue Team Handbook: SOC, SIEM, and Threat Hunting* (Don Murdoch), *The Practice of Network Security Monitoring* (Richard Bejtlich), *Practical Packet Analysis* (Chris Sanders), *Intelligence-Driven Incident Response* (Scott J. Roberts, Rebekah Brown), *Practical Malware Analysis* (Michael Sikorski, Andrew Honig).
33. **Cloud security and DevSecOps:** identity and permissions in the cloud, container and Kubernetes security, securing CI/CD and the supply chain, and the certifications (CCSK, AZ-500, AWS Security Specialty, CKS). Books: *Practical Cloud Security* (Chris Dotson), *Container Security* (Liz Rice), *Hacking Kubernetes* (Andrew Martin, Michael Hausenblas), *Securing DevOps* (Julien Vehent).

### Data and AI

34. **Database engineer and DBA:** SQL in depth, data modeling, indexes and execution plans, transactions and locking, backup and recovery, and replication, in SQL Server and PostgreSQL. Books: *Learning SQL*, *SQL Performance Explained*, *SQL Antipatterns* (Bill Karwin), *Database Internals*, *SQL Server Execution Plans* (Grant Fritchey, free from Redgate), *PostgreSQL Internals* (Egor Rogov, free from Postgres Professional).
35. **Data analyst:** Excel, SQL, statistics, Python or Power BI, dashboards, and telling a story with data; the PL-300 exam. Books: *SQL for Data Analysis* (Cathy Tanimura), *Practical Statistics for Data Scientists* (Peter Bruce, Andrew Bruce, Peter Gedeck), *Python for Data Analysis* (Wes McKinney, free online), *Storytelling with Data* (Cole Nussbaumer Knaflic).
36. **Data engineer:** SQL and Python, data modeling and warehouses, ETL and ELT, orchestration, Spark, streaming with Kafka, and data quality. Books: *Fundamentals of Data Engineering* (Joe Reis, Matt Housley), *The Data Warehouse Toolkit* (Ralph Kimball, Margy Ross), *Designing Data-Intensive Applications*, *Streaming Systems* (Tyler Akidau, Slava Chernyak, Reuven Lax), *Kafka: The Definitive Guide* (Gwen Shapira, Todd Palino, Rajini Sivaram, Krit Petty).
37. **Machine learning engineer:** the math you really need, classic ML, deep learning and evaluation, then MLOps and serving models in production. Books: *Mathematics for Machine Learning* (Marc Peter Deisenroth, A. Aldo Faisal, Cheng Soon Ong, free), *An Introduction to Statistical Learning* (Gareth James, Daniela Witten, Trevor Hastie, Robert Tibshirani, Jonathan Taylor; free Python edition), *Hands-On Machine Learning* (Aurélien Géron), *Designing Machine Learning Systems* (Chip Huyen), *Understanding Deep Learning* (Simon J. D. Prince, free).
38. **AI engineer, building LLM applications:** how LLMs work, prompting, RAG, tools and agents, evaluation, cost and safety, and shipping to production. Books: *AI Engineering* (Chip Huyen), *Hands-On Large Language Models* (Jay Alammar, Maarten Grootendorst), *Build a Large Language Model (From Scratch)* (Sebastian Raschka), *Prompt Engineering for LLMs* (John Berryman, Albert Ziegler).

### Other Tracks

39. **QA and test automation engineer:** testing fundamentals and exploratory testing, test design, API testing, UI automation with Playwright, performance testing, and where QA fits in CI; the ISTQB Foundation exam. Books: *Lessons Learned in Software Testing* (Cem Kaner, James Bach, Bret Pettichord), *Explore It!* (Elisabeth Hendrickson), *Agile Testing* (Lisa Crispin, Janet Gregory), *Unit Testing Principles, Practices, and Patterns*, *xUnit Test Patterns* (Gerard Meszaros).
40. **Embedded systems engineer:** C in depth, digital electronics, ARM Cortex-M microcontrollers, peripherals and drivers, RTOS, hardware debugging, and the automotive standards (AUTOSAR, MISRA C). Books: *C Programming: A Modern Approach* (K. N. King), *Making Embedded Systems* (Elecia White), *The Definitive Guide to ARM Cortex-M3 and Cortex-M4 Processors* (Joseph Yiu), *Mastering the FreeRTOS Real Time Kernel* (Richard Barry, free), *Test Driven Development for Embedded C* (James Grenning).

## Book Summaries

One article per book: its key ideas in our own words, what has aged, who should read it and where to start. The rules are under "Book Summaries topics" at the top of this file.

### Writing Good Code

1. ***The Pragmatic Programmer*** (David Thomas, Andrew Hunt; 20th anniversary edition, 2019): DRY as duplicated knowledge rather than duplicated lines, orthogonality, tracer bullets, broken windows, and what changed from the 1999 edition.
2. ***Clean Code*** (Robert C. Martin, 2008): naming, functions, comments and error handling; which advice is widely accepted, which is disputed (very short functions, few comments), and where *A Philosophy of Software Design* disagrees.
3. ***Code Complete*** (Steve McConnell; 2nd edition, 2004): construction as a craft: variables, routines, defensive programming and code quality, and which parts a 2004 book still gets right.
4. ***Refactoring*** (Martin Fowler; 2nd edition, 2018): code smells, small safe steps behind tests, the most useful refactorings, and why the second edition moved its examples to JavaScript.
5. ***A Philosophy of Software Design*** (John Ousterhout; 2nd edition, 2021): complexity, deep vs shallow modules, information hiding, and defining errors out of existence.
6. ***Working Effectively with Legacy Code*** (Michael Feathers, 2004): legacy code as code without tests, seams, characterization tests, and breaking dependencies safely.
7. ***Test-Driven Development: By Example*** (Kent Beck, 2002): red, green, refactor, small steps, and what TDD is and isn't for.
8. ***Unit Testing Principles, Practices, and Patterns*** (Vladimir Khorikov, 2020): what makes a test valuable, the classical vs London schools, mocks only at the system's edges, and testing the domain without the database.

### Design and Architecture

9. ***Design Patterns*** (Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides, 1994): the patterns still worth knowing, the ones modern languages made unnecessary, and "favor composition over inheritance".
10. ***Patterns of Enterprise Application Architecture*** (Martin Fowler, 2002): Transaction Script vs Domain Model, Active Record vs Data Mapper, Unit of Work, and where these live in today's ORMs.
11. ***Domain-Driven Design*** (Eric Evans, 2003): ubiquitous language, bounded contexts, aggregates and strategic design, and why the strategic half matters more than the tactical one.
12. ***Clean Architecture*** (Robert C. Martin, 2017): the dependency rule, boundaries and use cases, and where teams overdo it.
13. ***Fundamentals of Software Architecture*** (Mark Richards, Neal Ford): architecture characteristics, the main styles and their trade-offs, and "everything is a trade-off".
14. ***Building Microservices*** (Sam Newman; 2nd edition, 2021): service boundaries, data ownership, communication, deployment, and when not to use microservices at all.
15. ***Designing Data-Intensive Applications*** (Martin Kleppmann, 2017; check for the 2nd edition with Chris Riccomini): reliability, scalability and maintainability; data models, storage engines, replication, partitioning, transactions, consistency, and batch and stream processing.
16. ***Release It!*** (Michael T. Nygard; 2nd edition, 2018): stability antipatterns and patterns (timeouts, circuit breakers, bulkheads), and designing for production rather than for QA.

### Delivery and Operations

17. ***Continuous Delivery*** (Jez Humble, David Farley, 2010): the deployment pipeline, releasable software at every commit, and deploying vs releasing.
18. ***Accelerate*** (Nicole Forsgren, Jez Humble, Gene Kim, 2018): the four key metrics, the research behind them, and the limits of that research.
19. ***Site Reliability Engineering*** (Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy, 2016): SLOs, error budgets, toil, on-call and postmortems, and what a small team can take from Google's practices.

### Languages

20. ***Effective Java*** (Joshua Bloch; 3rd edition, 2018): the items that matter most (immutability, equals and hashCode, generics, lambdas and streams), and which apply to other languages too.
21. ***C# in Depth*** (Jon Skeet; 4th edition, 2019): how C# evolved from version 2 to 7, with generics, LINQ, async and nullable types, and what a reader on today's C# should add.
22. ***You Don't Know JS Yet*** (Kyle Simpson, 2020, free online): scope, closures and the parts of JavaScript people use without understanding; note which books of the second edition are finished.
23. ***Effective TypeScript*** (Dan Vanderkam; 2nd edition, 2024): thinking in types as sets, inference, narrowing, `any` vs `unknown`, and designing types that make invalid states impossible.
24. ***Fluent Python*** (Luciano Ramalho; 2nd edition, 2022): the data model, dunder methods, iterators and generators, concurrency, and writing Python that reads like Python.

### Computer Science

25. ***Code: The Hidden Language of Computer Hardware and Software*** (Charles Petzold; 2nd edition, 2022): from switches and logic gates to a working CPU and memory, for readers who never studied hardware.
26. ***Structure and Interpretation of Computer Programs*** (Harold Abelson, Gerald Jay Sussman; 2nd edition, 1996, and the 2022 JavaScript edition): abstraction, recursion, higher-order functions and interpreters, and why people still recommend it.
27. ***Introduction to Algorithms*** (Thomas Cormen, Charles Leiserson, Ronald Rivest, Clifford Stein; 4th edition, 2022): how to use a reference this large, the chapters a working developer needs, and lighter books to start with.
28. ***Computer Systems: A Programmer's Perspective*** (Randal E. Bryant, David R. O'Hallaron; 3rd edition, 2015): data representation, machine code, the memory hierarchy, linking, processes and virtual memory, from a programmer's point of view.

### Teams and Careers

29. ***The Mythical Man-Month*** (Frederick P. Brooks Jr.; anniversary edition, 1995): Brooks's law, conceptual integrity, the second-system effect and "No Silver Bullet", and what still holds 50 years later.
30. ***Cracking the Coding Interview*** (Gayle Laakmann McDowell; 6th edition, 2015): how technical interviews are run, the core data structures and algorithms they test, a study approach that builds skill rather than memorized answers, and the 2025 follow-up *Beyond Cracking the Coding Interview*.

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
