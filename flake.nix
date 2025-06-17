{
  description = "Flake to build OpenPose from source (CPU-only)";

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

        openpose = pkgs.stdenv.mkDerivation rec {
          pname = "openpose";
          version = "1.7.0";

          src = pkgs.fetchFromGitHub {
            owner = "CMU-Perceptual-Computing-Lab";
            repo = "openpose";
            rev = "e8cb03fa27699187169f9fa84bb6c7c9b8b9270e"; # Stable CPU-only commit
            sha256 = "sha256-Pv1+e9bnF6IV9glxvZGWKhO9YSeDP0NSeJGiDW9us+Y=";
          };

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
            cudaPackages.cudnn # REMOVE this line if you're not compiling CUDA at all
          ];

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
