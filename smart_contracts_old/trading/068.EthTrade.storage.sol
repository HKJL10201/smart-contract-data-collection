pragma solidity ^0.4.6;

/**
 * Style Guide: http://solidity.readthedocs.io/en/develop/style-guide.html
 *
 * Contract:
 * 1. Anyone can Set the number           << Costs ETH for execution
 * 2. Anyone can Get the number set       << Costs 0 gas
 *
 **/
contract SimpleStorage {
    uint storedData;

    event NumberSet(address bywho, uint num);

    // When a number is set and event gets emitted
    function set(uint x) {
        storedData = x;

        address byWho = msg.sender;
        NumberSet(byWho, x);
    }

    function get() constant returns (uint) {
        return storedData;
    }
}