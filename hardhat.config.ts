import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv'
dotenv.config()

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    mumbai: {
      url: `${process.env.ALCHEMY_MUMBAI_URL}`,
      accounts: [`0x${process.env.MUMBAI_PRIVATE_KEY}`],
    },
    goerli: {
      url: `${process.env.EFA_GOERLI}`,
      accounts: [`0x${process.env.PK_GOERLI}`],
    },
    mantle: {
      url: "https://rpc.testnet.mantle.xyz/",
      accounts: [`0x${process.env.PK_GOERLI}`],
    }
  },
  etherscan: {
    apiKey: "T48WMCT1PV5C1NVB5K3UWVEXBDCI4FNS3H",
  }
};

export default config;