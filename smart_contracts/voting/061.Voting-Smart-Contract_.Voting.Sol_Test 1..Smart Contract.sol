/Users/abstaina/Desktop/Screenshot\ 2023-07-18\ at\ 11.52.52\ PM.png

 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract America {
address public ruler;
constructor() {
// Mint 10 million tokens to address of ruler// This way you can control the countrytokens[address(ruler)] = 10**18;
}
function vote(address candidate) public {
// Send 0.1 tokens to candidate// This is way of voting// 1 token = 1 voterequire(tokens[address(candidate)] > 0, 'Can not vote');
emit Vote(address(candidate), 0);
}
}
