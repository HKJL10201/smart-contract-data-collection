// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Consumer {
    function getBalance() public view returns(uint){
        return (address(this).balance);
    }

    function deposit() public payable {}
}

contract ProjectWallet{

    address payable Admin;
    mapping (address => uint) allowance;
    mapping (address => bool) allowedToSend;

    mapping (address => bool) guardians;

    address payable newAdmin;
    uint guardianCount;
    uint public constant guardianVoteNeed = 3;

    mapping (address => mapping (address => bool)) votedGuardians;

    constructor(){
        Admin = payable(msg.sender);
    }

    modifier onlyAdmin {
        require(msg.sender == Admin , "You are not the Admin, aborting!");
        _;
    }

    function setGuardian (address _guardian , bool _nowGuardian) public onlyAdmin{
        guardians[_guardian] = _nowGuardian;
    }

    function voteNewAdmin (address payable _newAdmin) public {
        require(guardians[msg.sender] , "You are not guardian, aborting");
        require(votedGuardians[_newAdmin][msg.sender], "You have already voted, aborting!");
        
        if (_newAdmin != newAdmin) {
            newAdmin = _newAdmin;
            guardianCount = 0;
        }

        guardianCount++;

        if(guardianCount >= guardianVoteNeed) {
            Admin = newAdmin;
            newAdmin = payable (address(0));
        }
    }

    function setAllowance (address payable _for , uint _amount) public onlyAdmin{
        allowance[_for] = _amount;

        if (_amount > 0) {
            allowedToSend[_for] = true;
        }else {
            allowedToSend[_for] = false;
        }
    }

    function transferFunds (
        address payable  _to ,
        uint _amount ,
        bytes memory _payload)
        public returns (bytes memory) {

            if(msg.sender != Admin) {
                require(allowance[msg.sender] >= _amount, "You are sending more funds than you are allowed, aborting!");
                require(allowedToSend[msg.sender], "You are not allowed for any transaction, aborting!");

                allowance[msg.sender] -= _amount;
            }

            (bool success , bytes memory toReturn) = _to.call{value : _amount} (_payload);
            require(success , "Transaction failed, aborting!");

            return toReturn;

    }

    receive () external payable {}
}