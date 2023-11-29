{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "ipinfo";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = pname;
    repo = "cli";
    rev = "refs/tags/${pname}-${version}";
    hash = "sha256-bqA8Y3mVHSwhUcvr3biWbH6K73MYmo3f7wSMS4J+Bk8=";
  };

  vendorHash = null;

  # Tests require network access
  doCheck = false;

  meta = with lib; {
    description = "Command Line Interface for the IPinfo API";
    homepage = "https://github.com/ipinfo/cli";
    changelog = "https://github.com/ipinfo/cli/releases/tag/ipinfo-${version}";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ fab ];
  };
}
