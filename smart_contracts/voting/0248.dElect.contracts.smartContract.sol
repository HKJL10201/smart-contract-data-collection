pragma solidity ^0.5.1;

// Provide DeadmanSwitch TABconf workshop
contract DeadmanSwitch {

    address public beneficiary; // named beneficiary
    address public estate; // estate
    uint public expiration; // block number of the expiration
    uint public ttl = 100; // time to live (number of blocks)

    // TODO: add ERC20 token balance

    constructor(address _beneficiary) public {
        estate = msg.sender;
        beneficiary = _beneficiary;
        expiration = block.number + ttl;
    }

    function checkin() public onlyEstate onlyNotExpired {
        expiration = block.number + ttl;
    }

    function withdraw() public onlyBeneficiary onlyExpired {
        // TODO: transfer ERC20 balance to beneficiary
    }

    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary) {
            revert("Cannot withdraw unless named beneficary.");
        }
        _;
    }

    modifier onlyEstate() {
        if (msg.sender != estate) {
            revert("Cannot execute unless estate.");
        }
        _;
    }
    
    modifier onlyExpired() {
        if (block.number < expiration) {
            revert("Cannot execute prior to expiration.");
        }
        _;
    }

    modifier onlyNotExpired() {
        if (block.number >= expiration) {
            revert("Cannot execute after expiration.");
        }
        _;
    }
}