//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Consumer {
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract SmartContractWallet {
    address payable public owner;

    mapping(address => uint256) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVotedBool;
    uint256 guardiansResetCount;
    uint256 public constant confirmationsFromGuardiansForReset = 3;

    constructor() {
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _isGuardian) public {
        require(msg.sender == owner, "You are not the owner, aborting");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public {
        require(
            guardians[msg.sender],
            "You are not guardian of this wallet, aborting"
        );
        require(
            nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false,
            "You already voted, aborting"
        );
        if (_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if (guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _for, uint256 _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting");
        allowance[_for] = _amount;

        if (_amount > 0) {
            isAllowedToSend[msg.sender] = true;
        } else {
            isAllowedToSend[_for] = false;
        }
    }

    function transfer(
        address payable _to,
        uint256 _amount,
        bytes memory payload
    ) public returns (bytes memory) {
        require(
            _amount <= address(this).balance,
            "Can't send more than the contract owns, aborting."
        );
        if (msg.sender != owner) {
            require(
                isAllowedToSend[msg.sender],
                "You are not allowed to send any transactions, aborting"
            );
            require(
                allowance[msg.sender] >= _amount,
                "You are trying to send more than you are allowed to, aborting"
            );
            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(
            payload
        );
        require(success, "Transaction failed, aborting");
        return returnData;
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}