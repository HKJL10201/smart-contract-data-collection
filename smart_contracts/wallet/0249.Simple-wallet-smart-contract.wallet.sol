//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Consumer{

    function getBalance() public view returns(uint){
       return address(this).balance;
    }

    function deposit() public payable {} 
}

contract SmartContractWallet {
    
    address payable public owner;
    address payable nextOwner;
    
    mapping (address => uint) public allowance;    //how much an address is allowed to withdraw from the SC.
    mapping (address => bool) public isAllowedToSend; //whether an address is about to send. 
    mapping (address => bool) public guardians; //to see if an address is a guardian.
    mapping (address => mapping(address => bool)) nextOwnerGuardianVotedBool;
    
    uint guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;  //gives error if val not assigned. 
    
    constructor() {
        owner = payable(msg.sender);
    }

    function proposeNewOwner(address payable _newOwner) public{
        require(guardians[msg.sender], "you are not a guardian");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false, "you already voted");
        if (_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }
        guardiansResetCount ++;

        if (guardiansResetCount >= confirmationsFromGuardiansForReset ){
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setGuardian(address _guardian, bool _isguardian ) public {
        require(msg.sender == owner, "you are not the owner, abort");
        guardians[_guardian] = _isguardian;
    }

    function setAllowance(address _for, uint256 _amount) public {
        require(msg.sender == owner, "you are not the owner, abort");
        allowance[_for] = _amount;

        if (_amount > 0) {
            isAllowedToSend[_for ] = true; 
        }
    }

    function transfer(address payable _to,  uint _amount, bytes memory _payload) public returns (bytes memory ) {
        //require(msg.sender == owner, "You are not the owner");
        if (msg.sender != owner){
            require( isAllowedToSend[msg.sender], "you are not allowed to send anything from this SC");
            require( allowance[msg.sender] >= _amount, "You have insufficient funds" );
            allowance[msg.sender] -= _amount;
        }

        //_to.transfer(_amount);
        (bool success, bytes memory returnData ) = _to.call{value: _amount}(_payload);  
        require(success, "Aborting Call was successful");
        return returnData;
    } 

    receive() external payable{}  //will not work if call data is given while sending funds.
} 
