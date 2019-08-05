# Dockerfile written by Vincent Landau
# Built upon jamesnetherton's atom Dockerfile (here: 
# https://hub.docker.com/r/jamesnetherton/docker-atom-editor/dockerfile) 

FROM ubuntu:18.04

ENV ATOM_VERSION v1.36.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      fakeroot \
      gconf2 \
      gconf-service \
      git \
      gvfs-bin \
      libasound2 \
      libcap2 \
      libgconf-2-4 \
      libgcrypt20 \
      libgtk2.0-0 \
      libgtk-3-0 \
      libnotify4 \
      libnss3 \
      libx11-xcb1 \
      libxkbfile1 \
      libxss1 \
      libxtst6 \
      libgl1-mesa-glx \
      libgl1-mesa-dri \
      python \
      xdg-utils --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -L https://github.com/atom/atom/releases/download/${ATOM_VERSION}/atom-amd64.deb > /tmp/atom.deb && \
    dpkg -i /tmp/atom.deb && \
    rm -f /tmp/atom.deb

# Install julia
RUN curl -L https://julialang-s3.julialang.org/bin/linux/x64/1.3/julia-1.3.0-alpha-linux-x86_64.tar.gz > /tmp/julia.tar.gz
RUN tar -zxvf /tmp/julia.tar.gz
RUN ln -s /julia-1.3.0-alpha/bin/julia /usr/bin/julia

RUN apm install uber-juno

# Install julia packages so they don't need to be 
# install from stratch when Julia is started in Atom
RUN julia -e 'using Pkg; Pkg.add(["Juno","Atom","BinaryProvider","DocSeeker", \
"JuliaInterpreter","JSON","Compat","DataStructures","Reexport","LNR", \
"OrderedCollections","Widgets","Observables","URIParser","IniFile","Lazy", \
"Colors","ColorTypes", "Media","AssetRegistry","CodeTools","CodeTracking", \
"IterTools","Tokenize","Distances","Hiccup","StringDistances","HTTP", \
"TreeViews","MbedTLS","Traceur","WebIO","FixedPointNumbers","Requires", \
"Pidfile"])'

# Install Circuitscape and dependencies

RUN apt-get update && apt-get install -y zlib1g-dev
RUN julia -e 'using Pkg; Pkg.add(["Circuitscape", "BenchmarkTools"])'

CMD ["/usr/bin/atom","-f"]