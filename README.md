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

## Home Manager

User environments are managed with [Home Manager](https://github.com/nix-community/home-manager), which is wired in as a NixOS module in `nix/flake.nix`.

- `nix/home/<user>.nix` - the Home Manager config for a user (currently `roock`). It applies to every server that imports the user in `nix/modules/common.nix`.
- Set `home-manager.users.<user>` in `nix/modules/common.nix` to point at that file.
- Per-server user settings can go in `nix/servers/<hostname>/configuration.nix` under `home-manager.users.<user>`.
- Home Manager follows the system `nixpkgs` input, and `useGlobalPkgs` is enabled, so user packages use the same nixpkgs as the system.
- Changes apply with the normal rebuild command (see above). No separate `home-manager switch` is needed.

## Updating the flake lock

Run from `nix/`:

```bash
nix flake update              # update all inputs
nix flake update nixpkgs      # update a single input
```

Review the diff, then commit `nix/flake.lock` and rebuild the servers to apply the new versions.
