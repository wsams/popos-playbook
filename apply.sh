#!/bin/bash

# e.g. ./apply.sh --tags install_kubernetes

ansible-playbook site.yml --ask-become-pass $@
