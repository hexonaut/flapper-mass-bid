#!/usr/bin/env bash
set -e

if [[ -z "$1" ]]; then
  forge test --rpc-url="$ETH_RPC_URL" --optimize --force
else
  forge test --rpc-url="$ETH_RPC_URL" --optimize --force --match "$1" -vvvv
fi
