//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract SmartContractWallet {
    address payable public owner;
    constructor(){
        owner = payable(msg.sender);
    }
    address payable newOwner;
    mapping (address =>bool) public maintainer;
    uint maintainerVotes;
    uint constant votesNeddedforReset=3;
    uint countmaintainers=0;
    
    function setMaintainer (address _address) public{
        require(msg.sender==owner,"Sorry, only owners are allowed to set Maintainers.");
        require(countmaintainers<5,"Maximum maintainers assigned");
        maintainer[_address]=true;
        countmaintainers++;        
    }
    
    mapping(address=>mapping(address=>bool)) maintainerVoted;
    function voteToAppointNewOwner(address payable _newOwner) public {
        require(maintainer[msg.sender],"Sorry, only Maintainers are allowed to appoint new Owner");
        require(!maintainerVoted[_newOwner][msg.sender],"Sorry, you have already voted and can't vote again");
        if(newOwner != _newOwner){
            maintainerVotes=0;
            newOwner = _newOwner;
        }
        maintainerVotes++;
        maintainerVoted[_newOwner][msg.sender]=true;
        if(maintainerVotes>=votesNeddedforReset){
            owner=newOwner;
            newOwner = payable(address(0));
        }
    }
    mapping (address=>uint) maxAllowed;
    mapping (address=>bool) isAllowedtoTransfer;
    function setMaxAllowedValue(address _address, uint amount) public {
        require(msg.sender==owner,"Sorry, only owner is allowed to set allowance");
        maxAllowed[_address]=amount;
        if(amount>0){
            isAllowedtoTransfer[_address]=true;
        }
        else{
            isAllowedtoTransfer[_address]=false;
        }

    }
    function viewMaxAllowedValue(address adrs) public view returns(uint){
        return maxAllowed[adrs];
    }

    function transfer(address payable to,uint amount,bytes memory payload) public returns(bytes memory retval){
        if(msg.sender!=owner){
            require(isAllowedtoTransfer[msg.sender],"You are not allowed to transfer anything");
            require(amount<=maxAllowed[msg.sender],"You can't send more than what is allowed");
            maxAllowed[msg.sender]-= amount;
        }
        (bool success,bytes memory returnvalue ) = to.call{value: amount}(payload);
        require(success,"transfer failed!");
        return returnvalue;
    }
    function viewWalletBalance() public view returns(uint bal) {
        require(msg.sender==owner,"only owner can view balance");
        return address(this).balance;

    }
    receive() external payable{}
}
