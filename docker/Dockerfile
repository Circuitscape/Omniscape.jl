FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl

# Install julia
RUN curl -L https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.0-linux-x86_64.tar.gz > /tmp/julia.tar.gz
RUN tar -zxvf /tmp/julia.tar.gz
RUN ln -s /julia-1.10.0/bin/julia /usr/bin/julia

# Install Omniscape
RUN julia -e 'using Pkg; Pkg.add(["Omniscape", "Test", "BenchmarkTools"])'

CMD ["/usr/bin/julia"]
