# Settings shared by every server in this repository.
{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Set your time zone.
  time.timeZone = "Europe/Vienna";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_AT.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
    LC_MONETARY = "de_AT.UTF-8";
    LC_NAME = "de_AT.UTF-8";
    LC_NUMERIC = "de_AT.UTF-8";
    LC_PAPER = "de_AT.UTF-8";
    LC_TELEPHONE = "de_AT.UTF-8";
    LC_TIME = "de_AT.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "at";
    variant = "";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    bash # required for copilot
    curl
    devenv
    dig
    git
    gnupg
    htop
    lm_sensors
    nvd
    niv
    smartmontools
    tmux
    vim
    wget
  ];

  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."roock" = {
    isNormalUser = true;
    description = "Roman Pertl";
    extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE14M+Iid87Kcm8JL5V7qqgWobsfSKB7NZEFbXeevkrn rpertl@PC-WIEN-97"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBE7qZOeBeQn1bMBa/CB9QfwhOpGtidLGMojoNg6QkQ7tW03ZKwHos7fNmeN8/tDoLjsQz4Sd01BRkHUcdw6xUwY= roman.pertl@secretive.MBP-04.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIMt7RsXQszuAxz8ysgDXmvV+DTdi/q+gCRBqaVHn/47 cardno:19_779_699"
    ];
    packages = with pkgs; [
      bat
      glab
      github-copilot-cli
      betterleaks
      inxi
      ipcalc
      ncdu
      pwgen
      python3
      whois
      tig
    ];
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.roock = import ../home/roock.nix;

  users.defaultUserShell = pkgs.zsh;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    KbdInteractiveAuthentication = false;
    StreamLocalBindUnlink = true;
  };
  # Do not open the firewall for the OpenSSH service on all servers.
  # This service will be opened on each server individually if needed.
  services.openssh.openFirewall = false;
}
