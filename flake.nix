{
  description = "MQTT WizualiZing Rust Dashboard";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    unstable-nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ]
    (system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays =
            let
              selfOverlay = _: _: { } // inputs.self.packages."${system}";
            in
            [
              selfOverlay
              (import inputs.rust-overlay)
            ];
        };

        nightlyRustTarget = pkgs.rust-bin.selectLatestNightlyWith (toolchain:
          pkgs.rust-bin.fromRustupToolchain { channel = "nightly-2024-02-07"; components = [ "rustfmt" ]; });

        nightlyCraneLib = (inputs.crane.mkLib pkgs).overrideToolchain nightlyRustTarget;

        rustTarget = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rustTarget;

        tomlInfo = craneLib.crateNameFromCargoToml { cargoToml = ./Cargo.toml; };

        inherit (tomlInfo) version;

        pname = "mqttwzrd";

        src =
          let
            nixFilter = path: _type: !pkgs.lib.hasSuffix ".nix" path;
            extraFiles = path: _type: !(builtins.any (n: pkgs.lib.hasSuffix n path) [ ".github" ".sh" ]);
            filterPath = path: type: builtins.all (f: f path type) [
              nixFilter
              extraFiles
              pkgs.lib.cleanSourceFilter
            ];
          in
          pkgs.lib.cleanSourceWith {
            src = ./.;
            filter = filterPath;
          };

        buildInputs = [
          pkgs.pkg-config
          pkgs.openssl
          pkgs.cmake
        ];

        cargoArtifacts = craneLib.buildDepsOnly {
          inherit
            src
            pname
            buildInputs
            ;
        };

        mqttwzrd = craneLib.buildPackage {
          inherit cargoArtifacts src pname version
           buildInputs;
        };

        rustfmt' = pkgs.writeShellScriptBin "rustfmt" ''
          exec "${nightlyRustTarget}/bin/rustfmt" "$@"
        '';
      in
      rec {
        checks = {
          inherit mqttwzrd;

          mqttwzrd-clippy = craneLib.cargoClippy {
            inherit cargoArtifacts src pname buildInputs;

            cargoClippyExtraArgs = "--all-features -- --deny warnings";
          };

          mqttwzrd-fmt = nightlyCraneLib.cargoFmt {
            inherit src pname;
          };
        };

        packages = {
          default = packages.mqttwzrd;
          inherit
            mqttwzrd
            ;
        };

        devShells.default = devShells.mqttwzrd;
        devShells.mqttwzrd = pkgs.mkShell {
          inherit buildInputs;

          nativeBuildInputs = [
            rustfmt'
            rustTarget

            pkgs.gitlint
          ];
        };
      }
    );
}
