import { ethers } from "hardhat";
import { getNamedAccounts } from "hardhat";
import { IWeth } from "../typechain-types";


export async function getWeth() {
    const { deployer } = await getNamedAccounts();
    const signer = await ethers.getSigner(deployer)

    const weth = await ethers.getContractAt(
        "IWeth",
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        signer
    ) as unknown as IWeth
    
    const tx = await weth.deposit({ value: ethers.parseEther("0.01") })
    await tx.wait()
    const wethBalance = await weth.balanceOf(deployer)

    console.log(`WETH balance: ${ethers.formatEther(wethBalance)}`)
}