pragma solidity ^0.6.6;

import "./interface/IClassroomChallenge.sol";


contract ExampleChallenge is IClassroomChallenge {
    function hintsCount() 
        external
        pure
        override
        returns (uint256) 
    {
        return 2;
    }

    function getHint(uint256 index, bytes32 seed)
        public
        view
        override
        returns (bytes32)
    {
        if (index == 0) return bytes32("HACKMONEY") | seed;
        if (index == 1) return ~bytes32("HACKMONEY") | seed;
    }

    function viewMaterial()
        external
        pure
        override
        returns (string memory) 
    {
        return "Material";
        //TODO: point a link to material hosted at IPFS/SIA using ENS
    }
}
