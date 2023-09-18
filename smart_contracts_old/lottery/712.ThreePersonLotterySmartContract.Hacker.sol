pragma solidity ^0.4.21;

import "./three_lottery.sol";

contract Hacker
{
    three_lottery public lottery;
    uint public count;
    uint public balance;
    uint nonce;
    uint pick;
    address owner;

    function getBalance()
    public
    returns (uint256)
    {
        address con = this;
        return con.balance;
    }

    function Hacker(three_lottery _lottery)
    public
    {
        lottery = three_lottery(_lottery);
        count = 0;
        balance = 0;
        nonce = 0;
        pick = 0;
        owner = msg.sender;
    }

    function enter(bytes32 hash)
    public
    payable
    {
        uint amount = msg.value;
        address l = lottery;
        l.call.gas(1060000).value(amount)(bytes4(sha3("enter_lottery(bytes32)")), hash);
    }

    function reveal()
    public
    {
        address l = lottery;
        l.call.gas(1060000)(bytes4(sha3("reveal_pick(uint256,uint256)")), nonce, pick);
    }

    function ()
    payable 
    {
        count += 1;
    }

}
