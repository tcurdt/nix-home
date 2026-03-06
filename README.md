# nix-home

Personal Home Manager setup as a reusable flake module.

## What this provides

- `homeManagerModules.tcurdt` as the main module to import from other flakes
- Platform-specific layering via `modules/darwin.nix` and `modules/linux.nix`
- Helper commands:
  - `nix run .#home-check` to build/validate the current system target
  - `nix run .#home-switch` to apply the current system target

## Local usage

```bash
nix flake check path:.
nix run .#home-check
# nix run .#home-switch
```

## Consume from another flake

Add input:

```nix
inputs.home.url = "github:tcurdt/nix-home";
```

Import module:

```nix
home-manager.users.tcurdt.imports = [
  inputs.home.homeManagerModules.tcurdt
];
```

## Layout

- `modules/common.nix`: shared config
- `modules/darwin.nix`: macOS-specific additions
- `modules/linux.nix`: Linux-specific additions
- `flake.nix`: exports `homeManagerModules.tcurdt` and composes modules
