// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NuxToken is ERC20 {
    address private owner;
    mapping(address => uint256) pendingWithdrawals;

    constructor(uint256 _initialSupply) public ERC20("NuxToken", "NTN") {
        _mint(msg.sender, _initialSupply);
        owner = msg.sender;
    }

    function buyToken(uint256 _amount) external payable {
        require(_amount == ((msg.value / 1 ether)), "Incorrect amount");
        transferFrom(owner, msg.sender, _amount);
    }

    function sellToken(uint256 _amount) external payable {
        pendingWithdrawals[msg.sender] = _amount;
        transfer(owner, _amount);
        withdrawEth();
    }

    function withdrawEth() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        // Making it zero before transfering to prevent reentrance attack
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount * 1 ether);
    }
}
