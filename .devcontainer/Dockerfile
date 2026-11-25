#syntax=docker/dockerfile:1

# Toolchain versions
ARG PYTHON_VERSION="1-3.10"
ARG DEBIAN_VARIANT="bookworm"
ARG UV_VERSION="0.13"

# uv image (copied from below)
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

# Base image
FROM mcr.microsoft.com/devcontainers/python:${PYTHON_VERSION}-${DEBIAN_VARIANT}

# Create user
ARG USERNAME=shard
ARG USER_UID=1001
ARG USER_GID=${USER_UID}
RUN \
    groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Install uv from the official image
COPY --from=uv /uv /uvx /usr/local/bin/

# Set cache and environment
ENV UV_CACHE_DIR=/uv
ENV UV_PROJECT_ENVIRONMENT=/opt/venv
ENV UV_LINK_MODE=copy
RUN \
    mkdir -p ${UV_CACHE_DIR} ${UV_PROJECT_ENVIRONMENT} && \
    chown -R ${USERNAME}:${USERNAME} ${UV_CACHE_DIR} ${UV_PROJECT_ENVIRONMENT}

# Set user and working directory
USER $USERNAME
WORKDIR /src
