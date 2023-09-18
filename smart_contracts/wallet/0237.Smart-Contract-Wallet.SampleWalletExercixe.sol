//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SampleWallet {
    address payable owner;

    mapping(address=>uint) public allowanceAmount; //define how much can spend the address (not if is allowed)
    mapping(address=>bool) public isAllowedToSend; //define if the asddress is allowed to send money(not the amount)

    mapping(address => bool) public guardians;//Guardian of the wallet declerate from owner 
    address payable nextOwner;//new owner of the waller
    mapping(address=> mapping(address=>bool)) nextOwnerGuardianVoteBool; //verify one time vote of guardians
    uint guardiansResetCount;//counter of votes
    uint public constant confirmationsFromGuardiansForReset = 3; //votes needed to change owner


    constructor() {
        owner = payable(msg.sender); //it's a "payable address" type not only "address" type
    } 

    function setGuardian(address _guardian, bool _isGuardian) public {
        require(msg.sender == owner, "You are not the owner, aborting");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner)public {
        require(guardians[msg.sender], "You are not the guardian of this wallet, aborting");//
        require(nextOwnerGuardianVoteBool[_newOwner][msg.sender] == false, "You already vote, aborting");
        
        if (_newOwner != nextOwner){
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if(guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner; //assign new owner next 3 votes of guardiansResetCount
            nextOwner = payable(address(0)); //restting of the next owner variable
        }
    }


    function setAllowance(address _for, uint _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting");
        allowanceAmount[_for] = _amount;
            
        if (_amount > 0){
              isAllowedToSend[_for] = true;
        }else {
             isAllowedToSend[_for] = false;
        }
        
    }

    //Transfer money 
    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns (bytes memory) {
        require(msg.sender == owner, "You are not the owner,aborting");
        if(msg.sender != owner){
            require(isAllowedToSend[msg.sender], "You are not allowed to send anything, aborting");//verify if is allowed
            require(allowanceAmount[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting");//verify the amount allowance

            allowanceAmount[msg.sender] -= _amount;
        }

        (bool success, bytes memory returndata) =   _to.call{value: _amount}(_payload);
        require(success,"Aborting, call was not successful");
        return returndata;
    }
    receive() external payable{
        
    }
}