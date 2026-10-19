let
  tom-wsl = builtins.readFile ./ssh/users/tom-wsl.pub;
  tom-win = builtins.readFile ./ssh/users/tom-win.pub;
  tom-zorn = builtins.readFile ./ssh/users/tom-zorn.pub;
  tom-iphone17 = builtins.readFile ./ssh/users/tom-iphone17.pub;
  tom = [ tom-wsl tom-win tom-zorn tom-iphone17 ];

  rpi3 = builtins.readFile ./ssh/hosts/rpi3.pub;
  systems = [ rpi3 ];
in
{
  "miniflux.age".publicKeys = [rpi3] ++ tom;
  "cloudflare-dns.age".publicKeys = [rpi3] ++ tom;
  "acme-email.age".publicKeys = [rpi3] ++ tom;
  "rpi3-wireguard-pr.age".publicKeys = [rpi3] ++ tom;
  "rpi3-wireguard-sh.age".publicKeys = [rpi3] ++ tom;
  "vaultwarden.age".publicKeys = [rpi3] ++ tom;
}