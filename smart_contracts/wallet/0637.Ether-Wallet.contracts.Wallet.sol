// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract Wallet
{
    event EtherExtracted(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    address private _owner;

    constructor()
    {
        _owner = msg.sender;
    }

    modifier onlyOwner
    {
        require(msg.sender == _owner, "Permission Denied, You're not the Owner!");
        _;
    }

    function extractEther(address payable account, uint256 amount) onlyOwner external returns (bool)
    {
        require(address(this).balance > 0, "Zero Balance!");
        require(address(this).balance >= amount, "Low Balance!");
        account.transfer(amount);
        emit EtherExtracted(address(this), account, amount, block.timestamp);
        return true;
    }

    function extractAllEther(address payable account) onlyOwner external returns (bool)
    {
        require(address(this).balance > 0, "Zero Balance!");
        account.transfer(address(this).balance);
        emit EtherExtracted(address(this), account, address(this).balance, block.timestamp);
        return true;
    }

    receive() external payable {}
}
