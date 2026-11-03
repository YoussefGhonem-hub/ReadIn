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
   `robocopy "<run>\uploads" "C:\inetpub\readin-api\wwwroot\uploads" /MIR`.
4. Start the API. Check a few avatars and covers in the app.

## 7. Limitation: one server

Local uploads only work with **one** API instance: a second instance would not see the first one's files.
Before scaling out (or moving images to a CDN-backed bucket), swap the `IFileStorage` implementation for shared or
cloud storage. Stored paths stay valid, so no data migration is needed. Steps: [ADR 0010 → Migration path](../adr/0010-uploads-in-wwwroot.md#migration-path).
