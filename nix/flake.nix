{
  description = "Homelab NixOS server configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      # Every directory under servers/ that contains a configuration.nix is a host.
      serverNames = builtins.attrNames (
        nixpkgs.lib.filterAttrs
          (name: type: type == "directory" && builtins.pathExists (./servers + "/${name}/configuration.nix"))
          (builtins.readDir ./servers)
      );

      mkServer = name: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit self; };
        modules = [
          home-manager.nixosModules.home-manager
          ./modules/common.nix
          (./servers + "/${name}/configuration.nix")
          { networking.hostName = name; }
        ];
      };
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs serverNames mkServer;
    };
}
