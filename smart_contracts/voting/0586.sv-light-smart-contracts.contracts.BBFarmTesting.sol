pragma solidity ^0.4.24;


import { IxIface } from "./SVIndex.sol";


contract BBFarmTesting {
    // namespaces should be unique for each bbFarm
    bytes4 NAMESPACE;

    event BBFarmInit(bytes4 namespace);

    constructor(bytes4 ns) public {
        NAMESPACE = ns;
        emit BBFarmInit(ns);
    }

    function getNamespace() external view returns (bytes4) {
        return NAMESPACE;
    }

    function initBallot( bytes32
                       , uint256
                       , IxIface
                       , address
                       , bytes24) external returns (uint) {
        // return some dummy data with the right namespace
        return uint224(blockhash(block.number - 1)) ^ (uint256(NAMESPACE) << 224);
    }
}
