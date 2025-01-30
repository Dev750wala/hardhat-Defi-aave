import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy"
// import "@nomicfoundation/hardhat-verify"
// import "@nomiclabs/hardhat-etherscan"
// import "@nomicfoundation/hardhat-ethers"
import * as dotenv from "dotenv"
dotenv.config()

// Importing both etherscan and hardhat verify can conflict dependencies. Can throw errors. HH209


const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || "";
console.log(MAINNET_RPC_URL);

const SPEOLIA_RPC_URL = process.env.SPEOLIA_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";


const config: HardhatUserConfig = {
  solidity: "0.8.28",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      forking: {
        url: MAINNET_RPC_URL
      }
    },
    sepolia: {
      url: SPEOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
        
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  },
  namedAccounts: {
    deployer: {
      default: 0
    },
  }
};

export default config;
