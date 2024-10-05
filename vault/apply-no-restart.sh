#!/bin/bash

sudo helm upgrade vault . --install -n vault --set vault.server.ha.enabled=true,vault.server.ha.replicas=5,vault.server.ha.raft.enabled=true,vault.server.ha.raft.setNodeId=true,vault.injector.enabled=false,job.enabled=false $@
