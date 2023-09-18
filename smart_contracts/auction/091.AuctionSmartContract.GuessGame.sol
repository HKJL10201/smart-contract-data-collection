// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

uint256 constant MIN_AMOUNT = 0.01 ether;
uint256 constant MAX_DIFF = 4;

contract GuessGame {
    uint256 public current_diff;

    function newGuessGame(uint256 _diff) external payable {
        require(msg.value >= MIN_AMOUNT);
        require(_diff <= MAX_DIFF && _diff != 0);
        require(current_diff == 0);

        current_diff = _diff;
    }

    function trySolve(uint256 preimage) external {
        require(current_diff != 0);
        bytes32 hash = keccak256(abi.encode(preimage, msg.sender));

        for(uint8 i = 0; i < current_diff; i++) {
            require(hash[i] == 0);
        }

        payable(msg.sender).transfer(address(this).balance);

        current_diff = 0;
    }
}
