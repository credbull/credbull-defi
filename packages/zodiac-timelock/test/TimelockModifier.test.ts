import { expect } from "chai"
import { ethers, network } from "hardhat"
import type { providers } from "ethers"
import {
  computeTargetAddress,
  deployAndSetUpCustomModule,
  deployMastercopy,
  deployModuleFactory,
} from "@gnosis.pm/zodiac"
// eslint-disable-next-line camelcase
import { Button, MockAvatar, ButtonPushModule__factory, TimelockModifier } from "../typechain-types"

const warpTo = async (time: number) => {
  const block = await network.provider.send("eth_getBlockByNumber", ["latest", false])
  const timestamp = parseInt(block.timestamp) + time
  await network.provider.send("evm_setNextBlockTimestamp", [timestamp])
}

const signer = async () => {
  const [deployer] = await ethers.getSigners()
  const signer = ethers.provider.getSigner(deployer.address)
  return { address: deployer.address, jsonRpxSigner: signer }
}

const setupMaserCopy = async (signer: providers.JsonRpcSigner) => {
  const contract = await ethers.getContractFactory("ButtonPushModule")

  const args = ["0x0000000000000000000000000000000000000001", "0x0000000000000000000000000000000000000001"]
  const salt = "0x0000000000000000000000000000000000000000000000000000000000000000"

  let address = await deployMastercopy(signer, contract, args, salt)

  if (address === ethers.constants.AddressZero) {
    const target = await computeTargetAddress(signer, contract, args, salt)
    address = target.address
  }

  return { masterCopyAddress: address }
}

const setupMockAvatar = async (signer: providers.JsonRpcSigner) => {
  const contract = await ethers.getContractFactory("MockAvatar")
  const avatar = await contract.connect(signer).deploy()
  return { avatar }
}

const setupButton = async (signer: providers.JsonRpcSigner, avatar: MockAvatar) => {
  const contract = await ethers.getContractFactory("Button")
  const button = await contract.connect(signer).deploy()

  const owner = await button.owner()

  if (owner !== avatar.address) {
    const tx = await button.transferOwnership(avatar.address)
    await tx.wait()
  }

  return { button }
}

const setupTimelock = async (signer: providers.JsonRpcSigner, avatar: MockAvatar) => {
  const cooldown = 180
  const expiration = 180 * 1000

  const Timelock = await ethers.getContractFactory("TimelockModifier")
  const timelock = await Timelock.connect(signer).deploy(
    avatar.address,
    avatar.address,
    avatar.address,
    cooldown,
    expiration,
  )

  return { timelock }
}

const setupModule = async (
  signer: providers.JsonRpcSigner,
  masterCopyAddress: string,
  avatar: MockAvatar,
  timelock: TimelockModifier,
  button: Button,
) => {
  await deployModuleFactory(signer)

  // eslint-disable-next-line camelcase
  const abi = ButtonPushModule__factory.abi
  const args = { values: [timelock.address, button.address], types: ["address", "address"] }
  const chainId = 31337
  const salt = Date.now().toString()

  const { transaction: deploy } = deployAndSetUpCustomModule(
    masterCopyAddress,
    abi,
    args,
    ethers.provider,
    chainId,
    salt,
  )

  const transaction = await signer.sendTransaction(deploy)
  const receipt = await transaction.wait()

  const proxyAddress = receipt.logs[1].address
  const module = await ethers.getContractAt("ButtonPushModule", proxyAddress, signer)

  const currentActiveModule = await avatar.module()
  if (currentActiveModule !== timelock.address) {
    const tx = await avatar.enableModule(timelock.address)
    await tx.wait()

    const enableModule = await timelock.populateTransaction.enableModule(module.address)
    await avatar.exec(timelock.address, 0, enableModule.data!)
  }

  return { module }
}

const setup = async () => {
  const { jsonRpxSigner, address } = await signer()
  const { masterCopyAddress } = await setupMaserCopy(jsonRpxSigner)
  const { avatar } = await setupMockAvatar(jsonRpxSigner)
  const { button } = await setupButton(jsonRpxSigner, avatar)
  const { timelock } = await setupTimelock(jsonRpxSigner, avatar)
  const { module } = await setupModule(jsonRpxSigner, masterCopyAddress, avatar, timelock, button)

  return { avatar, button, module, timelock, deployerAddress: address }
}

describe("TimelockModifier", function () {
  it("throws if cool down has not passed", async () => {
    const { module, timelock, button } = await setup()

    // start with 0 pushes
    expect(await button.pushes()).to.equal(0)

    // pushes but the transaction is not executed, only queued
    const pushButton = await module.pushButton()
    expect(await button.pushes()).to.equal(0)

    // try to execute the transaction before the cool down has passed
    const executed = timelock.executeNextTx(button.address, 0, pushButton.data!, 0)
    await expect(executed).to.be.revertedWith("Transaction is still in cooldown")
  })

  it("executes a button push whenever the cooldown has finished", async () => {
    const { module, timelock, button } = await setup()

    // start with 0 pushes
    expect(await button.pushes()).to.equal(0)

    // pushes but the transaction is not executed, only queued
    const pushButton = await module.pushButton()
    expect(await button.pushes()).to.equal(0)

    await warpTo(180)

    // now the transaction is executed and the button is pushed
    await timelock.executeNextTx(button.address, 0, pushButton.data!, 0)
    expect(await button.pushes()).to.equal(1)
  })
})
