# -----------------------------------------------------------------------------
# OpenSCAD CLI runtime image
# -----------------------------------------------------------------------------
# Build:  docker build -t openscad-cli .
# Run:    docker run --rm -v "$PWD:/work" -w /work openscad-cli --version
# Run (PNG): docker run --rm -v "$PWD:/work" -w /work --entrypoint xvfb-run openscad-cli -a openscad -o preview.png --imgsize=1280,960 model.scad
# -----------------------------------------------------------------------------

FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Install OpenSCAD and lightweight runtime deps
# xvfb is only needed for PNG export on older OpenSCAD (<2024);
# modern OpenSCAD renders PNG headlessly via EGL on Linux.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openscad \
        openscad-mcad \
        xvfb \
        && rm -rf /var/lib/apt/lists/*

# Verify installation
RUN openscad --version

# Create a non-root user for safer container execution
RUN groupadd -r openscad && useradd -r -g openscad -d /work -s /bin/false openscad

WORKDIR /work
USER openscad

ENTRYPOINT ["openscad"]
CMD ["--help"]