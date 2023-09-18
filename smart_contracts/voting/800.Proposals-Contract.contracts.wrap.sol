// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/ERC20.sol";

contract WRTW is ERC20 {
    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount);

    constructor() ERC20("TOKEN", "TK") {
        mint(address(this), 1000);
    }

    function deposit() public payable {
        require(msg.value <= 1, "you can deposit only one");
        mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) external {
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }
}
