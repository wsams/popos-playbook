#!/bin/bash

sudo helm upgrade vault . --install -n vault -f sandbox.yaml $@
