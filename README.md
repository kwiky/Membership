# Membership

This project is a study case to learn Solidity, OpenZeppelin, Hardhat and other ethereum developer stuff.

## Documentation

Membership mint you a Subscription NFT which is available as long as you have a valid subscription.

The greater the amount of token is when you subscribe, the longer the Subscription NFT will be available.

Example :
```typescript
  // Deploy Membership contract with one authorized token, and for 2 tokens per second
  Membership.deploy(subscriptionNft.address, [testToken.address], [2]);

  // Approve 10 tokens
  await testToken.approve(membership.address, 10);
  // Subscribe with this amount, so for 5 seconds
  await membership.subscribe(testToken.address);

  // Return 1 token if called in the 5 seconds, but 0 after those 5 seconds
  subscriptionNft.balanceOf("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266");
```

## Inspirations

- [Unlock Protocol](https://docs.unlock-protocol.com/) ([Gihtub](https://github.com/unlock-protocol/unlock))
- [The Bakery NFT](https://bakery.fyi/bakery-nft/) ([Contract on Rinkeby](https://rinkeby.etherscan.io/token/0x2c555f07b5994d5c47a6690563952fff44267e0f#readContract)) ([Contract on Mainnet](https://etherscan.io/address/0x740af0742ead695dc26a159f8a4dac331b7b3d1e))
