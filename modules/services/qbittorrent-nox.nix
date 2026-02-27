{ config, pkgs, lib, ... }:

{
	services.qbittorrent = {
		enable = true;
		webuiPort = 8080;
		torrentingPort = 7000;
	};
}
