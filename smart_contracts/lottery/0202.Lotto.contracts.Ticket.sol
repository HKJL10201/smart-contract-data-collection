//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Ticket {
    address private owner;
    uint price;
    uint limit;
    uint commission = 1;
    address[] players;

    constructor(address _address, uint _price, uint _limit, uint _commission) payable {
        owner = _address;
        price = _price;
        require(_limit > 1, "Limit must be 2 to 1000");
        require(_limit < 1001, "Limit must be 2 to 1000");
        limit = _limit;
        require(_commission > 0, "Commission must be 0 to 99");
        require(_commission < 100, "Commission must be 0 to 99");
        commission = _commission;
    }
        
    function register() public payable {
        require(msg.value >= price, "Price is upper");
        require(players.length < limit, "Too many players");
        players.push(msg.sender);
        if (players.length == limit) {
            payout(players[random()]);
        }
    }


    function random() private view returns(uint) {
        // TODO GD check random!!
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))) % limit;
    }

    function payout(address _player) private {
        uint balance = getBalance();
        uint percent = balance / 100;
        uint winSize = balance - percent * commission;
        payable(_player).transfer(winSize);
        (bool success,) = address(owner).call{value: getBalance()}("");
        require(success);
        owner = _player;
    }

    function getPrice() public view returns(uint) {
        return price;
    }

    function getLimit() public view returns(uint) {
        return limit;
    }

    function getPlayers() public view returns(address[] memory) {
        return players;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

}