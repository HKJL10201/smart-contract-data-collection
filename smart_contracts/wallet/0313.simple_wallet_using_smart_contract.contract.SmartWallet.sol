// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;


contract SmartWallet{
    
    address payable public owner;

    mapping(address => uint) allowance;
    mapping(address => bool) isAllowedToSend;
    mapping(address => bool) guardians;
    mapping(address => mapping(address => bool)) proposedNewOwner;

    address payable public newOwner;
    uint guardiansResetCount;
    uint public constant votesToResetOwner = 3;



    constructor() {
        owner = payable(msg.sender);
    }

    function resetOwner(address payable _newOwner) public{
        require(guardians[msg.sender],"You are not a guardian");
        require(!proposedNewOwner[_newOwner][msg.sender],"You are already voted");

        if(newOwner != _newOwner){
            newOwner = _newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if(guardiansResetCount >= votesToResetOwner){
            guardians[owner] = true;
            owner = newOwner;
            newOwner = payable(address(0));
        }

    }

    function setGuardian(address _guardian,bool _isGuardian) public {
        require(msg.sender == owner,"You are not owner to perform this action");
        guardians[_guardian]=_isGuardian;
    }

    function setAllowance(address _for,uint _amount) public {
        require(msg.sender == owner,"You are not owner to perform this action");
        allowance[_for]=_amount;

        if(_amount >0){
            isAllowedToSend[_for]=true;
        }

    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory){
        if(msg.sender != owner){
            require(isAllowedToSend[msg.sender],"You Are not Allowed to Send ANything from this SC");
            require(allowance[msg.sender] >= _amount,"Dont have enough money");
        }

        (bool success,bytes memory returnData) = _to.call{value:_amount}(_payload);
        require(success,"Transaction Failed");
        allowance[msg.sender]-=_amount;
        return returnData;
    }

    receive() external payable{}


}
