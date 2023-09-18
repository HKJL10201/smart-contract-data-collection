pragma solidity ^0.4.24;

contract Signidice {

    function generateRnd(uint[2][] ranges, bytes _entropy) public pure returns(uint[]) {
        uint[] memory randoms = new uint[](ranges.length);
        for (uint i = 0; i < ranges.length; i++) {
            uint256[2] memory range = ranges[i];

            uint256 _min  = range[0];
            uint256 _max  = range[1];
            uint256 delta = (_max - _min + 1);

            bytes32 lucky = keccak256(abi.encodePacked(_entropy, uint256(i)));

            while (uint256(lucky) >= (2**(256-1)/delta) * delta) {
                lucky = keccak256(abi.encodePacked(lucky));
            }

            uint256 result = (uint256(lucky) % (delta)) +_min;
            randoms[i] = result;
        }
        return randoms;
    }
}
