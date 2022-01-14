# nix-channel --add https://github.com/NixOS/nixpkgs/archive/master.tar.gz nixpkgs-master

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
      pip
      setuptools
      six
      google-api-python-client>=1.6.7
      # kaggle>=1.3.9
      numpy>=1.15.4
      oauth2client
      pandas>=0.22.0
      psutil>=5.4.3
      py-cpuinfo>=3.3.0
      scipy>=0.19.1
      sklearn
      tensorflow-hub>=0.6.0
      tensorflow-model-optimization>=0.4.1
      tensorflow-datasets
      dataclasses;python_version<"3.7"
      gin-config
      tf_slim>=1.1.0
      Cython
      matplotlib
      # Loader becomes a required positional argument in 6.0 in yaml.load
      pyyaml>=5.1,<6.0
      # CV related dependencies
      opencv-python-headless
      Pillow
      pycocotools
      # NLP related dependencies
      seqeval
      sentencepiece
      sacrebleu
    '';

  };
  libs = with mach-nix.nixpkgs; [
    cudatoolkit_11
    cudatoolkit_11.lib
    nccl_cudatoolkit_11
    cudnn_cudatoolkit_11
    stdenv.cc.cc.lib
  ];
in
mach-nix.nixpkgs.mkShell {
  buildInputs = [
    envPy
  ] ++ libs;

  shellHook = ''
    mkdir -p __pypkgs__
    alias npip="PIP_PREFIX='$(pwd)/__pypkgs__/pip_packages' TMPDIR='$HOME' pip"

    export PATH=$(pwd)/__pypkgs__/pip_packages/bin:$PATH
    export PYTHONPATH=$(pwd)/__pypkgs__/pip_packages/lib/python3.9/site-packages:$PYTHONPATH

    [ ! -f $(pwd)/__pypkgs__/stats ] && npip install kaggle
    [ ! -f $(pwd)/__pypkgs__/stats ] && npip install tfg-nightly --no-deps
    [ ! -f $(pwd)/__pypkgs__/stats ] && npip install networkx OpenEXR trimesh
    [ ! -f $(pwd)/__pypkgs__/stats ] && npip install tfa-nightly tensorflow-text-nightly tf-nightly-gpu
    [ ! -f $(pwd)/__pypkgs__/stats ] && touch $(pwd)/__pypkgs__/stats

    # python setup.py install --prefix __pypkgs__/pip_packages
    # npip install xxx

    alias run_train="python -m official.projects.volumetric_models.train"
    run_ (){
      mm=$1;
      shift;
      rr=$@;
      echo run python -m official.projects.volumetric_models."$mm" $rr;
      python -m official.projects.volumetric_models."$mm" $rr;
    }

    export LD_LIBRARY_PATH=${mach-nix.nixpkgs.cudatoolkit_11}/lib:${mach-nix.nixpkgs.lib.makeLibraryPath libs}:/usr/lib/x86_64-linux-gnu
  '';
}
