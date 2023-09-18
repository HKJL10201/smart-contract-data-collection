// SPDX-License-Identifier: GPT-3

pragma solidity ^0.8.4;

contract mainLottery{

    address public Admin;
    address [] public players;
    uint regFee;

    // Assign Owner as Admin and dynamically set the registration Fee
    constructor(uint _regFee){
        msg.sender == Admin;
        regFee = _regFee;
    }

    modifier onlyAdmin(){
        require(msg.sender == Admin);
        _;
    }

    // Event for Registration
    event newRegistration(string message, address addr, uint fee);

    function registration(address _playerAddress) external payable {
        require(msg.value >= regFee, "Can not pay below registration fee");
        players.push(_playerAddress);

        emit newRegistration("New Registration Alert", _playerAddress, regFee);
    }


    function Randomness() private view returns(uint){
        return uint (keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function selectWinner() external payable{
        // Select random winner
        uint playerIndex = Randomness() % players.length;
        
        // send ethers to winner
        payable(players[playerIndex]).transfer(address(this).balance);

        players = new address[](0);
    }

    function showAllPlayers() external view onlyAdmin returns(address [] memory){
        return players;
    }
}