// SPDX-License-Identifier: GPL-3.0

/*Shared Wallet - where anyone is allowed to deposit money and the owner assigns members with allowance to withdraw money.The member*/
pragma solidity ^0.8.7;

/*Using Ownable and SafeMath Libraries from OpenZeppelin*/
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SharedWallet is Ownable{

    uint public WalletBalance;

    event AllowanceChanged(address _who,address _whose,uint _oldamount, uint  _newamount);
    event MoneySent(address _towhom, uint amount);
    event MoneyReceived(address _fromwho, uint amount);

    /*Mapping the member addresses to their allowance*/
    mapping (address => uint) public member;

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    /*to add allowance to an address so that they can withraw funds from the Wallet. Only Owner can add a member*/
    function addAllowance(address member_address, uint member_allowance) public onlyOwner{
        emit AllowanceChanged(msg.sender,member_address,member[member_address],member[member_address] + member_allowance);
        member[member_address] = member_allowance;
    }

    /*to deposit funds to the wallet*/
    function depositFunds() payable public{
        assert(WalletBalance + msg.value >= WalletBalance);
        WalletBalance += msg.value;
        emit MoneyReceived(msg.sender,msg.value);
    }

    /*to make sure only owner or member has access to withdraw funds from the wallet*/
    modifier owner_member(uint withdraw_amt){
        require(isOwner() || member[msg.sender] >= withdraw_amt, "You are not allowed to withdraw funds");
        _;
    }

    /*to reduce the allowance once the amount has been withdrawn*/
    function reduceAllowance(address member_address,uint withdraw_amt) internal {
        emit AllowanceChanged(msg.sender,member_address,member[member_address],member[member_address]-withdraw_amt);
        member[member_address] -=withdraw_amt;
        
    }

    /* to correctly withdraw funds to a given address */
    function withdrawFunds(address payable _to,uint withdraw_amt) public owner_member(withdraw_amt) {
        require(WalletBalance >= withdraw_amt, "Not enough funds to withdraw this amount");
        assert(WalletBalance - withdraw_amt <= WalletBalance);
        if(!isOwner()){
            reduceAllowance(msg.sender,withdraw_amt);
        }
        emit MoneySent(_to,withdraw_amt);
        WalletBalance -= withdraw_amt;
        _to.transfer(withdraw_amt);
    }
    

    function renounceOwnership() public override onlyOwner {
        revert("can't renounceOwnership here"); //not possible with this smart contract
    }

    //fallback function
    receive() external payable{

    }    
}
    