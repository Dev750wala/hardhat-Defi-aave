import { ethers } from "hardhat";
import { getNamedAccounts } from "hardhat";

export async function getWeth() {
    const { deployer } = await getNamedAccounts();
    const signer = await ethers.getSigner(deployer)

    const weth = await ethers.getContractAt(
        "IWeth",
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        signer
    )
    
    const tx = await weth.deposit({ value: ethers.parseEther("0.01") })
    await tx.wait()
    const wethBalance = await ethers.provider.getBalance(deployer)

    console.log(`WETH balance: ${ethers.formatEther(wethBalance)}`)
}