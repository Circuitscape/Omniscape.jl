# Track the latest stable Julia 1.x release rather than a pinned tarball.
FROM julia:1

# Install Omniscape
RUN julia -e 'using Pkg; Pkg.add(["Omniscape", "Test", "BenchmarkTools"])'

CMD ["julia"]
