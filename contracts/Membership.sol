//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./tokens/SubscriptionNft.sol";
import "hardhat/console.sol";

contract Membership is Ownable {

    using SafeMath for uint256;

    mapping(IERC20 => uint256) private _tokenSubscriptionAmountsPerSeconds;
    IERC20[] _acceptedTokens;
    SubscriptionNft private _subscriptionNft;
    mapping(address => uint256) private _subscriptions;

    constructor(
        SubscriptionNft subscriptionNft_,
        IERC20[] memory acceptedTokens_, 
        uint256[] memory tokenSubscriptionAmountsPerSeconds_) {
        for (uint256 i = 0; i < acceptedTokens_.length; i++) {
            IERC20 acceptedToken = acceptedTokens_[i];
            _tokenSubscriptionAmountsPerSeconds[acceptedToken] = tokenSubscriptionAmountsPerSeconds_[i];
            _acceptedTokens.push(acceptedToken);
        }
        _subscriptionNft = subscriptionNft_;
    }

    function subscribe(IERC20 token_) public {
        require(_tokenSubscriptionAmountsPerSeconds[token_] > 0, "Membership: This token is not authorized for subscription");
        require(_subscriptionNft.balanceOf(_msgSender()) == 0, "Membership: This address already have a subscription");
        require(token_.allowance(_msgSender(), address(this)) > 0);
        uint tokenAmount = token_.allowance(_msgSender(), address(this));
        require(tokenAmount >= _tokenSubscriptionAmountsPerSeconds[token_], "Membership: Not enought of this token to subscribe");
        require(token_.transferFrom(_msgSender(), address(this), tokenAmount));
        uint256 subscriptionDuration = tokenAmount.div(_tokenSubscriptionAmountsPerSeconds[token_]);
        _subscriptionNft.mint(_msgSender(), subscriptionDuration);
    }

    function hasEnoughtTokens(address member) public view returns (bool) {
        bool hasEnought = false;
        for (uint256 i = 0; i < _acceptedTokens.length; i++) {
            IERC20 acceptedToken = _acceptedTokens[i];
            hasEnought = hasEnought || hasEnoughtTokens(member, acceptedToken);
        }
        return hasEnought;
    }

    function hasEnoughtTokens(address member, IERC20 token) public view returns (bool) {
        return _subscriptions[member] >= _tokenSubscriptionAmountsPerSeconds[token];
    }
}
