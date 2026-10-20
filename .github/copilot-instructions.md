# Copilot Instructions for Homelab Repository

## Project Overview

This is a multi-server homelab repository managing NixOS systems running k3s (Kubernetes) clusters with ArgoCD for declarative GitOps deployments. Infrastructure and applications are defined as code, with secrets encrypted using SOPS.

**Key technologies:**
- **NixOS**: Declarative, reproducible system configuration for each server
- **k3s**: Lightweight Kubernetes runtime on each NixOS server
- **ArgoCD**: GitOps tool for deploying applications to k3s clusters
- **SOPS**: Secret encryption with age/GPG for safe version control
- **Lefthook**: Git hooks for pre-commit validation (yamllint, betterleaks)

## Build, Test, and Lint Commands

**Git hooks (via Lefthook) automatically run on commit:**
- `yamllint`: Validates all YAML files in the repository
- `betterleaks`: Scans for accidentally committed secrets before they reach the repo
- Pre-commit hooks prevent commits with plain-text secrets or invalid YAML

**Manual validation commands:**
```bash
# Run all pre-commit checks manually
lefthook run pre-commit

# Individual checks
yamllint .                                    # Lint all YAML
betterleaks scan                              # Scan for secrets
sops -d kubernetes/secrets/app.sops.yaml     # Decrypt and view secrets
nix flake check                               # Validate flake.nix
kubectl --dry-run=client -f manifest.yaml    # Validate k8s manifest
argocd app get app-name                       # Check ArgoCD application status
```

**Before committing any changes:**
- Ensure all secrets are encrypted with SOPS (`.sops.yaml` rules apply)
- Never commit plain-text secrets; use SOPS encrypted files
- Run `lefthook run pre-commit` locally to catch issues early

## Architecture Patterns

### Expected Directory Structure

```
.
├── nix/                           # NixOS server configurations
│   ├── flake.nix                 # Nix flake with all inputs and outputs
│   ├── flake.lock                # Lock file (commit this)
│   └── servers/
│       ├── server1/              # Individual server configs
│       │   ├── configuration.nix
│       │   └── hardware-configuration.nix
│       └── server2/
│
├── kubernetes/                    # k3s and ArgoCD configurations
│   ├── clusters/                 # Per-cluster configs
│   │   ├── main/
│   │   │   ├── argocd-apps/     # ArgoCD Application definitions (GitOps)
│   │   │   └── system/           # System namespace manifests
│   │   └── backup/
│   ├── applications/             # Shared application definitions
│   └── secrets/                  # SOPS-encrypted secrets
│       ├── .sops.yaml            # SOPS encryption rules
│       └── *.sops.yaml           # Encrypted secret files
│
├── .lefthook.yaml               # Lefthook git hooks configuration
├── .sops.yaml                   # SOPS encryption config (defines rules)
└── docs/                        # Setup and operation documentation
```

### Key Technologies

**NixOS Configuration:**
- Each server has a declarative configuration in `nix/servers/`
- Use `flake.nix` to manage dependencies and outputs
- Import shared modules for consistency across servers

**k3s & Kubernetes:**
- k3s runs on each NixOS server (configured via NixOS module)
- Manifests are YAML in `kubernetes/` organized by cluster
- All manifests are static YAML—no templating (rely on ArgoCD)

**ArgoCD (GitOps):**
- Application definitions in `kubernetes/clusters/[cluster]/argocd-apps/`
- ArgoCD syncs applications from this repo to k3s clusters
- Changes to this repo automatically trigger deployments
- Pattern: One `Application` resource per app, pointing to app manifests

**SOPS Secret Encryption:**
- Secrets stored in `.sops.yaml` files (encrypted)
- `.sops.yaml` rules define which keys encrypt with which keys (age or GPG)
- Decrypted by k3s at runtime via sealed-secrets or external-secrets
- Never store unencrypted secrets in the repo

**Lefthook Git Hooks:**
- Prevents commits with unencrypted secrets (betterleaks scan)
- Validates YAML syntax (yamllint)
- Ensures code quality before it reaches the repository

## Key Conventions

### Secret Management (SOPS)

**CRITICAL: Secrets must ALWAYS be encrypted with SOPS before committing**

- All files containing secrets use `.sops.yaml` extension (e.g., `app-secrets.sops.yaml`)
- Encryption rules defined in `.sops.yaml` at repo root
  - Typically uses `age` for new keys or GPG for compatibility
  - Different keys can be used for different environments (dev, prod)
- To create encrypted secrets:
  ```bash
  sops -i kubernetes/secrets/myapp.sops.yaml    # Edit encrypted file
  # SOPS will decrypt → open editor → encrypt on save
  ```
- To view secrets without editing:
  ```bash
  sops -d kubernetes/secrets/myapp.sops.yaml | less
  ```
- **Never** store unencrypted secrets in this repo; betterleaks will catch them on commit
- Consider using sealed-secrets or external-secrets in k3s for runtime decryption

### NixOS Configuration

- **Naming**: `configuration.nix` for system config, `hardware-configuration.nix` for hardware-specific settings
- **Modules**: Extract reusable configuration into modules in `nix/modules/` or `nix/common/`
- **Imports**: Use absolute paths from `flake.nix` for consistency
- **Comments**: Document non-obvious configurations, especially k3s settings
- **k3s integration**: Configure k3s via NixOS modules
  ```nix
  services.k3s.enable = true;
  services.k3s.role = "server";  # or "agent" for worker nodes
  ```

### Kubernetes Manifests

- **File naming**: Use descriptive lowercase names: `deployment.yaml`, `service.yaml`, `configmap.yaml`
- **Organization**: Group by cluster and namespace
  ```
  kubernetes/clusters/main/argocd-apps/        # ArgoCD Applications
  kubernetes/clusters/main/default/             # Manifests for default namespace
  kubernetes/clusters/main/monitoring/          # Monitoring namespace manifests
  ```
- **Labels and selectors**: Use consistent labels
  ```yaml
  labels:
    app: myapp
    cluster: main
    environment: production
  ```
- **No Helm/Kustomize**: Use static YAML manifests; let ArgoCD handle orchestration
- **Secrets in manifests**: Never hardcode; reference SOPS-encrypted files

### ArgoCD Applications

- One `Application` resource per deployed application
- Stored in `kubernetes/clusters/[cluster]/argocd-apps/`
- Example pattern:
  ```yaml
  apiVersion: argoproj.io/v1alpha1
  kind: Application
  metadata:
    name: myapp
    namespace: argocd
  spec:
    project: default
    source:
      repoURL: https://github.com/roock/homelab
      targetRevision: main
      path: kubernetes/clusters/main/applications/myapp
    destination:
      server: https://kubernetes.default.svc
      namespace: default
  ```
- ArgoCD automatically syncs when repo changes

### Lefthook Configuration

- `lefthook.yaml` defines pre-commit hooks
- Runs before every commit to catch issues early
- **Pre-commit checks:**
  1. `betterleaks`: Scans for accidentally committed secrets
  2. `yamllint`: Validates YAML syntax for all `.yaml` files
- If checks fail, commit is blocked—fix issues and try again
- To run hooks manually: `lefthook run pre-commit`

### Git Workflow

- Commit encrypted secret files (`.sops.yaml`) normally
- Never commit unencrypted secrets—betterleaks will block it
- `.gitignore` should include:
  - `*.env` files (if used for local development)
  - Nix build artifacts: `result/`, `.dirlocal`
  - Editor artifacts: `.DS_Store`, `*.swp`, `*~`
  - Kubernetes kubeconfigs: `kubeconfig`, `*.kubeconfig`

### YAML Style

- Use consistent indentation (2 spaces)
- Keep lines reasonably short for readability
- Sort keys alphabetically when it aids readability
- Kubernetes manifests: `apiVersion`, `kind`, `metadata`, `spec` order

## Backup & Disaster Recovery

**Strategy:** Data is backed up to Backblaze using restic and/or Velero

### Restic (File-level backups)
- Backs up persistent volumes and important data to Backblaze B2
- Configure in NixOS or via Kubernetes cronjobs
- Store Backblaze credentials in SOPS-encrypted secrets
- Typical pattern: Daily incremental backups with weekly full backups
- Recovery: `restic restore` to recover individual files or entire snapshots

### Velero (Kubernetes cluster backups)
- Full cluster backup and restore (resources, PVCs, namespaces)
- Backblaze B2 as storage backend via Velero plugin
- Store credentials in SOPS-encrypted secrets
- Automate via Velero schedules for regular backups
- Recovery: Point-in-time cluster restore or restore specific resources

### Backup Configuration Files
- Backup jobs and schedules stored in `kubernetes/clusters/[cluster]/backup/`
- Document backup retention policies and RTO/RPO targets
- Store cloud provider credentials in SOPS-encrypted secrets
- Test restore procedures regularly; document recovery steps

### Documentation
- Document backup strategy in `docs/backup-recovery.md`
- Include runbooks for both restic and Velero restore procedures
- List recovery time objectives (RTO) and recovery point objectives (RPO)
- Document how to access Backblaze B2 and recover if repo is lost

## Development Workflow

When adding new servers, applications, or infrastructure:

1. **For a new NixOS server:**
   - Create `nix/servers/[servername]/configuration.nix`
   - Include common modules from `nix/modules/`
   - Configure k3s via NixOS modules
   - Test flake: `nix flake check`

2. **For a new Kubernetes application:**
   - Create manifests in `kubernetes/clusters/[cluster]/applications/[appname]/`
   - Reference secrets via SOPS-encrypted files or sealed-secrets
   - Create ArgoCD `Application` in `kubernetes/clusters/[cluster]/argocd-apps/`

3. **For secrets:**
   - Create `.sops.yaml` file with sensitive data
   - Encrypt immediately: `sops -i kubernetes/secrets/[appname].sops.yaml`
   - Never commit unencrypted secrets
   - Verify with: `sops -d kubernetes/secrets/[appname].sops.yaml`

4. **Before committing:**
   - Run `lefthook run pre-commit` to validate
   - Ensure all secrets are encrypted
   - Check YAML syntax is valid
   - Never force-push if pre-commit fails

5. **Documentation:**
   - Add server docs to `docs/servers/[servername].md`
   - Document application setup in `docs/applications/[appname].md`
   - Update README with any new prerequisites

## Common Commands

```bash
# NixOS
nix flake update                              # Update inputs
nix flake check                               # Validate flake configuration
nixos-rebuild switch --flake .#[hostname]    # Apply config to a server

# Kubernetes
kubectl get applications -n argocd            # List ArgoCD applications
kubectl get all -n [namespace]                # Check deployed resources
k3s kubectl logs deployment/[app] -n [ns]     # View application logs

# SOPS Secrets
sops -i kubernetes/secrets/myapp.sops.yaml   # Edit encrypted file
sops -d kubernetes/secrets/myapp.sops.yaml   # View decrypted content

# Backups
restic backup /path/to/data                   # Backup with restic
restic snapshots                              # List backups
velero backup create mybackup                 # Create cluster backup with Velero
velero restore create --from-backup mybackup  # Restore from cluster backup

# Git Hooks
lefthook run pre-commit                       # Run all pre-commit checks manually
lefthook install                              # Install git hooks (run once)
```

## Notes for Copilot Sessions

- **Secrets-first approach**: Always encrypt secrets with SOPS before committing. Never ask "should we encrypt this?"—always encrypt.
- **GitOps mindset**: All changes should be git-based. If it's not in this repo, it's not deployed.
- **Validate before suggesting**: Test YAML with `kubectl --dry-run=client`, Nix with `nix flake check`.
- **Cross-server consistency**: Use NixOS modules to keep configurations consistent across servers.
- **ArgoCD automation**: Remember that ArgoCD watches this repo—changes here trigger deployments.
- **Lefthook is your friend**: Respect pre-commit hooks; they prevent secrets from leaking.
- **Backup strategy**: Restic and Velero provide both file-level and cluster-level recovery; both should be configured and tested regularly.
- **Document as you go**: When adding a new service or server, update the relevant docs and backup strategy if needed.
- **k3s is lightweight**: Designs should account for k3s resource constraints compared to full Kubernetes.
- **Multiple clusters**: Be aware which cluster a configuration applies to (main, backup, etc.).
