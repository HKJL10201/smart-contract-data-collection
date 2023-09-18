//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract SmartContractWallet
{
    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardian;
    address payable nextOwner;
    uint guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;
    mapping(address => mapping (address => bool)) public nextGuardinVoteBool;

    constructor(){
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool isGuardian) public {
        require(msg.sender == owner , "you are not the owner, aborting");
        guardian[_guardian] = isGuardian;
    }

    function proposeNewOwner(address payable newOwner) public {
        require(guardian[msg.sender], "You are no guardian, aborting");
        require(nextGuardinVoteBool[newOwner][msg.sender] == false, "you already voted, aborting");

        if(nextOwner != newOwner) {
            nextOwner = newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if(guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    
    function setAllowance(address _for, uint _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        allowance[_for] = _amount;
        
        if(_amount > 0){
          isAllowedToSend[_for] = true;
        }
         isAllowedToSend[_for] = false;
    }

    function denySending(address _from) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        isAllowedToSend[_from] = false;
    }

    function transfer(address payable _to, uint _amount , bytes memory payload) public returns(bytes memory){
        require(_amount <= address(this).balance, "Can't send more than the contract owns, aborting.");
        if(msg.sender != owner) {
            require(isAllowedToSend[msg.sender], "You are not allowed to send any transactions, aborting");
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting");
            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(payload);
        require(success, "Transaction failed, aborting");
        return returnData;
    }

    receive() external payable{}
}
