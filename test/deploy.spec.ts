import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, network, upgrades } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";
// import {
//   BTC_VALUE,
//   DECIMALS,
//   WETH_VALUE,
//   convertToUSD,
//   convertUnits,
// } from "../../tasks/helpers/utils";
// import {
//   ExPoints__factory,
//   SwapContract__factory,
// } from "../../typechain-types";
require("mocha-reporter").hook();

const OFFCHAIN_SIGNER = "0xCfcD5729B5FC530a62b78C32cAcD4F7F84F744E3";

async function deployFixture() {
  // Contracts are deployed using the first signer/account by default
  const [deployer, alice, bob, charlie] = await ethers.getSigners();

  // FACTORIES
  const TRC1155__factory = await ethers.getContractFactory("TRC1155");
  const TherasShop__factory = await ethers.getContractFactory("TRC1155");

  // DEPLOY
  const TRC1155 = await TRC1155__factory.deploy(deployer.address);
  const TherasIMPL = await TherasShop__factory.deploy(deployer.address);
  console.log(TherasIMPL, "TherasIMPL");

  //-----THERAS SHOP

  // Deploy the contract using UUPS proxy
  const initialOwner = deployer.address;
  console.log(initialOwner, "initialOwner");

  const TherasShop = await upgrades.deployProxy(
    TherasIMPL,
    [initialOwner, 0, OFFCHAIN_SIGNER],
    {
      kind: "uups",
      initializer: "initialize",
    }
  );
  console.log(TherasShop, "TherasShop");

  await TherasShop.waitForDeployment();
  //   await TherasShop.deployed();
  console.log("TherasShop deployed to:", TherasShop?.address);

  //   await TherasShop.connect(deployer).mint(
  //     alice.address,
  //     BigNumber.from("30000000000000000000") // 30 weth
  //   );

  return {
    // TherasShop,
    deployer,
    alice,
    bob,
    charlie,
  };
}

describe("Build setup", function () {
  let TherasShop: any;
  // let ledgerAbi: any;
  let deployer: Signer;
  let alice: Signer;
  let charlie: Signer;
  let bob: Signer;
  let bank: Signer;

  before(async function () {
    // Initialize the contract and other variables once before all tests
    ({ TherasShop, deployer, alice, bob, charlie } = await loadFixture(
      deployFixture
    ));
  });

  it("Should be able to see the SHOP correctly setup", async function () {
    // const res = TherasShop.connect(alice).owner();
    console.log(await TherasShop?.owner(), "result of owner");
    // await getAllBalancesExpectZero(alice, bob, charlie, ledger);
    // // MAKING DEPOSIT
    // console.log("Alice deposit 1.5k usd");
    // await expect(
    //   ledger.connect(alice).deposit(
    //     alice.address,
    //     BigNumber.from("1500000000000000000000") // 1.5k usd
    //   )
    // ).to.not.be.reverted;
    // console.log("Bob deposit 33k usd");
    // await expect(
    //   ledger.connect(bob).deposit(
    //     bob.address,
    //     BigNumber.from("33000000000000000000000") // 33k usd
    //   )
    // ).to.not.be.reverted;
    // console.log("Charlie deposit 5k usd");
    // await expect(
    //   ledger.connect(charlie).deposit(
    //     charlie.address,
    //     BigNumber.from("5000000000000000000000") // 5k usd
    //   )
    // ).to.not.be.reverted;
  });
});

// $ hardhat compile
// Compiling contracts for zkSync Era with zksolc v1.4.1 and solc v0.8.17
// Compiling 59 Solidity files
