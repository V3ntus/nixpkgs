{ pkgs, buildGoModule, fetchFromGitHub, lib, perl }:

buildGoModule rec {
  pname = "XD";
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "majestrate";
    repo = "XD";
    rev = "v${version}";
    sha256 = "sha256-u8cUcxNW2jAWxVn1hDHS2cpIpcyv4lwx1zytlzPPdv4=";
  };

  vendorHash = "sha256-ZD7PZJcY7qWHEQOk5I9IlMup0vbYYaRvVau5Go7ocno=";

  nativeCheckInputs = [ perl ];

  postInstall = ''
    ln -s $out/bin/XD $out/bin/XD-CLI
  '';

  meta = with lib; {
    description = "i2p bittorrent client";
    homepage = "https://xd-torrent.github.io";
    maintainers = with maintainers; [ nixbitcoin ];
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
