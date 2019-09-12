#!/usr/bin/env bash

ssh -i identity.pem ubuntu@$(cat ip_address.txt)