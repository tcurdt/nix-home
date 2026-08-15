{
  inputs,
  ...
}:
{
  imports = [ inputs.comin.nixosModules.comin ];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/tcurdt/nix-home.git";
        branches.main.name = "main";
        poller.period = 60;

        # auth.access_token_path = cfg.sops.secrets."gitlab/access_token".path;
      }
    ];
  };

}
