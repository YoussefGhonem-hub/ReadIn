# Deploying the API without losing uploads

Every uploaded image (avatars, article covers, article images) is stored on the API server's disk, in
`ReadIn.Api/wwwroot/uploads` by default ([ADR 0010](../adr/0010-uploads-in-wwwroot.md), SPEC §24). The folder
lives **inside the app folder**, so the one rule of every deployment is:

> **A deployment must never delete, replace or overwrite `wwwroot/uploads`.** Losing it loses every image
> users have uploaded, and the database will still point at the missing files.

---

## 1. What the repo already does

| Safeguard | Where |
|---|---|
| The folder is git-ignored; only `wwwroot/uploads/.gitkeep` is committed | `.gitignore` |
| `dotnet publish` never ships anything from `wwwroot/uploads` (`CopyToPublishDirectory="Never"`) | `backend/src/ReadIn.Api/ReadIn.Api.csproj` |
| At startup the API creates the folder and its `avatars/`, `covers/`, `articles/` sub-folders and writes a probe file. If it can't, it logs a critical error and **refuses to start** | `PrepareUploadsFolder()` in `ReadIn.Infrastructure/DependencyInjection.cs` |
| Docker: the folder is a named volume | `docker-compose.yml` (`api` profile) |
| Private files (verification proofs) live in a separate folder that the API refuses to start with if it overlaps `wwwroot` or the uploads folder | `PreparePrivateStorage()` in `ReadIn.Infrastructure/DependencyInjection.cs`, [section 8](#8-private-files-verification-proofs) |

Check the publish exclusion yourself before the first deployment:

```powershell
dotnet publish backend/src/ReadIn.Api -c Release -o .\publish-check
Get-ChildItem .\publish-check -Recurse | Where-Object FullName -match 'uploads'   # must print nothing
```

## 2. Configuration

| Key | Default | Notes |
|---|---|---|
| `Storage:UploadsPath` | `wwwroot/uploads` | Relative to the content root, or an absolute path. |
| `Storage:PublicBaseUrl` | `https://api.readin.app` (`http://localhost:5080` in Development) | Origin that serves `/uploads`. Clients get `PublicBaseUrl + /uploads/…`; the database stores only `/uploads/…`, so changing this never needs a data migration. |

On a server, set them as environment variables: `Storage__UploadsPath`, `Storage__PublicBaseUrl`.

> **Recommended hardening:** point `Storage__UploadsPath` at a folder **outside** the app folder, e.g.
> `D:\ReadIn\data\uploads` or `/var/lib/readin/uploads`. The API still serves it at `/uploads`, and no deploy
> tool can touch it by accident. Everything below still applies if you keep the default.

## 3. Deploy methods that delete files at the destination

Any method that makes the destination folder an exact copy of the publish output deletes `wwwroot/uploads`
unless that folder is explicitly excluded.

### Web Deploy (Visual Studio "Publish", `msdeploy`)

"**Remove additional files at destination**" deletes the uploads. Either keep it unchecked, or add a skip rule
to the publish profile (`Properties/PublishProfiles/*.pubxml`):

```xml
<!-- With these rules "Remove additional files at destination" can stay on: Web Deploy never touches the folder. -->
<ItemGroup>
  <MsDeploySkipRules Include="SkipUploadsFolder">
    <ObjectName>dirPath</ObjectName>
    <AbsolutePath>wwwroot\\uploads</AbsolutePath>
  </MsDeploySkipRules>
  <MsDeploySkipRules Include="SkipUploadsFiles">
    <ObjectName>filePath</ObjectName>
    <AbsolutePath>wwwroot\\uploads\\.*</AbsolutePath>
  </MsDeploySkipRules>
</ItemGroup>
```

Command line equivalent: `msdeploy -verb:sync … -skip:objectName=dirPath,absolutePath=wwwroot\\uploads`.

### Copy / mirror scripts

`robocopy /MIR`, `rsync --delete` and "delete the folder, then copy the new build" all wipe the uploads.
Exclude the folder:

```powershell
robocopy .\publish C:\inetpub\readin-api /MIR /XD "C:\inetpub\readin-api\wwwroot\uploads"
```
```bash
rsync -a --delete --exclude 'wwwroot/uploads/' ./publish/ /srv/readin-api/
```

Never deploy by deleting or renaming the whole app folder.

### Docker

The container's file system is thrown away on every rebuild, so the folder **must** be a volume:

```yaml
services:
  api:
    image: ghcr.io/<owner>/readin-api:latest
    volumes:
      - api-uploads:/app/wwwroot/uploads
volumes:
  api-uploads:
```

- The .NET image runs as the non-root `app` user (UID 1654), and a new named volume is owned by root. Give the
  volume to UID 1654 once (the `api-uploads-init` service in `docker-compose.yml` does this), otherwise the
  startup check stops the API.
- `docker compose down` keeps the volume. **`docker compose down -v` deletes it, with every image.**
- To try it locally: `dotnet publish backend/src/ReadIn.Api -c Release /t:PublishContainer -p:ContainerRepository=readin-api -p:ContainerImageTag=local`,
  then `docker compose --profile api up -d` (API on <http://localhost:5080>).

## 4. IIS / Windows Server

1. The app pool identity needs **read & execute** on the app folder (the default) and **modify** on the
   uploads folder **only**:
   ```powershell
   $uploads = "C:\inetpub\readin-api\wwwroot\uploads"
   New-Item -ItemType Directory -Force $uploads | Out-Null
   icacls $uploads /grant "IIS AppPool\ReadInApi:(OI)(CI)M"
   ```
   Don't grant write on the whole site folder.
2. Deploy with one of the exclusions from section 3.
3. IIS sends every request to Kestrel through the ASP.NET Core Module, so `/uploads` is served by the API with
   its `.webp`-only allow-list and security headers. Don't add an IIS virtual directory or static-file handler
   for `/uploads`: it would bypass those rules.

## 5. Azure App Service (if used later)

- **Web Deploy / Visual Studio:** add the skip rules from section 3.
- **Zip deploy / Run From Package** (`WEBSITE_RUN_FROM_PACKAGE=1`): `wwwroot` becomes read-only and is
  replaced on every deploy. Set `Storage__UploadsPath` to the persistent `/home` share instead:
  `D:\home\data\uploads` (Windows plans) or `/home/data/uploads` (Linux plans).
- **Containers on App Service:** enable persistent storage (`WEBSITES_ENABLE_APP_SERVICE_STORAGE=true`) and
  point `Storage__UploadsPath` at `/home/data/uploads`, or mount an Azure Files share there.
- Scale-out (more than one instance) is not supported with local uploads, see section 7.

## 6. Backups

The database references images by path, and the images exist nowhere else. **Back them up together**, on the
same schedule, and restore them together. Restoring one without the other breaks images.

- Back up the **database first, then the uploads**. Files uploaded between the two copies are only unreferenced
  extras after a restore (the orphan job removes them after 24 h). The opposite order can leave the database
  pointing at files the backup doesn't have.
- Uploaded files never change after they are written, so a plain file copy of the folder is consistent.
- The folder also holds the **original PDFs** of document attachments (`documents/{yyyy}/{MM}/{id}/original.pdf`,
  ADR 0011) next to their rendered pages. They are the only copy of what authors uploaded (up to 200 MB per user),
  so size the backup target for them. They are never served by the static-file middleware; only the download
  endpoint reads them.
- Keep backups **off the server** too (another disk, another machine, cloud storage). A backup on the same disk
  dies with it.

### Example: nightly backup script (PowerShell)

Save as `C:\ReadIn\ops\Backup-ReadIn.ps1`. It writes one dated folder per run holding the database backup and
a copy of the uploads, then deletes runs older than `$KeepDays`.

```powershell
<#
.SYNOPSIS
    Backs up the ReadIn database and the uploads folder together (docs/setup/deployment.md §6).
#>
param(
    [string] $SqlInstance = "localhost",
    [string] $Database    = "ReadIn",
    [string] $UploadsPath = "C:\inetpub\readin-api\wwwroot\uploads",
    [string] $PrivatePath = "D:\ReadIn\data\private",   # Storage:PrivatePath (section 8)
    [string] $BackupRoot  = "E:\Backups\ReadIn",
    [int]    $KeepDays    = 14
)
$ErrorActionPreference = "Stop"

$stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$target = Join-Path $BackupRoot $stamp
New-Item -ItemType Directory -Force -Path $target | Out-Null

# 1. Database first. The SQL Server service account must be able to write to $target.
#    Remove COMPRESSION on SQL Server Express, which doesn't support it.
$bak = Join-Path $target "$Database.bak"
sqlcmd -S $SqlInstance -E -b -Q "BACKUP DATABASE [$Database] TO DISK = N'$bak' WITH COPY_ONLY, CHECKSUM, COMPRESSION, INIT"
if ($LASTEXITCODE -ne 0) { throw "Database backup failed (sqlcmd exit $LASTEXITCODE)." }

# 2. Then the uploads (robocopy exit codes below 8 mean success).
robocopy $UploadsPath (Join-Path $target "uploads") /E /COPY:DAT /R:2 /W:5 /NP /NFL /NDL | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Uploads copy failed (robocopy exit $LASTEXITCODE)." }

# 2b. And the private files (verification proofs). The backup folder must be as protected as the folder itself.
robocopy $PrivatePath (Join-Path $target "private") /E /COPY:DAT /R:2 /W:5 /NP /NFL /NDL | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Private files copy failed (robocopy exit $LASTEXITCODE)." }

# 3. Retention.
Get-ChildItem $BackupRoot -Directory |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$KeepDays) } |
    Remove-Item -Recurse -Force

Write-Output "Backup written to $target"
```

Schedule it daily (run once in an elevated PowerShell):

```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\ReadIn\ops\Backup-ReadIn.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 2:30am
Register-ScheduledTask -TaskName "ReadIn backup" -Action $action -Trigger $trigger -User "NT AUTHORITY\SYSTEM" -RunLevel Highest
```

Then copy `E:\Backups\ReadIn` off the server (for example with a second scheduled `robocopy` to a network share,
or your cloud backup agent).

**Docker:** the uploads are in the named volume, not a host folder. After the database backup, archive the volume:
`docker run --rm -v readin_api-uploads:/data:ro -v E:\Backups\ReadIn\<run>:/backup busybox:1.37 tar czf /backup/uploads.tgz -C /data .`

### Restore

1. Stop the API (stop the app pool / container).
2. Restore the database from `<run>\ReadIn.bak` (`RESTORE DATABASE [ReadIn] FROM DISK = N'…' WITH REPLACE`).
3. Replace the uploads folder with `<run>\uploads` from the **same** run:
   `robocopy "<run>\uploads" "C:\inetpub\readin-api\wwwroot\uploads" /MIR`, and the private folder with `<run>\private`:
   `robocopy "<run>\private" "D:\ReadIn\data\private" /MIR`.
4. Start the API. Check a few avatars and covers in the app.

## 7. Limitation: one server

Local uploads only work with **one** API instance: a second instance would not see the first one's files.
Before scaling out (or moving images to a CDN-backed bucket), swap the `IFileStorage` implementation for shared or
cloud storage. Stored paths stay valid, so no data migration is needed. Steps: [ADR 0010 → Migration path](../adr/0010-uploads-in-wwwroot.md#migration-path).

## 8. Private files (verification proofs)

Writer verification (SPEC F19) lets users upload proof of their expertise: a certificate or a syndicate card, as a PDF,
JPEG, PNG or WebP of at most 10 MB. These are **personal documents**. They never go to `wwwroot`, never get a public
URL and are never served as static files: only `GET /admin/verification-requests/{id}/proof` reads them, for admins with
`verification.manage`, as an attachment with `Cache-Control: no-store`.

| Key | Default | Notes |
|---|---|---|
| `Storage:PrivatePath` | `App_Data/private` | Relative to the content root, or an absolute path. Proofs are stored as `verification/{requestId}{.ext}` below it. |

On a server, set `Storage__PrivatePath` to a folder **outside the app folder**, e.g. `D:\ReadIn\data\private` or
`/var/lib/readin/private`, next to (not inside) the uploads folder. Then no deploy tool can delete it and no web server
setting can expose it.

What the API checks at startup (`PreparePrivateStorage()`), refusing to start with a clear log message otherwise:

- the folder is not the web root (`wwwroot`) or inside it, and the web root is not inside it;
- the folder is not the uploads folder (`Storage:UploadsPath`) or inside it, and the uploads folder is not inside it;
- the folder (and its `verification/` sub-folder) can be created and written.

Rules for every environment:

- **Permissions.** IIS / Windows Server: give the app pool identity **modify** on this folder only, like the uploads
  folder (`icacls "D:\ReadIn\data\private" /grant "IIS AppPool\ReadInApi:(OI)(CI)M"`). Never add an IIS virtual
  directory or a static-file handler for it. Linux: owned by the service account, mode `700`.
- **Deployments.** The default `App_Data/private` is inside the app folder: a mirror deployment (`robocopy /MIR`,
  `rsync --delete`, Web Deploy "Remove additional files at destination") deletes it unless it is excluded the same way
  as `wwwroot/uploads` in section 3 (`/XD "C:\inetpub\readin-api\App_Data"`, `--exclude 'App_Data/'`,
  `<AbsolutePath>App_Data</AbsolutePath>`). Pointing `Storage__PrivatePath` outside the app folder avoids this
  altogether. The repo ships nothing in `App_Data`.
- **Docker.** The container's file system is thrown away on every rebuild, and the non-root `app` user (UID 1654) can't
  create folders in `/app`. Mount a named volume for it and give it to UID 1654, like the uploads volume:
  `api-private:/app/App_Data/private` (or set `Storage__PrivatePath` to the mount point). The local `api` profile in
  `docker-compose.yml` does this.
- **Backups.** Back the folder up with the database and the uploads, on the same schedule (the script in section 6
  does), and keep the backup as protected as the folder. Restore it from the same run as the database.
- **Retention.** A proof is deleted as soon as its request is approved or rejected, when the request is withdrawn and
  when the account is deleted (SPEC §9.6), so the folder only holds proofs of pending requests. The daily
  `verification-proofs-cleanup` job (03:15 UTC) deletes files no request points at any more and that are older than
  24 hours (a delete that failed, or a file from a restore), plus stale `.tmp` leftovers.
- **One server.** Like the uploads (section 7): with more than one API instance, swap `IPrivateFileStorage` for shared
  private storage (e.g. a private blob container with no public access) before scaling out.

## 9. Database migrations and the data upgrades after them

`Database:MigrateOnStartup` is off in production (`appsettings.json`), so a deployment applies the EF migrations itself,
before the new version serves requests. Some releases also need a **data upgrade** right after their migration, written
in C# because it uses the app's rules. Today there is one: tags made before F32 get their cleaned name, normalized name
and URL-safe slug, and tags that are now one tag are merged (`LegacyTagsUpgrade`). Until it runs, those tags have a
`~{id}` placeholder slug, so their links and pages don't work.

- **Recommended:** run the `seed` command with the production settings
  (`dotnet ReadIn.Api.dll seed`, or `dotnet run --project backend/src/ReadIn.Api -- seed`). It applies the migrations,
  then the data upgrades, then the seeders (SPEC §18), and exits.
- **A SQL script or a migrations bundle** (`dotnet ef migrations script --idempotent`, `dotnet ef migrations bundle`)
  can't run C#. The API does the data upgrades at its next start, before it serves requests (`UpgradeDataAsync()` in
  `ReadIn.Infrastructure/DependencyInjection.cs`), so start or restart the API **after** the script is applied.
  Run the script with `sqlcmd -I` (QUOTED_IDENTIFIER on): without it, the filtered indexes fail (`Msg 1934`).

Each upgrade waits until its migration is applied and does nothing once it is done (one or two small queries per
start), so running it again is always safe.

**Roles change (2026-11-05, [ADR 0018](../adr/0018-two-roles-and-a-verified-badge.md)):** nothing to run by hand. The
`VerifiedBadgeAndTwoRoles` migration does the whole move in SQL, so a script works too: VerifiedWriter becomes the
Verified badge, and the Admin, Moderator and VerifiedWriter roles and `roles.manage` are deleted. Anyone who was an
Admin or a Moderator is a plain Member afterwards, so only the SuperAdmin keeps the admin and moderation screens. The
role seeder (`seed`, or a start with seeding on) then keeps the roles exactly as SPEC §10.2 lists them.

## 10. Chromium for article PDFs (SPEC F33)

`GET /api/v1/articles/{id}/pdf` prints an article with **headless Chromium** through PuppeteerSharp. Chromium is installed
with the server or the image and is **never downloaded at runtime**. The fonts (IBM Plex Sans Arabic, IBM Plex Sans,
JetBrains Mono, Noto Sans, Noto Color Emoji, and Noto Sans Symbols 2 and Noto Sans Math for symbols such as ★ and ⇒), the
logo and the icons ship inside the API and are inlined into every file, so the server needs no fonts of its own. Their
licenses are published next to the API in `licenses/fonts/` (SIL OFL 1.1; Lucide icons: ISC).

**The permission.** F33 adds `articles.export_pdf` to Member and every role above it. Permissions are read from the
database, and only the seeders write them, so **run the `seed` command (§9) once with this release**. A deployment by
SQL script or migrations bundle alone leaves the roles without it, and every PDF answers `403`.

**How the API finds Chromium:** `ArticlePdf:ChromiumPath`, else the `PUPPETEER_EXECUTABLE_PATH` environment variable,
else the usual install paths: Chrome on Windows (`Program Files\Google\Chrome\Application\chrome.exe`) and macOS, and
`/usr/bin/chromium`, `/usr/bin/chromium-browser`, `/usr/bin/google-chrome(-stable)` or `/opt/google/chrome/chrome` on
Linux. Without one, every PDF answers `500 article.pdf_failed` and the log says "Chrome/Chromium for article PDFs was
not found"; nothing else in the API needs Chromium.

| Key | Default | Notes |
|---|---|---|
| `ArticlePdf:ChromiumPath` | (empty) | The `chrome`/`chromium` executable, when it isn't in a usual place |
| `ArticlePdf:WebBaseUrl` | `https://readin.app` | The web app's origin: the article link at the end, profile links, and the host in the footer |
| `ArticlePdf:MaxConcurrentBuilds` | `2` | Builds at the same time, per API instance |
| `ArticlePdf:QueueTimeout` | `00:00:30` | Wait for a free build, then `503 article.pdf_busy` |
| `ArticlePdf:BuildTimeout` | `00:01:00` | One build, then `500 article.pdf_failed`; that build's page is closed (Chromium restarts only if it crashed) |
| `RateLimits:ArticlePdfPerHour` | `10` | Per user, in memory: per API instance, and it starts over on a restart |

**Quote cards (SPEC F24)** are drawn by the same Chromium on the same build slots: `ArticlePdf:MaxConcurrentBuilds`
counts PDFs and cards together, and the card's article link uses `ArticlePdf:WebBaseUrl`. Their own settings:

| Key | Default | Notes |
|---|---|---|
| `QuoteCard:QueueTimeout` | `00:00:10` | Wait for a free slot, then `503 quote.busy` |
| `QuoteCard:BuildTimeout` | `00:00:20` | One card, then `500 quote.failed` |
| `RateLimits:QuoteCardPerHour` | `30` | Per user, guests per IP address; in memory, per API instance |

`POST /api/v1/articles/*/quote-card` answers within 30 s at most (10 s wait + 20 s draw), so no proxy change is needed.
Nothing new to install: the dark lockup and the quote mark ship inside the API like the other PDF resources.

**What Chromium is allowed to do.** One browser per API instance, started on the first PDF and restarted only when it
crashed, disconnected or stopped answering; a build that fails or runs out of time closes only its own page, so the
other build carries on. Its sandbox stays on (never add `--no-sandbox`), each page runs with JavaScript off, every
request except the page's own `data:` URLs is aborted, and the browser's proxy points at `127.0.0.1:9` as a second
wall, so article content can't make the server fetch anything. Plan about 150–250 MB of memory per build.

**Response time.** A request may wait 30 s for a slot and then build for up to 60 s. Every proxy in front of the API
must allow at least **100 s** for `/api/v1/articles/*/pdf` (nginx `proxy_read_timeout 120s;`; IIS's ASP.NET Core Module
default of 2 minutes is enough; Cloudflare's proxied limit is exactly 100 s).

### Docker image

The SDK container build (`dotnet publish … /t:PublishContainer`, `backend.yml`) starts from
`mcr.microsoft.com/dotnet/aspnet`, which has no Chromium. .NET 10 has no Debian images (Microsoft publishes Ubuntu,
Alpine and Azure Linux ones; `10.0-trixie-slim` only existed as a preview tag), and Ubuntu's `chromium` package is a
snap shim that doesn't run in a container. So the base image is Debian 13 with Debian's real `chromium`, plus the
ASP.NET Core runtime copied from Microsoft's image:

```dockerfile
# api-base.Dockerfile: the API's base image, with Chromium for article PDFs. Rebuild it monthly: Debian's chromium
# follows Chrome stable with its security fixes, and the COPY takes the latest .NET 10 patch.
FROM debian:trixie-slim
COPY --from=mcr.microsoft.com/dotnet/aspnet:10.0-noble /usr/share/dotnet /usr/share/dotnet
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates libicu76 tzdata chromium \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
 && groupadd --gid 1654 app \
 && useradd --uid 1654 --gid app --create-home --no-log-init app
# As on Microsoft's images: the SDK container build reads the user and port from APP_UID and ASPNETCORE_HTTP_PORTS.
ENV APP_UID=1654 \
    ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
USER $APP_UID
```

```bash
docker build -t ghcr.io/<owner>/readin-api-base:chromium -f api-base.Dockerfile .
docker push ghcr.io/<owner>/readin-api-base:chromium
dotnet publish backend/src/ReadIn.Api -c Release /t:PublishContainer \
  -p:ContainerBaseImage=ghcr.io/<owner>/readin-api-base:chromium   # plus the registry/repository/tags of backend.yml
```

The API runs as the non-root `app` user (UID 1654); Chromium refuses to start its sandbox as root.

**The sandbox in a container.** Chromium's sandbox starts by creating a user namespace, and Docker's default seccomp
profile refuses that (`clone`/`unshare` with namespace flags need `CAP_SYS_ADMIN` there). Started the default way,
Chromium aborts with "No usable sandbox!" and every PDF answers `500 article.pdf_failed`. (Debian's hint to install
`chromium-sandbox` doesn't help in a container.) Run the API with Docker's default profile plus three rules:

```bash
# chromium-seccomp.json: Docker's default seccomp profile + what Chromium's sandbox needs, nothing else.
curl -fsSL https://raw.githubusercontent.com/moby/profiles/seccomp/v0.3.0/seccomp/default.json \
| jq '.syscalls += [
    {"names": ["clone", "unshare"], "action": "SCMP_ACT_ALLOW",
     "args": [{"index": 0, "value": 268435456, "valueTwo": 268435456, "op": "SCMP_CMP_MASKED_EQ"}],
     "comment": "Chromium sandbox: create a user namespace (CLONE_NEWUSER)"},
    {"names": ["clone"], "action": "SCMP_ACT_ALLOW",
     "args": [{"index": 0, "value": 2114060288, "valueTwo": 536870912, "op": "SCMP_CMP_MASKED_EQ"}],
     "comment": "Chromium sandbox: fork a renderer into a new PID namespace (CLONE_NEWPID alone)"},
    {"names": ["chroot"], "action": "SCMP_ACT_ALLOW",
     "comment": "Chromium sandbox: chroot inside its user namespace, also with every capability dropped"}
  ]' > chromium-seccomp.json
```

The rules let a process create a user namespace (what any user may do on a normal Linux host), let Chromium fork each
renderer into a new PID namespace from inside it, and allow the `chroot` Chromium makes inside that namespace (Docker
allows `chroot` only with `CAP_SYS_CHROOT`, so without this rule a container with every capability dropped fails). The
kernel still checks every call, and the container gets no capability. Each rule is needed: without the first Chromium
says "No usable sandbox!", without the second it hangs on "Zygote could not fork", without the third it fails once
capabilities are dropped. Never use `--cap-add SYS_ADMIN` or `seccomp=unconfined` instead: both open far more.

- `docker run`: `--security-opt seccomp=/etc/readin/chromium-seccomp.json`.
- Compose (the path is relative to the compose file):

  ```yaml
  services:
    api:
      image: ghcr.io/<owner>/readin-api:latest
      security_opt:
        - seccomp=./chromium-seccomp.json
  ```

- Kubernetes: containerd reads `Localhost` profiles in the OCI format and ignores Docker's `includes`/`excludes`, which
  would allow everything `CAP_SYS_ADMIN` unlocks. Convert the file for pods that drop every capability (x86-64), copy it
  to `/var/lib/kubelet/seccomp/readin/chromium-seccomp.json` on every node, and point the container at it:

  ```bash
  jq '{defaultAction, defaultErrnoRet,
       architectures: ["SCMP_ARCH_X86_64", "SCMP_ARCH_X86", "SCMP_ARCH_X32"],
       syscalls: [.syscalls[]
         | select((.includes.caps // []) == []
                  and ((.includes.arches // ["amd64"]) | index("amd64"))
                  and (((.excludes.arches // []) | index("amd64")) | not))
         | del(.includes, .excludes, .comment)]}' chromium-seccomp.json > chromium-seccomp.oci.json
  ```

  ```yaml
  securityContext:
    runAsNonRoot: true
    runAsUser: 1654
    allowPrivilegeEscalation: false
    capabilities: { drop: ["ALL"] }
    seccompProfile: { type: Localhost, localhostProfile: readin/chromium-seccomp.json }
  ```

**The host.** The kernel must allow unprivileged user namespaces: `sysctl user.max_user_namespaces` above 0 (the default
on current Debian and Ubuntu), and `kernel.unprivileged_userns_clone = 1` where that Debian-only setting exists. Ubuntu
23.10 and later also set `kernel.apparmor_restrict_unprivileged_userns = 1`, which applies to programs without an
AppArmor profile; containers run under Docker's `docker-default` profile, so it shouldn't affect them. If the check
below still fails only on such a host, give the container an AppArmor profile that allows `userns` rather than turning
the setting off for the whole server.

**Check it works**, on the server, with the image and options the API runs with:

```bash
docker run --rm --security-opt seccomp=/etc/readin/chromium-seccomp.json --entrypoint chromium \
  ghcr.io/<owner>/readin-api:latest --headless=new --disable-gpu --dump-dom 'data:text/html,<p>sandbox ok</p>'
```

It prints `<html><head></head><body><p>sandbox ok</p></body></html>` (D-Bus errors on stderr are harmless). Without the
profile it prints "No usable sandbox!". In the API's log, the first PDF writes `Started Chromium <version> for article
PDFs`; a start that fails writes `Chromium for article PDFs (…) did not start` with Chromium's output.

Verified on 2026-11-05 with this image (Debian chromium 156.0.8078.79, user `app`): the article PDF tests fail with
Docker's default profile and pass with `chromium-seccomp.json`, also with `--cap-drop ALL --security-opt
no-new-privileges`, and with the OCI version above.

### Windows Server / IIS

Install Google Chrome (it updates itself), or extract a pinned [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/)
build to e.g. `C:\ReadIn\chromium` and set `ArticlePdf__ChromiumPath=C:\ReadIn\chromium\chrome.exe` (then update it
yourself every month). The app pool identity needs **read & execute** on that folder and a writable `%TEMP%` (each
launch makes a throwaway profile there).

### Linux server (no Docker)

Debian: `sudo apt-get install chromium` (found at `/usr/bin/chromium`). Run the API as a normal user, never as root.
Debian allows unprivileged user namespaces, so the sandbox works as installed.

Ubuntu 23.10 and later: Ubuntu's `chromium` is a snap, so install Google Chrome (`google-chrome-stable` from Google's apt
repository). Ubuntu restricts user namespaces with AppArmor (`kernel.apparmor_restrict_unprivileged_userns = 1`) and
ships a profile that exempts `/opt/google/chrome/chrome` only. Any other Chrome or Chromium binary needs the same
one-rule profile that CI adds for its pinned Chrome (`backend.yml`, step "Chrome for article PDFs"); don't turn the
restriction off for the whole server.

Check either one as the API's user: `<chrome> --headless=new --disable-gpu --dump-dom 'data:text/html,<p>sandbox ok</p>'`
prints `<p>sandbox ok</p>` inside the page's HTML, or "No usable sandbox!".

### Local development and CI

- **Local:** an installed Chrome is found on its own (Windows, macOS, Linux). Otherwise set `ArticlePdf:ChromiumPath`
  in user-secrets, or `PUPPETEER_EXECUTABLE_PATH`.
- **Tests:** the article PDF tests (`ReadIn.Infrastructure.UnitTests/Pdf`, `ArticlePdfTests`) print with the real
  Chromium found the same way, sandbox on, so it must be installed where the tests run.
- **CI** (`backend.yml`, step "Chrome for article PDFs"): the runner's own browsers change with every runner image, and
  the API would pick its `/usr/bin/chromium` first, a Chromium snapshot that Ubuntu 24.04's AppArmor restriction leaves
  without a sandbox ("No usable sandbox!", every PDF test failing). So CI downloads a pinned
  [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/) build (`CHROME_VERSION`), loads a
  one-rule AppArmor profile that lets only that binary create user namespaces (the restriction stays on for everything
  else), starts it once with its sandbox so a sandbox problem fails that step, and exports `PUPPETEER_EXECUTABLE_PATH`.
  To move CI to a newer Chrome, change `CHROME_VERSION` to a version listed there, and re-approve the Linux page images
  if they change.
- **Page baselines:** page 1 of the Arabic and the English stress fixture is compared with an approved image, with a
  small tolerance: `Pdf/baselines/*.page1.png` on Windows and `*.page1.linux.png` on Linux. The layout is the same, but
  Chrome places glyphs a fraction of a pixel differently on Linux, which moves text edges by more than the tolerance
  allows. After a deliberate layout change:
  - Windows: set `READIN_PDF_BASELINES_DIR` to `backend/tests/ReadIn.Infrastructure.UnitTests/Pdf/baselines`, run the
    test once, look at the new images and commit them.
  - Linux: push. The failing CI run uploads the new images as the `pdf-page-images` artifact, already named
    `*.linux.png`. Download them with `gh run download <run-id> -n pdf-page-images -D
    backend/tests/ReadIn.Infrastructure.UnitTests/Pdf/baselines`, look at them, and commit them. On any Linux machine
    the same variable writes them too, with the Chrome version of `CHROME_VERSION` (Debian's chromium 156.0.8078.79 and
    Chrome for Testing 156.0.8078.80 gave byte-identical images).

  `READIN_PDF_OUT=<folder>` writes the test PDFs and every page as PNG for a look.
