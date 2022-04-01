// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

/*
This contract's job is to allow two parties to atomically swap
their NFT's. Let's walk through an example with Alice and Bob.

1.) Alice proposes a Swap, between her and Bob, with exactly which token she's willing to trade
2.) Alice approves the Swapper contract to move her token on her behalf.
3.) Bob approves the Swapper contract to move his token on his behalf.
4.) Anyone can then call the swap function, passing in the Swap ID (from step 1), and the tokens are atomically swapped.
*/

contract Swapper {
    uint256 swapIdCounter;
    mapping(uint256 => Swap) public swaps;
    mapping(uint256 => uint256) public pendingWithdrawals; // refundable wei of unsuccessful swaps

    struct Swap {
        address token1;
        uint256 tokenId1;
        address owner1;
        address token2;
        uint256 tokenId2;
        address owner2;
        uint256 askPrice;
        uint256 expirationTime;
    }

    event SwapCreated(
        uint256 swapId,
        address token1,
        uint256 tokenId1,
        address owner1,
        address token2,
        uint256 tokenId2,
        address owner2,
        uint256 askPrice,
        uint256 expirationTime
    );

    event SwapExecution(uint256 indexed swapId);
    event MakePayment(uint256 indexed swapId, uint256 indexed askPrice);
    event Withdrawal(uint256 indexed swapId, uint256 indexed askPrice);

    function proposeSwap(Swap memory _swap) public returns (uint256 swapId) {
        swapId = swapIdCounter;
        swaps[swapId] = _swap;
        pendingWithdrawals[swapId] = 0;

        emit SwapCreated(
            swapIdCounter,
            _swap.token1,
            _swap.tokenId1,
            _swap.owner1,
            _swap.token2,
            _swap.tokenId2,
            _swap.owner2,
            _swap.askPrice,
            _swap.expirationTime
        );
        swapIdCounter += 1;
    }

    // Allows user to pay the optionally asked swap price
    function makePayment(uint256 swapId) public payable {
        require(_isSwapNotExpired(swapId), "Swap has expired");
        require(
            _getOwnerWhoPaysAskPrice(swapId) == msg.sender,
            "Caller is not required payment"
        );
        require(msg.value >= _getAskPrice(swapId), "Not enough eth");
        pendingWithdrawals[swapId] += msg.value;
        emit MakePayment(swapId, _getAskPrice(swapId));
    }
    
    // Allows user to withdraw their payment for an expired or unrealized swap.
    function withdraw(uint256 swapId) public {
        require(
            _getOwnerWhoPaysAskPrice(swapId) == msg.sender,
            "Unauthorized"
        );
      uint _amount = pendingWithdrawals[swapId];
      if (_amount == 0) revert('No funds to withdraw');
      payable(msg.sender).transfer(_amount);
      pendingWithdrawals[swapId] = 0;
    }

    // Allows two users to swap tokens
    function swap(uint256 swapId) external payable {
      require(_isSwapNotExpired(swapId), "Swap has expired");
      require(_getAskPrice(swapId) == pendingWithdrawals[swapId], "Payment is not done");
      Swap memory _swap = swaps[swapId];
      
      _executeTokenTransfer(
            _swap.owner1,
            _swap.owner2,
            _swap.token1,
            _swap.tokenId1
        );
        _executeTokenTransfer(
            _swap.owner2,
            _swap.owner1,
            _swap.token2,
            _swap.tokenId2
        );

        // Transfer askedPrice
        if(_getAskPrice(swapId) != 0){
        payable(_swap.owner1).transfer(_getAskPrice(swapId));
        pendingWithdrawals[swapId] = 0;
        }

        emit SwapExecution(swapId);
    }

    // helper functions
    function _executeTokenTransfer(
        address from,
        address to,
        address token,
        uint256 tokenId
    ) internal {
        IERC721 Token = IERC721(token);
        Token.safeTransferFrom(from, to, tokenId);
    }

    function _getOwnerWhoPaysAskPrice(uint256 swapId)
        internal
        view
        returns (address ownerWhoPaysAskPrice)
    {
        ownerWhoPaysAskPrice = swaps[swapId].owner2;
    }

    function _isSwapNotExpired(uint256 swapId)
        internal
        view
        returns (bool notExpired)
    {
        notExpired = block.timestamp <= swaps[swapId].expirationTime;
    }

    function _getAskPrice(uint256 swapId)
        internal
        view
        returns (uint256 askPrice)
    {
        askPrice = swaps[swapId].askPrice;
    }
}
