# MacBook Air 13" A1466 (2013-2017, MacBookAir6,2 / MacBookAir7,2)
#
# Full disk encryption: one LUKS2 partition holds the ext4 root, and swap is a
# file on that root, so /home and swap are both encrypted at rest. The
# passphrase is asked for at boot.
#
# Install from the NixOS installer (disk is usually /dev/sda):
#
#   parted /dev/sda -- mklabel gpt
#   parted /dev/sda -- mkpart ESP fat32 1MiB 1GiB
#   parted /dev/sda -- set 1 esp on
#   parted /dev/sda -- mkpart crypt 1GiB 100%
#
#   mkfs.fat -F 32 -n boot /dev/disk/by-partlabel/ESP
#   cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/crypt
#   cryptsetup open /dev/disk/by-partlabel/crypt crypt
#   mkfs.ext4 -L root /dev/mapper/crypt
#
#   mount /dev/mapper/crypt /mnt
#   mount -o umask=077 --mkdir /dev/disk/by-label/boot /mnt/boot
#   nixos-install --flake .#<machine>
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
    # the internal keyboard is USB, it has to work in the initrd to type the passphrase
    "usbhid"
    "hid_generic"
    "hid_apple"
  ];
  boot.initrd.kernelModules = [ "dm-crypt" ];

  boot.initrd.luks.devices.crypt = {
    device = "/dev/disk/by-partlabel/crypt";
    # TRIM on the SSD; leaks which blocks are unused, but not their content
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  fileSystems."/" = {
    device = "/dev/mapper/crypt";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # lives on the encrypted root
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024; # MiB
    }
  ];

  services.fstrim.enable = true;

  # cpu

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  boot.kernelModules = [ "kvm-intel" ];
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # wifi: the original BCM4360 was swapped for a BCM43224 [14e4:4353], which
  # uses the in-kernel brcmsmac driver plus firmware from
  # enableRedistributableFirmware. Without a regulatory domain it falls back to
  # the conservative world settings.
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="DE"
  '';
  #
  # if brcmsmac is unstable, or with the original BCM4360 (which brcmsmac does
  # not support), use the proprietary (insecure, unfree) driver:
  #   boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  #   boot.kernelModules = [ "wl" ];
  #   boot.blacklistedKernelModules = [ "b43" "bcma" "brcmfmac" "brcmsmac" "ssb" ];
  #   nixpkgs.config.allowInsecurePredicate = pkg: lib.getName pkg == "broadcom-sta";
  #   nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "broadcom-sta";

  # fan control via applesmc

  services.mbpfan.enable = lib.mkDefault true;

  # camera needs unfree firmware
  # hardware.facetimehd.enable = true;

  networking.useDHCP = lib.mkDefault true;
}
