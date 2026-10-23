# Homelab

NixOS servers running k3s, with ArgoCD for GitOps deployments and SOPS for secrets.

## Repository layout

- `nix/` - NixOS flake. Each directory in `nix/servers/` is one host, named after the directory.
- `nix/modules/` - settings shared by all servers.
- `kubernetes/` - ArgoCD applications and manifests, organized by cluster.
- `docs/` - setup and operation notes.

## Adding a server

1. Copy `nix/servers/server1/` to `nix/servers/<hostname>/`.
2. On the machine, generate its hardware configuration:

   ```bash
   sudo nixos-generate-config --show-hardware-config > nix/servers/<hostname>/hardware-configuration.nix
   ```

3. Import it in `nix/servers/<hostname>/configuration.nix`:

   ```nix
   imports = [ ./hardware-configuration.nix ];
   ```

4. Check the flake and commit. Flakes only see git-tracked files, so `git add` the new files first.

## Rebuilding a server

Run on the server, from a clone of this repo:

```bash
sudo nixos-rebuild switch --flake ./nix#<hostname>
```

Run `nix flake check` from `nix/` to validate the flake before rebuilding.

## Updating the flake lock

Run from `nix/`:

```bash
nix flake update              # update all inputs
nix flake update nixpkgs      # update a single input
```

Review the diff, then commit `nix/flake.lock` and rebuild the servers to apply the new versions.
