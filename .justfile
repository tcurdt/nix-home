set quiet

check:
    nix flake check --all-systems path:.

# local version
build:
    nix build --eval-store daemon --store ssh-ng://home-ber --no-link path:.#nixosConfigurations.home-ber.config.system.build.toplevel

# local version (better disable comin)
switch:
    nix run --inputs-from . nixpkgs#nixos-rebuild -- switch --no-reexec --flake .#home-ber --build-host home-ber --target-host home-ber

# comin
released:
    ssh home-ber \
      "nixos-rebuild switch --flake github:tcurdt/nix-home#home-ber"
