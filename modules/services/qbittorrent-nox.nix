{ config, pkgs, lib, ... }:

{
	services.qbittorrent = {
		enable = true;
		webuiPort = 8001;
		torrentingPort = 7000;
	};
}
