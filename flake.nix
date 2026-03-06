{
  description = "home management for tcurdt";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;
      username = "tcurdt";

      systems = [
        "aarch64-darwin"
        # "x86_64-darwin"
        "x86_64-linux"
        # "aarch64-linux"
      ];

      forAllSystems = lib.genAttrs systems;

      homeDirBySystem = {
        aarch64-darwin = "/Users/${username}";
        x86_64-darwin = "/Users/${username}";
        x86_64-linux = "/home/${username}";
        aarch64-linux = "/home/${username}";
      };

      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [
            self.homeManagerModules.tcurdt
            {
              home.username = username;
              home.homeDirectory = homeDirBySystem.${system};
            }
          ];
        };

      mkSwitchApp =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hm = "${home-manager.packages.${system}.home-manager}/bin/home-manager";
          app = pkgs.writeShellScriptBin "home-switch" ''
            set -euo pipefail
            exec ${hm} switch --flake ".#${username}-${system}" "$@"
          '';
        in
        {
          type = "app";
          program = "${app}/bin/home-switch";
          meta.description = "Switch Home Manager for current system";
        };

      mkCheckApp =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hm = "${home-manager.packages.${system}.home-manager}/bin/home-manager";
          app = pkgs.writeShellScriptBin "home-check" ''
            set -euo pipefail
            exec ${hm} build --flake ".#${username}-${system}" "$@"
          '';
        in
        {
          type = "app";
          program = "${app}/bin/home-check";
          meta.description = "Build Home Manager for current system";
        };
    in
    {
      homeManagerModules = {
        tcurdt =
          { ... }:
          {
            imports = [
              ./modules/common.nix
              ./modules/darwin.nix
              ./modules/linux.nix
            ];
          };
        common = import ./modules/common.nix;
        darwin = import ./modules/darwin.nix;
        linux = import ./modules/linux.nix;
      };

      homeConfigurations = lib.listToAttrs (
        map (system: {
          name = "${username}-${system}";
          value = mkHome system;
        }) systems
      );

      apps = forAllSystems (system: {
        home-switch = mkSwitchApp system;
        home-check = mkCheckApp system;
      });

      checks = forAllSystems (system: {
        home = (mkHome system).activationPackage;
      });
    };
}
