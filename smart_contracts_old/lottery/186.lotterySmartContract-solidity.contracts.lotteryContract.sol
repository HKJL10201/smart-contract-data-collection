pragma solidity ^0.4.17;

contract lotteryContract {
    address public manager; // The address of the person who created this contract
    address[] public players; // The players who're investing ethers in the lottery

    function lotteryContract() public {
        manager = msg.sender;
    }

    function getPlayersAddress() public payable {
        require(msg.value >= 0.00000001 ether); // Put a check that a player should invest atleast 0.1 ether in the lottery
        // if above condition will return true then only it will execute the next stpes
        players.push(msg.sender); // Save the address of players who're submitting their ethers in lottery
    }

    // To generate random number, to pick winner from players array
    function getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(block.difficulty, now, players));
    }

    // To get the winner from players array
    function getWinner() public onlyManagerCanAccess {
        uint256 index = getRandomNumber() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }

    // modifier function to restrict the unauthorised activity in contract
    modifier onlyManagerCanAccess() {
        require(msg.sender == manager); // Because manager only can pick the winner
        _;
    }

    // get all the players who're entered for lottery
    function getAllPlayers() public view returns (address[] memory) {
        return players;
    }
}
