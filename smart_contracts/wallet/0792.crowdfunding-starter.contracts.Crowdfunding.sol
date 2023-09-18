// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Crowdfunding {
    // Tracks Deposit Events
    event Deposit(address token, address depositor, uint256 amount, uint256 balance);

    // Admin address that will receive the funds
    address public depositAddress;

    // The amount of investor deposits
    uint256 public totalDeposit;

    uint256 public targetRaise;

    // Tracks the deposited amount
    mapping(address => mapping(address => uint256)) public tokens;

    // Deploy the contract with depositAddress and targetRaise
    constructor(address _depositAddress, uint256 _targetRaise) {
        depositAddress = _depositAddress;
        targetRaise = _targetRaise;
    }

    function depositTokens(address _token, uint256 _amount) public {
        require(ERC20(_token).transferFrom(msg.sender, depositAddress, _amount));
        tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;
        totalDeposit += _amount;
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    // To view the balance of tokens user has in the platform
    function balanceOf(address _token, address _user)
        public
        view
        returns (uint256)
    {
        return tokens[_token][_user];
    }
}