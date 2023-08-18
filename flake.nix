{
  description = "Example flake template consuming talo flakes";
  inputs = {
    # Change to this after flake init, or when using the flake in practice
    talo.url = "github:talo/talo_flake";
    # nixpkgs.url = "github:talo/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    talo,
  }: let
    # Reproducible, pinned import of the NixOS-QChem overlay function.
    qchemOvl = import (builtins.fetchGit {
      url = "https://github.com/markuskowa/NixOS-QChem.git";
      name = "NixOS-QChem";
      rev = "1b5dea569ca1e5fb064182935348846885ef957c";  # latest rev as of 8 Feb 2023, 2 pm GMT+8
    });
    inherit (talo.inputs) nixpkgs;
    inherit (talo.inputs) utils;
    out = system: let
        pkgs = import nixpkgs {
            overlays = [qchemOvl];
            config = {
                allowUnfree = true;
            };
            inherit system;
        };
        mstore = pkgs.stdenv.mkDerivation rec {
            pname = "mstore";
            version = "0.0.1";
            src = fetchTarball {
                url = "https://github.com/grimme-lab/mstore/archive/refs/heads/main.tar.gz";
                sha256 = "sha256:01vi0an6ndddggra6q8b5l37gnkk6jk289bccdmz85fp7agjsgbw";
            };
            nativeBuildInputs = [
                pkgs.cmake
                pkgs.gfortran
                pkgs.ninja
                pkgs.qchem.mctc-lib
            ];
        };
        test-drive = pkgs.stdenv.mkDerivation rec {
            pname = "test-drive";
            version = "0.4.0";
            src = fetchTarball {
                url = "https://github.com/fortran-lang/test-drive/archive/refs/tags/v0.4.0.tar.gz";
                sha256 = "sha256:1prkqpbnbwhwq51s13rra02mg8i7hx6libvgq9qnc3iibpni4d10";
            };
            nativeBuildInputs = [
                pkgs.cmake
                pkgs.gfortran
                pkgs.ninja
            ];
        };
        toml-f = pkgs.stdenv.mkDerivation rec {
            pname = "toml-f";
            version = "0.3.1";
            src = fetchTarball {
                url = "https://github.com/toml-f/toml-f/archive/refs/tags/v0.3.1.zip";
                sha256 = "sha256:07v6wgj3c0wjgw5z1ab80nvx1hk2k1yidqnclnymnvsl1dp5qqz8";
            };
            nativeBuildInputs = [
                pkgs.cmake
                pkgs.gfortran
                pkgs.ninja
                test-drive
            ];
        };
        multicharge = pkgs.stdenv.mkDerivation rec {
            pname = "multicharge";
            version = "0.2.0";
            src = fetchTarball {
                url = "https://github.com/grimme-lab/multicharge/archive/refs/tags/v0.2.0.tar.gz";
                sha256 = "sha256:0paydb5jkyy1pg2l37j5kmgpsh95wm4gnw5x0lcl2xy6kz3kjhm1";
            };
            nativeBuildInputs = [
                pkgs.cmake
                pkgs.blas
                pkgs.lapack
                pkgs.gfortran
                pkgs.ninja
                pkgs.qchem.mctc-lib
                mstore
            ];
        };
        dftd4 = pkgs.stdenv.mkDerivation rec {
            pname = "dftd4";
            version = "3.5.0";
            src = fetchTarball {
                url = "https://github.com/dftd4/dftd4/archive/refs/tags/v3.5.0.tar.gz";
                sha256 = "sha256:14lrcdg6qzyq1cyibcqzg94cfjiys41jnv5fjvn3wh6d6ip0aak4";
            };
            nativeBuildInputs = [
                pkgs.cmake
                pkgs.gfortran
                pkgs.ninja
                pkgs.blas
                pkgs.lapack
                pkgs.qchem.mctc-lib
                mstore
                test-drive
                multicharge
            ];
        };
        s-dftd3 = pkgs.stdenv.mkDerivation rec {
            pname = "s-dftd3";
            version = "0.7.0";
            src = fetchTarball {
                url = "https://github.com/dftd3/simple-dftd3/archive/refs/tags/v0.7.0.tar.gz";
                sha256 = "sha256:1018pw6ylbpkjy0ingsq3qm1f4gjaf1w6bkr53iyiwn310rfdsz4";
            };
            nativeBuildInputs = [
                pkgs.cmake
                pkgs.gfortran
                pkgs.ninja
                pkgs.qchem.mctc-lib
                pkgs.blas
                pkgs.lapack
                mstore
                multicharge
                toml-f
            ];
        };
    in
      talo.lib.mkTalo rec {
        src = ./.;
        srcDir = "./src";
        pname = "YOUR_PACKAGE_NAME";
        version = "0.0.1";

        requirements = ''
        #   oddt
        #   numpydoc
        #   torch
        #   torchdata
        #   torch-cluster
        #   torch-geometric
        #   torch-scatter
        #   torch-sparse
        #   torch-spline-conv
        '';
        buildInputs = with pkgs; [
          # DD doesn't like being packaged with mach - so keep in buildinputs for now
          # some issue with meeko and phik colliding
        #   talo.packages.${system}.ddctl

        ];
        taloInputs = with talo.packages.${system}; [
        #   bohr
        #   bench
        #   features
        #   data
        #   transformercpi
        #   molsaic
        #   molqfrag
        ];
        cudaPackages = "";
        propagatedBuildInputs = taloInputs ++ [
            mstore
            toml-f
            dftd4
            multicharge
            s-dftd3
            pkgs.python3
            pkgs.cmake
            pkgs.meson
            pkgs.gfortran
            pkgs.blas
            pkgs.qchem.mctc-lib
            pkgs.lapack
            pkgs.ninja
        ];
        devInputs = with pkgs.python310Packages; [
          black
          (pkgs.dvc.override {enableGoogle = true;})
          flake8
          pydocstyle
          flake8-docstrings
          isort
          pkgs.pyright
          pytest
          pytest-cov
        ];
        pythonImportsCheck = [
        #   "molsaic"
        #   "transformercpi"
        #   "bohr"
        #   "plb_bench"
        #   "plb_features"
        #   "talo_data"
        ];
        nvidia_drivers = {
          nvidia_510_48 = {
            version = "515.48.07";
            sha256 = "sha256-4odkzFsTwy52NwUT2ur8BcKJt37gURVSRQ8aAOMa4eM=";
          };
        };
        ignoreDataOutdated = true;
        inherit self system nixpkgs;

        # # Set this value if you are using a monorepo; it must point to the subfolder in the monorepo root
        # outputName = "template";
        # # This value is only set for the template flake.nix as it behaves slightly differently
        # isTemplate = true;
      };
  in
    utils.lib.eachSystem ["x86_64-linux"] out;
}
