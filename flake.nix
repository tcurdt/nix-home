{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    comin.url = "github:nlewo/comin";
    comin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    {
      nixosConfigurations = {

        # home-goe = nixpkgs.lib.nixosSystem {
        #   specialArgs = { inherit inputs; };
        #   modules = [
        #     ./machines/home-goe.nix
        #     ./modules/comin.nix
        #   ];
        # };

        home-ber = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./machines/home-ber.nix
            ./modules/comin.nix
          ];
        };

      };
    };
}
