import hre, { ethers } from "hardhat";
import { BigNumber } from "ethers";

let snapshotId: string = "0x1";
export async function takeSnapshot() {
  snapshotId = await hre.ethers.provider.send("evm_snapshot", []);
}

export async function revertToSnapshot() {
  await hre.ethers.provider.send("evm_revert", [snapshotId]);
}

export const DECIMALS = 8;
export const WETH_VALUE = "221911200000"; //2219 usd
export const BTC_VALUE = "4360160000000"; //43601 usd

// Function to convert Ether to USD
export function convertToUSD(etherAmount, rateInWei, decimals) {
  const usdResult = etherAmount
    .mul(rateInWei)
    .div(BigNumber.from(10).pow(18))
    .div(BigNumber.from(10).pow(decimals));

  // Convert the result to an integer
  const formattedUSDResult = usdResult.toNumber(); // Convert to a regular JavaScript number
  const formattedEtherAmount = ethers.utils.formatUnits(etherAmount, 18);
  return `${formattedEtherAmount}  = ${formattedUSDResult} USD`;
}

export function convertUnits(val) {
  return `${ethers.utils.formatUnits(val, 18)} L-USD`;
}
