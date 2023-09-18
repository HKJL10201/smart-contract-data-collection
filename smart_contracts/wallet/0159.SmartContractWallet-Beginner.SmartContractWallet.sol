// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract SmartContractWallet{

    address payable public owner;
    mapping(address=> uint) public allowance;
    mapping(address=>bool)public isAllowedToSend;
    uint public guardianCount;
    address payable newOwner;

    struct guardian{
        bool enabled;
        bool vote;
        bool record;
    }
    mapping (address=>guardian) public boolGuardian;
    uint public guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;
    bool proposalSet;

    constructor(){
        owner= payable(msg.sender);
    }

    function setGuardian(address _guardian)public{
        require(msg.sender== owner,"not the owner");
        if(guardianCount<5){
            boolGuardian[_guardian].enabled = true;
            guardianCount++;
        }else{
            revert("5 guardians already set");
        }
    }

    function removeGuardian(address _guardian)public{
        require(msg.sender== owner,"not the owner");
            boolGuardian[_guardian].enabled = false;
            guardianCount--;
    }

    function proposeNewOwner(address payable _nextOwner) public {
        require(boolGuardian[msg.sender].enabled,"Not a guardian");
        require(!proposalSet,"Proposal already set");
        require(newOwner==address(0),"owner not resetted");
        if(newOwner!= _nextOwner){
            newOwner=_nextOwner;
            guardiansResetCount=0;
            proposalSet = true;
        } 
    }

    function implementNewOwner(bool _record) public {
        require(boolGuardian[msg.sender].enabled,"Not a guardian");
        require(proposalSet,"Proposal not set");
        require(!boolGuardian[msg.sender].vote,"Already votted" );
        boolGuardian[msg.sender].record= _record;
        require(boolGuardian[msg.sender].record,"Guardian Not in favour");
        if(guardiansResetCount >= confirmationsFromGuardiansForReset){
            owner = newOwner;
            newOwner = payable(address(0));
            guardiansResetCount = 0;
            proposalSet = false;
        }
        boolGuardian[msg.sender].vote = true;
        guardiansResetCount++;
    }

    function resetVote() public {
        require(boolGuardian[msg.sender].enabled,"Not a guardian");
        require(newOwner == address(0),"Voting in progress");
        boolGuardian[msg.sender].vote = false;
        boolGuardian[msg.sender].record= false;
    }

    function setAllowance(address _from, uint _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        allowance[_from] = _amount;
        isAllowedToSend[_from] = true;
    }

    function denySending(address _from) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        isAllowedToSend[_from] = false;
    }

    function transfer(address payable _to, uint _amount , bytes memory payload)public returns(bytes memory){
        require(_amount<= address(this).balance, "Insufficient Fund");
        if(msg.sender != owner) {
            require(isAllowedToSend[msg.sender], "You are not allowed to send any transactions, aborting");
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting");
            allowance[msg.sender] -= _amount;

        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(payload);
        require(success, "Transaction failed, aborting");
        return returnData;
    }
    receive()external payable{}
}
