import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";
import type { MintableERC20 } from "../typechain/MintableERC20";
import type { SubscriptionNft } from "../typechain/SubscriptionNft";
import type { Membership } from "../typechain/Membership";

describe("Membership", function () {

  let signers: Signer[];
  let owner: Signer;
  let user2: Signer;
  let myAddress: string;

  let testToken: MintableERC20;
  let subscriptionNft: SubscriptionNft;
  let membership: Membership;

  beforeEach(async function () {
    signers = await ethers.getSigners();
    [owner, user2] = signers;
    myAddress = await owner.getAddress();

    const MintableERC20 = await ethers.getContractFactory("MintableERC20");
    testToken = await MintableERC20.deploy("Test", "TST", 2);
    await testToken.deployed();
    await testToken.mint(100);

    const SubscriptionNft = await ethers.getContractFactory("SubscriptionNft");
    subscriptionNft = await SubscriptionNft.deploy("Subscription", "SUB");

    const Membership = await ethers.getContractFactory("Membership");
    // Test with a membership which cost 2 tokens per seconds
    membership = await Membership.deploy(subscriptionNft.address, [testToken.address], [2]);

    await subscriptionNft.setMinter(membership.address);
  });

  it("Should use MintableERC20", async function () {
    expect(await testToken.balanceOf(myAddress)).to.equal(100);
  });

  it("Should use SubscriptionNft", async function () {
    await subscriptionNft.setMinter(myAddress);
    
    expect(await subscriptionNft.balanceOf(myAddress)).to.equal(0);
    // Mint a subscription NFT for 5 seconds
    await subscriptionNft.mint(myAddress, 10);
    expect(await subscriptionNft.balanceOf(myAddress)).to.equal(1);
    await subscriptionNft.burn(0);
    expect(await subscriptionNft.balanceOf(myAddress)).to.equal(0);

    await subscriptionNft.setMinter(membership.address);
  });

  it("Should revert mint NFT because of access control", async function () {
    await expect(subscriptionNft.mint(myAddress, 10)).to.be.reverted;
  });

  it("Should revert subscription because of not authorized token", async function () {
    const MintableERC20 = await ethers.getContractFactory("MintableERC20");
    const unavailableToken = await MintableERC20.deploy("Unavailable Token", "UN", 2);
    await unavailableToken.deployed();
    await unavailableToken.mint(100);

    await unavailableToken.approve(membership.address, 10);
    await expect(membership.subscribe(unavailableToken.address)).to.be.revertedWith("Membership: This token is not authorized for subscription");
  });

  it("Should revert subscription because of not enought tokens", async function () {
    await testToken.approve(membership.address, 1);
    await expect(membership.subscribe(testToken.address)).to.be.revertedWith("Membership: Not enought of this token to subscribe");

    expect(await testToken.balanceOf(myAddress)).to.equal(100);
    expect(await subscriptionNft.balanceOf(myAddress)).to.equal(0);
  });

  it("Should mint NFT", async function () {
    await testToken.approve(membership.address, 10);
    await membership.subscribe(testToken.address);

    expect(await testToken.balanceOf(myAddress)).to.equal(90);
    expect(await subscriptionNft.balanceOf(myAddress)).to.equal(1);
    expect(await subscriptionNft.endSubscriptionTimestampOf(myAddress)).to.above(0);
  });

  it("Should revert subscription because already subscribed", async function () {
    await testToken.approve(membership.address, 10);
    await membership.subscribe(testToken.address);

    expect(await testToken.balanceOf(myAddress)).to.equal(90);
    expect(await subscriptionNft.balanceOf(myAddress)).to.equal(1);

    // User resubscribe with 20 more tokens
    await testToken.approve(membership.address, 10);
    await expect(membership.subscribe(testToken.address)).to.be.revertedWith("Membership: This address already have a subscription");

    expect(await testToken.balanceOf(myAddress)).to.equal(90);
    expect(await subscriptionNft.balanceOf(myAddress)).to.equal(1);
  });
});
