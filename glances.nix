let
  mach-nix = import
    (builtins.fetchGit {
      url = "https://github.com/DavHau/mach-nix";
      ref = "master";
    })
    {
      pkgs = import <nixpkgs-master> {
       allowUnfree = true;
       cudaSupport = true;
      };

      # optionally specify the python version
      python = "python39";

      pypiData = builtins.fetchTarball "https://github.com/DavHau/pypi-deps-db/tarball/master";
    };
  envPy = mach-nix.mkPython {
    requirements = ''
      glances

      bottle
      netifaces
      py3nvml
      pySMART
      pymdstat
      requests
    '';
  };
in
mach-nix.nixpkgs.mkShell {
  buildInputs = [ envPy ];
  shellHook = ''
    export LD_LIBRARY_PATH=${mach-nix.nixpkgs.cudatoolkit_11}/lib:${mach-nix.nixpkgs.cudatoolkit_11.lib}/lib:/usr/lib/x86_64-linux-gnu

    glances -w
  '';
}
