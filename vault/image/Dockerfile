FROM bitnami/kubectl:latest

USER root

RUN install_packages python3 python3-venv

RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install kubernetes requests httpx

ENV PATH="/opt/venv/bin:$PATH"
