// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

/**
 * @title SubscriptionNft
 */
contract SubscriptionNft is ERC721, Ownable, AccessControl {

  using SafeMath for uint256;
  
  bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");
  mapping(address => uint256) public _endSubscriptionTimestamps;

  uint256 _tokenId = 0;
  
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
  }

  /**
    * @dev See {IERC721-balanceOf}.
    */
  function balanceOf(address owner) public view virtual override returns (uint256) {
      uint256 balance = super.balanceOf(owner);
      if (_endSubscriptionTimestamps[owner] > block.timestamp) {
        return balance;
      }
      return 0;
  }

  /**
    * @dev See {IERC721-ownerOf}.
    */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
      address owner = super.ownerOf(tokenId);
      require(_endSubscriptionTimestamps[owner] > block.timestamp, "SubscriptionNft: owner subscription is expired");
      return owner;
  }

  function mint(address recipient, uint256 subscriptionDuration) public onlyRole(MINTER_BURNER_ROLE) { 
      _safeMint(recipient, _tokenId);
      _endSubscriptionTimestamps[recipient] = block.timestamp.add(subscriptionDuration);
      _tokenId++;
  }

  function burn(uint256 tokenId_) public onlyRole(MINTER_BURNER_ROLE) {
      _burn(tokenId_);
  }

  function setMinter(address minter) public onlyOwner {
      // Grant the minter role to a specified account
      _setupRole(MINTER_BURNER_ROLE, minter);
  }
  
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  function endSubscriptionTimestampOf(address subscriber) public view returns (uint256) {
      return _endSubscriptionTimestamps[subscriber];
  }
}
