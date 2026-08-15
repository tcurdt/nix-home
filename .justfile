check:
    nix flake check --all-systems path:.

build:
    nix build --eval-store daemon --store ssh-ng://home-ber --no-link path:.#nixosConfigurations.home-ber.config.system.build.toplevel

switch:
    nixos-rebuild switch --flake .
