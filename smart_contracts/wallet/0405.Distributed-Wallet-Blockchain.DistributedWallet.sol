pragma solidity ^0.6.0;
contract DistributedWallet{
    address public owner;
    bool pause;
    constructor() public{
    owner=msg.sender;
    }
    struct Payment{
        uint amount;
        uint timestamp;
    }
    struct Balance{
        uint amount;
        uint numPayment;
        mapping(uint => Payment) payments ;
    }
    mapping(address => Balance) public balanceRecord;
    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner is allowed");
        _;
    }
    modifier whileNotPause(){
        require(pause==false);
        _;
    }
    function changeCondition(bool change) public onlyOwner{
        pause=change;
    }
    function sendMoney() public payable whileNotPause{
        balanceRecord[msg.sender].amount += msg.value;
        balanceRecord[msg.sender].numPayment +=1;
        Payment memory pay=Payment(msg.value, now);
        balanceRecord[msg.sender].payments[balanceRecord[msg.sender].numPayment]=pay;
    }
    function getMoney() public view whileNotPause returns(uint){
        return balanceRecord[msg.sender].amount;
    }
    function weiToEth(uint amtInWei) public pure returns(uint){
        return amtInWei/(1 ether);
    }
    function withdrawMoney(uint withdrawAmount) public whileNotPause{
        require(balanceRecord[msg.sender].amount>withdrawAmount, "not enough balance to withdraw");
        balanceRecord[msg.sender].amount -= withdrawAmount;
        msg.sender.transfer(withdrawAmount);
    }
    function destroyContract(address payable end) public onlyOwner{
        selfdestruct(end);
    }
}