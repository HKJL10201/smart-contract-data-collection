// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lotty is ERC20 {
    address public lotteryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _lotteryAddress
    ) ERC20(_name, _symbol) {
        lotteryAddress = _lotteryAddress;
    }

    function mint(address _recipient) external {
        require(msg.sender == lotteryAddress, "Only Lottery Address");
        _mint(_recipient, 5000000000000000000);
    }

    function changeLotteryAddr(address _lotteryAddr) public {
        lotteryAddress = _lotteryAddr;
    }
}