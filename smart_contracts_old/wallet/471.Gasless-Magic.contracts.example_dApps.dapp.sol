pragma solidity ^0.5.11;

/*  Example dapp contract to demo use of proxy contract.
    Only stores 2 variable and exposes a setter function for these values.
*/
contract dapp {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == owner, "Non-Owner accessed restricted function");
        _;
    }

    /* The values to be stored and publicly accessible to be read */
    uint256 public n;
    address public sender;

    /* Events used for Debugging */
    event debug(string, uint256);
    event debug(string, address);

    function debug_values(uint256 _n) internal {
        // Emit the values passed into the function
        emit debug("Function input: ", _n);

        // Emit the global values via events for debugging
        emit debug("Value of N is now: ", n);
        emit debug("Sender is now: ", sender);
    }

    // Setter function to change the stored variables
    function setN(uint256 _n) public returns (uint256) {
        n = _n;
        sender = msg.sender;

        debug_values(_n);
        return n;
    }

    // Same function as setN, but gets the sender address as return value
    function setN_getSender(uint256 _n) public returns (address) {
        n = _n;
        sender = msg.sender;

        debug_values(_n);
        return sender;
    }

    // Setter function to change the stored variables
    function setN_restricted(uint256 _n) public restricted returns (uint256) {
        n = _n;
        sender = msg.sender;

        debug_values(_n);
        return n;
    }
    
    // Simple fallback function that will just fire off an event when called.
    function() external payable {
        emit debug("Fallback function of dApp contract has been called by: ", msg.sender);
        sender = msg.sender;
    }
}