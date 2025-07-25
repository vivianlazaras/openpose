{
  description = "Flake to build OpenPose (CPU-only) with vendored Caffe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Fetch Caffe and vendor it manually
        caffeSrc = pkgs.fetchFromGitHub {
          owner = "BVLC";
          repo = "caffe";
          rev = "1.0"; # Replace with correct revision
          hash = "sha256-Q6aWb5ck6gp/bbUMr/l6/hxqpNUPHngbG3EIVNm4koA=";
        };

        openpose = pkgs.stdenv.mkDerivation rec {
          pname = "openpose";
          version = "1.7.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
            git
          ];

          buildInputs = with pkgs; [
            boost
            opencv
            protobuf
            glog
            gflags
            protobufc
          ];

          preConfigure = ''
            echo "Vendoring Caffe into 3rdparty/caffe"
            rm -rf 3rdparty/caffe
            cp -r ${caffeSrc} 3rdparty/caffe
          '';

          cmakeFlags = [
            "-DBUILD_CAFFE=ON"
            "-DUSE_CUDNN=OFF"
            "-DUSE_CUDA=OFF"
            "-DBUILD_PYTHON=OFF"
            "-DBUILD_DOCS=OFF"
            "-DBUILD_EXAMPLES=OFF"
            "-DCMAKE_INSTALL_PREFIX=$out"
          ];

          installPhase = ''
            mkdir -p $out/bin $out/lib $out/include
            cp -vr bin/* $out/bin/ || true
            cp -vr include/* $out/include/ || true
            cp -vr lib*/* $out/lib/ || true
          '';
        };

      in {
        packages.default = openpose;
      });
}