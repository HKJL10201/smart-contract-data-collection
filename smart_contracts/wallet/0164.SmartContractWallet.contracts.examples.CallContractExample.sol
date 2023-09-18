//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// These are generic ways of send funds but be careful because this approach opens the door for reEntrancy attacks.
contract ContractOne {
    mapping (address => uint) public addressBalances;

    function deposit() public payable {
        addressBalances[msg.sender] += msg.value;
    }
}

contract ContractTwo {
    receive() external payable {}

    function depositToContractOne(address _contract) public {
        ContractOne one = ContractOne(_contract);   // Common approach similar to other languages.
        one.deposit{value: 10, gas: 100000}();
    }
}

contract ContractThree {
    mapping (address => uint) public addressBalances;

    function deposit() public payable {
        addressBalances[msg.sender] += msg.value;
    }
}

contract ContractFour {
    receive() external payable {}

    function depositToContractOne(address _contract) public {
        bytes memory payload = abi.encodeWithSignature("deposit()");    // If you know the contract name, you can encode it with the abi.
        (bool success, ) = _contract.call{value: 10, gas: 100000}(payload);
        require(success);
    }
}

contract ContractFive {
    mapping (address => uint) public addressBalances;

    function deposit() public payable {
        addressBalances[msg.sender] += msg.value;
    }

    receive() external payable {
        deposit();
    }
}

contract ContractSix {
    receive() external payable {}

    function depositToContractOne(address _contract) public {

        // If you do not know the contract name, but the tricky part are the additional lines added from 47-49.
        // The question is, how do you determine the contract/function name?
        (bool success, ) = _contract.call{value: 10, gas: 100000}(""); 
        require(success);
    }
}