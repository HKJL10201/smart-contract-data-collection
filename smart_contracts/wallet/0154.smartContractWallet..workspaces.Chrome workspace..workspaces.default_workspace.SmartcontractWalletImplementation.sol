//SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <= 0.9.0;

contract Consumer{
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function deposit() public payable{}
}

contract SmartContractWallet{

    modifier onlyOwner(){
        require(owner == msg.sender,"You are not the OWNER !!");
        _;
    }

    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;
    address payable public nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVoteBool;
    uint  guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;

    constructor(){
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _isGuardian) public onlyOwner{
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public{
        require(guardians[msg.sender],"You are not guardian of this wallet, aborting");
        require(nextOwnerGuardianVoteBool[nextOwner][msg.sender] == false, "You already voted, aborting");
        if(_newOwner != nextOwner){
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }
        guardiansResetCount++;

        if(guardiansResetCount >= confirmationsFromGuardiansForReset){
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _for, uint _amount) public onlyOwner{
        allowance[_for] = _amount;
        if(_amount > 0){
            isAllowedToSend[_for] = true;
        }
        else{
            isAllowedToSend[_for] = false;
        }
    }    

    function sendMoney(address payable _to, uint _amount, bytes memory _payload) public returns (bytes memory) {
        if(msg.sender != owner){
            require(isAllowedToSend[msg.sender],"You are not allowed to send anything from this smart contract, Aborting!!");
            require(allowance[msg.sender]>= _amount,"You are trying to send more than the allowed amount, Aborting!!");
            allowance[msg.sender] -= _amount;
        }
        
        (bool success, bytes memory returnData) = _to.call{value:_amount}(_payload);
        require(success,"Aborting, Call was not successful");
        return returnData;
        
    }

    receive() external payable{}

}