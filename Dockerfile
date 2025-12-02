# -------- Stage 1: Build --------
FROM postgres:16 AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-server-dev-16 \
    curl \
    pkg-config \
    cmake \
    git \
    ca-certificates \
    libreadline6-dev \
    zlib1g-dev

# Устанавливаем Rust
ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:$PATH
# RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal --default-toolchain stable
USER root
#start this need coz curl rust install command not work in my region
COPY rustup-init.sh /rustup-init.sh
RUN chmod +x /rustup-init.sh
RUN \
  /rustup-init.sh -y --no-modify-path --profile minimal --default-toolchain stable
#end this need coz curl rust install command not work in my region

# Копируем ваш код и билдим расширение
WORKDIR /home/supa
COPY . .
RUN cargo install cargo-pgrx --version 0.16.1 --locked
RUN cargo pgrx init --pg16 $(which pg_config)
RUN cargo pgrx install

# -------- Stage 2: Final Image --------
FROM postgres:16

# Копируем только готовое расширение и нужные файлы
COPY --from=builder /usr/lib/postgresql/16/lib /usr/lib/postgresql/16/lib
COPY --from=builder /usr/share/postgresql/16/extension /usr/share/postgresql/16/extension

# Если нужно, копируем конфиги или дополнительные файлы
COPY --from=builder /home/supa /home/supa

# Назначаем владельца
RUN chown -R postgres:postgres /home/supa /usr/share/postgresql/16/extension /usr/lib/postgresql/16/lib

USER postgres
