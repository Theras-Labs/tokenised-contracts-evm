import { ethers, upgrades } from "hardhat";
const OFFCHAIN_SIGNER = "0xCfcD5729B5FC530a62b78C32cAcD4F7F84F744E3";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(deployer.address, "deploy address");

  // FACTORIES
  const TherasShop__factory = await ethers.getContractFactory("TherasShop");

  // DEPLOY TherasShop with UUPS Proxy
  const TherasShop = await upgrades.deployProxy(
    TherasShop__factory,
    [deployer.address, 0, OFFCHAIN_SIGNER],
    {
      kind: "uups",
      // initializer: "initialize",
    }
  );

  // Ensure the deployment is complete
  await TherasShop.deployed();
  // Ensure the deployment is complete
  const txReceipt = await TherasShop.deployTransaction.wait();

  console.log("TherasShop proxy address: ", TherasShop.address, txReceipt);

  // To confirm the implementation contract address
  const TherasShopImplAddress = await upgrades.erc1967.getImplementationAddress(
    TherasShop.address
  );
  console.log(`TherasShop Implementation: ${TherasShopImplAddress}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

//manual deploy
// const MyContract = await ethers.getContractFactory('MyContract');
//   const ERC1967Proxy = await ethers.getContractFactory('ERC1967Proxy');

//   const impl = await MyContract.deploy();
//   await impl.waitForDeployment();
//   const proxy = await ERC1967Proxy.deploy(
//     await impl.getAddress(),
//     MyContract.interface.encodeFunctionData('initialize', ['Add your initializer arguments here']),
//   );
//   await proxy.waitForDeployment();
