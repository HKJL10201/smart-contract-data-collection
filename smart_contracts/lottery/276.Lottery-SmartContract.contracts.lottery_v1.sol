// pragma solidity ^0.4.26;

// contract Lottery{
//     address public manager;
//     address[] public players;
//     address public lastWinner;

//     function Lottery() public {
//         manager = msg.sender;
//     }

//     // function enter() public restricted payable {
//     function enter() public payable {
//         require(msg.value > .01 ether);

//         players.push(msg.sender);
//     }

//     // function random() private view restricted returns (uint) {
//     function random() private view returns (uint) {
//         return uint(keccak256(block.difficulty, now, players)); // = sha3() 
//     }
    
//     // function pickWinner() public {
//     //     require(msg.sender == manager);

//     //     uint index = random() % players.length;
//     //     players[index].transfer(this.balance);
//     //     lastWinner = players[index]; // this is just for getting the winner info
//     //     players = new address[](5);
//     // }

//     // avoid the same code as 22, use modifier
//     // function returnEntries {
//     //     require(msg.sender == manager);
//     // }

//     function pickWinner() public restricted {
//         uint index = random() % players.length;
//         players[index].transfer(this.balance);
//         players = new address[](0);
//     }

//     // onlyManagersCanCall
//     modifier restricted() {
//         require(msg.sender == manager);
//         // go on rest code part 
//         _;
//     }

//     function getPlayers() public view returns (address[]) {
//         return players;
//     }
// }