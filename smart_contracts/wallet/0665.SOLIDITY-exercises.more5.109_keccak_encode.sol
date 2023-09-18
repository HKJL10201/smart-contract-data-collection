//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Hash {
    function hash(uint a, string memory b, uint[] memory c) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(a, b, c));
    }
    function hash2() external pure returns(bytes32) {
        return keccak256("hello");
    }

    function encode1(string memory a, uint b) external pure returns(bytes memory){
        return abi.encode(a, b);
    }
    function encode2(string memory a, uint b) external pure returns(bytes memory){
        return abi.encodePacked(a, b);
    }
}

/*
1) keccak256 can take only strings as input.Thats what I found
2) keccak256 can take only one value as input
3) keccak256 returns bytes32 as result 
4) We need to use abi.encodePacked():
- to be able to convert multiple values into a keccak hash.
- to be able to take any data type as input.
- to be able to reach function parameters. Otherwise we will have to use string alone.
5) abi.encodePacked / abi.encode returns bytes.
6)- abi.encode converts input data to bytes format.
- abi.encodePacked converts input data to bytes format but compresses it.
7) abi.encodePacked loophole: when you put two same type data next to each other in abi.encodePacked,
it will give same result for this case:
"aaa", "abbb" -- same bytes data
"aaaa", "bbb" -- same bytes data.
And in turn, if you are using keccak256, it will produce same hash because of this loophole ("Hash Collision")
To overcome this:
- you can put another input type in between them.
- you can use abi.encode() instead.

 */