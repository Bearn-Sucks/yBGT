#!/bin/sh

# this script temporarily makes a copy of hardhat.config.ts then run hardhat compile to generate the types
# hardhat.config.ts is not normally present in the repo as it can interfere with plugins and formatters

export FOUNDRY_PROFILE=hardhat

cp hardhat.config.ts.template hardhat.config.ts
npx hardhat compile
rm hardhat.config.ts