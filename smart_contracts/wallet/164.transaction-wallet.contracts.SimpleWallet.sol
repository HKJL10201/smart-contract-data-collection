// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract SimpleWallet {

    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'You are not the owner of the contract');
        _;
    }

    function withdrawMoney(address payable _to, uint8 _amount) public onlyOwner {
        _to.transfer(_amount);
    }

    receive() external payable {}
}
