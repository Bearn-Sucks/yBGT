import { HardhatUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";

// Hardhat is only used to generate Typescript typings in this repo

const config: HardhatUserConfig = {
  solidity: "0.8.27",

  paths: {
    sources: "src/interfaces", // only need the interfaces
  },
};

export default config;
