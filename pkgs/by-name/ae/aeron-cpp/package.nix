{
  autoPatchelfHook,
  aeron,
  cmake,
  fetchFromGitHub,
  fetchMavenArtifact,
  jdk11,
  lib,
  libbsd,
  libuuid,
  makeWrapper,
  patchelf,
  stdenv,
  zlib
}:

let
  version = aeron.version;

  sbeAll_1_30_0 = fetchMavenArtifact {
    groupId = "uk.co.real-logic";
    version = "1.30.0";
    artifactId = "sbe-all";
    hash = "sha512-K/LMP6zNBHl2Wpvli/sH+ZsYwlTPJHHCKee7riOH6dR8nxTJgucnF7AsbVOpowR6xaV3wPjFh0iqWp/oerHKBg==";
  };

  sbeAll = sbeAll_1_30_0;

in

stdenv.mkDerivation {
  pname = "aeron-cpp";
  inherit version;

  src = fetchFromGitHub {
    owner = "real-logic";
    repo = "aeron";
    rev = version;
    hash = "sha256-MY7I8Cw1izVLW3/JWav9zPIBJTGInZHwAZT2e7tI9F0=";
  };

  patches = [
    ./aeron-all.patch
    # Use pre-built aeron-all.jar from Maven repo, avoiding Gradle

    ./aeron-archive-sbe.patch
    # Use SBE tool to generate C++ codecs, avoiding Gradle
  ];

  buildInputs = [
    libbsd
    libuuid
    zlib
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    cmake
    jdk11
    makeWrapper
    patchelf
  ];

  configurePhase = ''
    runHook preConfigure

    mkdir --parents cppbuild/Release
    (
      cd cppbuild/Release
      cmake \
        -G "CodeBlocks - Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DAERON_TESTS=OFF \
        -DAERON_SYSTEM_TESTS=OFF \
        -DAERON_BUILD_SAMPLES=OFF \
        -DCMAKE_INSTALL_PREFIX:PATH=../../install \
        ../..
    )

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    ln --symbolic  "${aeron.jar}" ./aeron-all.jar
    ln --symbolic  "${sbeAll.jar}" ./sbe.jar
    mkdir --parents aeron-all/build/libs
    (
      cd cppbuild/Release

      make -j $NIX_BUILD_CORES \
        aeron \
        aeron_archive_client \
        aeron_client_shared \
        aeron_driver \
        aeron_client \
        aeron_driver_static \
        aeronmd

      make -j $NIX_BUILD_CORES install
    )

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir --parents "$out"
    cp --archive --verbose --target-directory="$out" install/*

    runHook postInstall
  '';

  meta = with lib; {
    description = "Aeron Messaging C++ Library";
    homepage = "https://aeron.io/";
    license = licenses.asl20;
    mainProgram = "aeronmd";
    maintainers = [ maintainers.vaci ];
    sourceProvenance = [
      sourceTypes.fromSource
      sourceTypes.binaryBytecode
    ];
  };
}

