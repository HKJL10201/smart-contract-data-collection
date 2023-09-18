// SPDX-License-Identifier: MIT

// This is the final task: The implementation of the Smart Contract Wallet 💸
// These are the requirements:
//      The wallet has one owner
//      The wallet should be able to receive funds, no matter what
//      It is possible for the owner to spend funds on any kind of address, no matter if its a so-called Externally Owned Account (EOA - with a private key), or a Contract Address.
//      It should be possible to allow certain people to spend up to a certain amount of funds.
//      It should be possible to set the owner to a different address by a minimum of 3 out of 5 guardians, in case funds are lost.

pragma solidity ^0.8.19;

contract SmartContractWallet {
    address payable owner;
    address payable nextOwner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;
    mapping(address => bool) public guardians;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVotedBool;
    
    uint guardiansResetCount;
    uint public constant cofirmationForGuardiansForReset = 3;

    constructor(){
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _isGuardian) public {
        require(msg.sender == owner, "You are not the owner, aborting.");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public {
        require(guardians[msg.sender], "You are not a guardian! Get out.");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false, "You already voted!");
        if(_newOwner != nextOwner){
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }
        guardiansResetCount++;
        if(guardiansResetCount >= cofirmationForGuardiansForReset){
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _from, uint _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting.");
        allowance[_from] = _amount;

        if(_amount > 0) {
            isAllowedToSend[_from] = true;
        } else {
            isAllowedToSend[_from] = false;
        }
    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory) {
        if(msg.sender != owner) {
            require(isAllowedToSend[msg.sender], "You are not allowed to send anything from this smart contract.");
            require(allowance[msg.sender] >= _amount, "Not enough funds.");

            allowance[msg.sender] -= _amount;
        }


        (bool success, bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success, "Aborting unsuccessful call.");
        return returnData;
    }

    receive() external payable {}
}
