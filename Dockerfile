FROM postgres:16
RUN apt-get update

ENV build_deps ca-certificates \
  git \
  build-essential \
  libpq-dev \
  postgresql-server-dev-16 \
  curl \
  libreadline6-dev \
  zlib1g-dev


RUN apt-get install -y --no-install-recommends $build_deps pkg-config cmake

WORKDIR /home/supa

ENV HOME=/home/supa \
  PATH=/home/supa/.cargo/bin:$PATH
RUN chown postgres:postgres /home/supa
USER postgres

USER root
#start this need coz curl rust install command not work in my region
COPY rustup-init.sh /rustup-init.sh
RUN chmod +x /rustup-init.sh
RUN \
  /rustup-init.sh -y --no-modify-path --profile minimal --default-toolchain stable
#end this need coz curl rust install command not work in my region

USER root

RUN cargo install cargo-pgrx --version 0.16.1 --locked

RUN cargo pgrx init --pg16 $(which pg_config)

USER root

COPY . .
RUN cargo pgrx install

RUN chown -R postgres:postgres /home/supa
RUN chown -R postgres:postgres /usr/share/postgresql/16/extension
RUN chown -R postgres:postgres /usr/lib/postgresql/16/lib

USER postgres