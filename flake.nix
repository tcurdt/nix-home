{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    comin.url = "github:nlewo/comin/v0.11.0";
    comin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      comin,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        # home-goe = nixpkgs.lib.nixosSystem {
        #   specialArgs = { inherit inputs; };
        #   modules = [
        #     ./machines/home-goe.nix
        #     comin.nixosModules.comin
        #     (import ./modules/comin.nix)
        #   ];
        # };

        home-ber = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./machines/home-ber.nix
            comin.nixosModules.comin
            (import ./modules/comin.nix)
          ];
        };
      };
    };
}
