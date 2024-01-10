import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import _ from "lodash";
import { CommunityToken, RewardVault, StakingVault } from "../typechain-types";

describe("RewardVault", function () {
  type Participant = { account: string; balance: bigint };

  async function deployFixture() {
    const [owner, john, alice] = await ethers.getSigners();

    const CommunityToken = await ethers.getContractFactory("CommunityToken");
    const communityToken = await CommunityToken.deploy(1000);

    const StakingVault = await ethers.getContractFactory("StakingVault");
    const stakingVault = await StakingVault.deploy(communityToken);

    const RewardVault = await ethers.getContractFactory("RewardVault");
    const rewardVault = await RewardVault.deploy(communityToken);

    return { rewardVault, communityToken, stakingVault, owner, john, alice };
  }

  async function getRankedParticipants(stakingVault: StakingVault) {
    const transfers = await stakingVault.queryFilter(
      stakingVault.filters.Transfer(),
    );

    const accounts = _.chain(transfers)
      .flatMap((transfer) => transfer.args)
      .filter((arg) => typeof arg === "string")
      .uniq()
      .value() as string[];

    const balances = await Promise.all(
      accounts.map(async (account) => {
        return { account, balance: await stakingVault.balanceOf(account) };
      }),
    );

    return _.chain(balances).sortBy("balance").reverse().chunk(1).value();
  }

  async function distributeRewards(
    rewardVault: RewardVault,
    communityToken: CommunityToken,
    tier: Participant[],
    buyBackYield: number,
    percentage: number,
  ) {
    const tierReward =
      (BigInt(buyBackYield) * BigInt(percentage)) / BigInt(100);
    const tierRewards = tier.map(() => tierReward / BigInt(tier.length));

    await communityToken.approve(await rewardVault.getAddress(), tierReward);
    await rewardVault.distribute(
      tierRewards,
      tier.map((t) => t.account),
    );
  }

  describe("reward distribution", function () {
    it("Should distribute funds to ranked participants according to their tier", async function () {
      const { communityToken, rewardVault, stakingVault, john, alice } =
        await loadFixture(deployFixture);

      await communityToken.transfer(john.address, 100);
      expect(await communityToken.balanceOf(john)).to.equal(100);

      // John stakes 100
      await communityToken
        .connect(john)
        .approve(await stakingVault.getAddress(), 100);
      await stakingVault.connect(john).deposit(100, john);

      // John sends 100 xShares to Alice
      await stakingVault.connect(john).transfer(alice.address, 100);

      // The tiers are calculate with Alice with 100 xShares, John with 0 xShares and Alice as the only holder (100%)
      const [tier1, tier2, tier3] = await getRankedParticipants(stakingVault);
      const [percentage1, percentage2, percentage3] = [100, 0, 0];

      // The yield from buying the stock back
      const buyBackYield = 100;

      // Alice gets Tier 1 rewards (in this example 100%)
      await distributeRewards(
        rewardVault,
        communityToken,
        tier1,
        buyBackYield,
        percentage1,
      );

      // Other participants are in the Tier 2 and Tier 3 (in this example 0%)
      await distributeRewards(
        rewardVault,
        communityToken,
        tier2,
        buyBackYield,
        percentage2,
      );
      await distributeRewards(
        rewardVault,
        communityToken,
        tier3,
        buyBackYield,
        percentage3,
      );

      // The reward vault has 300 community tokens and 300 reward shares ot distribute
      expect(await communityToken.balanceOf(rewardVault)).to.equal(100);
      expect(await rewardVault.balanceOf(rewardVault)).to.equal(100);

      // Alice and John claim their community tokens
      await rewardVault.connect(alice).claim();
      await rewardVault.connect(john).claim();

      // Alice has 300 community tokens and John has 0 community tokens and the reward vault has 0 community tokens
      expect(await communityToken.balanceOf(alice)).to.equal(100);
      expect(await communityToken.balanceOf(rewardVault)).to.equal(0);
      expect(await communityToken.balanceOf(john)).to.equal(0);

      // Alice still has 100 xShares that would be worth 100 community tokens
      expect(await stakingVault.balanceOf(alice)).to.equal(100);
    });
  });
});
