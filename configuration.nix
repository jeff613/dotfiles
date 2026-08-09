{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyleSwitchesAutomatically = true;  # light by day, dark by night
      AppleShowAllExtensions = true;
      "com.apple.swipescrolldirection" = false;  # reversed (non-natural) scrolling
    };
  };
  # Keep HM per-user packages on PATH via the managed /etc/zshrc.
  programs.zsh.enable = true;
  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
      "pi-coding-agent"
    ];
    casks = [
      "ghostty"
      "visual-studio-code"
      "google-chrome"
      "claude-code"
    ];
  };
}
