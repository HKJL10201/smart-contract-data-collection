// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GuessGame is Ownable {

    string wordToGuess;
    string hint;
    mapping(address => bool) players;
    address public winner = address(0x0);

    event GetHint(string hint);
    event ProposalSubmited(address addr);
    event Winner(address winnerAddress);

    function setGame(string calldata _word, string calldata _hint) external onlyOwner{
        wordToGuess = _word;
        hint = _hint;
    }

    function getHint() external returns(string memory){
        require(players[msg.sender], "You must guess a first word before to have a hint.");
        emit GetHint(hint);
        return hint;
    }

    function proposal(string memory _guess) external returns(bool) {
        require(winner == address(0x0), "Someone already won. The game ended");
        if (!players[msg.sender]){
            players[msg.sender] = true;
        }
        emit ProposalSubmited(msg.sender);
        bool _match = (keccak256(abi.encode(_guess)) == keccak256(abi.encode(wordToGuess)));
        if (_match){
            winner = msg.sender;
            emit Winner(msg.sender);
        }
        return _match;
    }

}
