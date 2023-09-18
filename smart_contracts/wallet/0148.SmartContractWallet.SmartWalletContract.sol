// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

contract SmartContractWallet{

    address payable public owner;
    address payable nextowner;

    uint guardiansRestcount;
    uint public constant ConformationfromguardiansForRest = 3;

    mapping (address => uint) public allownce;
    mapping (address => bool) public isAllowedtosend;
    mapping (address => bool) public Guardians;
    mapping (address => mapping (address => bool)) public Nextownerguardianvotedbool;

    constructor () {
        owner = payable (msg.sender);
    }

    function transfer (address payable _to, uint _amount, bytes memory _payload) public returns (bytes memory) {
        if(msg.sender != owner) {
            require (isAllowedtosend[msg.sender], "You are not allowed to send anything for this smart contract, sorry");
            require (allownce[msg.sender] >= _amount, "You are trying more than you are allowed to");

            allownce [msg.sender] -= _amount;
        }

        (bool success, bytes memory returndata) = _to.call{value: _amount} (_payload);
        require (success, "sorry, call was not successfull");
        return returndata;
    }

    function setAllownce (address _for, uint _amount) public {
        require (msg.sender == owner, "You are not owner");
        allownce[msg.sender] = _amount;
        if (_amount > 0){
            isAllowedtosend [_for] = true;
        } else {
            isAllowedtosend [_for] = false;
        }
    }

    function setGuardian (address _addguardian, bool _isguardian) public {
        require (msg.sender == owner, "You are not owner");
        Guardians[_addguardian] = _isguardian;
    }

    function PorposeNewOwner (address payable _newowner) public {
        require(Guardians [msg.sender] , "You are not guardians of this wallet,sorry");
        require(Nextownerguardianvotedbool [_newowner] [msg.sender] == false, "You are not the owner, sorry");
        if (_newowner != nextowner) {
            nextowner = _newowner;
            guardiansRestcount = 0;
        }

        guardiansRestcount ++;

        if (guardiansRestcount >= ConformationfromguardiansForRest) {
            owner = nextowner;
            nextowner = payable (address(0)); 
        }
    }

    receive () external payable {}

}