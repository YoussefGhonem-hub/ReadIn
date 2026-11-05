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

Each upgrade waits until its migration is applied and does nothing once it is done (one or two small queries per
start), so running it again is always safe.

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
`mcr.microsoft.com/dotnet/aspnet`, which has no Chromium. Publish onto a base image that has it:

```dockerfile
# Base image for the API with Chromium (rebuild it monthly for Chromium's security fixes).
# A Debian tag: Debian ships a real `chromium` package (Ubuntu's is only a snap shim and doesn't run in a container).
FROM mcr.microsoft.com/dotnet/aspnet:10.0-trixie-slim
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends chromium \
 && rm -rf /var/lib/apt/lists/*
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
USER app
```

```bash
docker build -t ghcr.io/<owner>/readin-api-base:chromium -f api-base.Dockerfile .
docker push ghcr.io/<owner>/readin-api-base:chromium
dotnet publish backend/src/ReadIn.Api -c Release /t:PublishContainer \
  -p:ContainerBaseImage=ghcr.io/<owner>/readin-api-base:chromium   # plus the registry/repository/tags of backend.yml
```

The API runs as the non-root `app` user, which Chromium's sandbox needs. The sandbox also needs unprivileged user
namespaces: if Chromium fails to start with "No usable sandbox!", run the container with Chrome's seccomp profile
(`--security-opt seccomp=chrome.json`, from the Chromium/Puppeteer docs) or on a host that allows user namespaces
(`kernel.unprivileged_userns_clone=1`). Don't turn the sandbox off instead.

### Windows Server / IIS

Install Google Chrome (it updates itself), or extract a pinned [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/)
build to e.g. `C:\ReadIn\chromium` and set `ArticlePdf__ChromiumPath=C:\ReadIn\chromium\chrome.exe` (then update it
yourself every month). The app pool identity needs **read & execute** on that folder and a writable `%TEMP%` (each
launch makes a throwaway profile there).

### Linux server (no Docker)

Debian: `sudo apt-get install chromium` (found at `/usr/bin/chromium`). Run the API as a normal user, never as root.

### Local development and CI

- **Local:** an installed Chrome is found on its own (Windows, macOS, Linux). Otherwise set `ArticlePdf:ChromiumPath`
  in user-secrets, or `PUPPETEER_EXECUTABLE_PATH`.
- **Tests:** the article PDF tests (`ReadIn.Infrastructure.UnitTests/Pdf`, `ArticlePdfTests`) print with the real
  Chromium found the same way, so it must be installed where the tests run. GitHub's `ubuntu-latest` runner already
  has Google Chrome at `/usr/bin/google-chrome`. To pin a version there, add a step such as
  `browser-actions/setup-chrome` with a fixed `chrome-version` and export its path as `PUPPETEER_EXECUTABLE_PATH`.
- **Page baselines:** two page images (`Pdf/baselines/*.png`, one Arabic, one English) are compared with a small
  tolerance. After a deliberate layout change, set `READIN_PDF_BASELINES_DIR` to that folder, run the test once, look
  at the new images and commit them. `READIN_PDF_OUT=<folder>` writes the test PDFs and every page as PNG for a look.
