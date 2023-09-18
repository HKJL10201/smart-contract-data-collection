//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Main contract representing a wallet where funds are locked
contract TimeLockedWallet is AccessControl {
    // defining the funds owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // contract creator, should be the factory
    address public factory;
    // funds owner
    address public owner;
    uint256 public unlockDate;
    uint256 public createdAt;
    // emitted when the funds owner withdraw ETH from his funds
    // _reciever is the owner address
    // _amount is the withdrawn amount
    event WithdrewETH(address _receiver, uint256 _amount);

    // emitted when the funds owner withdraw token his funds
    // _token is the token address
    // _reciever is the owner address
    // _amount is the withdrawn amount
    event WithdrewTokens(address _token, address _receiver, uint256 _amount);

    // emitted when the contract receives ETH.
    // _sender is the address sending ethers.
    // _amount is the withdrawn amount
    event ReceivedETH(address _sender, uint256 _amount);

    constructor(
        address _factory,
        address _owner,
        uint256 _unlockDate
    ) {
        factory = _factory;
        owner = _owner;
        unlockDate = _unlockDate;
        createdAt = block.timestamp;
    }

    // function to withdrawal ETH funds, ckecks if the unlocking time was reached
    function withdrawFunds(address token, uint256 _amount)
        public
        onlyRole(OWNER_ROLE)
    {
        // ETH withdrawal
        // ETH address is represented by the string
        if (token == address(0xfEfFEfFEfeeeeeeeeee)) {
            require(
                _amount <= address(this).balance,
                "Amount exceeds current balance"
            );
            require(block.timestamp >= unlockDate, "Funds are locked");

            (bool success, ) = msg.sender.call{value: _amount}("");
            require(success, "Transfer failed.");

            emit WithdrewETH(msg.sender, _amount);
        }
        // ERC20 Tokens withdrawal
        else {
            require(
                _amount <= IERC20(token).balanceOf(address(this)),
                "Amount exceeds current balance"
            );
            require(block.timestamp >= unlockDate, "Funds are locked");
            // Calling ERC20 transfer function. Emits a Transfer event.
            IERC20(token).transfer(owner, _amount);

            emit WithdrewTokens(token, msg.sender, _amount);
        }
    }

    // receive ether function
    // Note: using payable fallback functions for receiving Ether is not recommended, since it would not fail on interface confusions).
    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }
}
