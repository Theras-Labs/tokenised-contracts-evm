import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
// require('@nomiclabs/hardhat-ethers');
// require('@openzeppelin/hardhat-upgrades');
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          evmVersion: "paris",
        },
      },
    ],
  },
  networks: {
    bttc: {
      chainId: 1029,
      url: "https://pre-rpc.bt.io/",
      accounts:
        process.env.ACCOUNT_KEY !== undefined ? [process.env.ACCOUNT_KEY] : [],
      // 1001
    },
  },
};

export default config;
