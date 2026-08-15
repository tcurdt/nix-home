{
  # pkgs,
  ...
}:
{
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/tcurdt/nix-home.git";
        branches.main.name = "main";
        # auth.access_token_path = cfg.sops.secrets."gitlab/access_token".path;
        poller.period = 60;
      }
    ];
  };

}
