
pragma solidity 0.5.12;
contract Lottery {
    address public manager;
    address payable[] public players;
    uint256 public totalTickets;
    mapping(address => uint256) public tickets;

    constructor() public {
        manager = msg.sender;
    }



    function genRandom() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, address(this), players)));
    }

    function winner() public restricted returns(address) {

        assert(msg.sender == manager && players.length != 0);
        uint i = genRandom() % players.length;
        players[i].transfer(address(this).balance);
        address winner = players[i];
        // Reset players

        for (uint16 j = 0; j < players.length; j++) {
            delete tickets[players[j]];
        }
        players = new address payable[](0);
        totalTickets = 0;
        return winner;
    }


    function enter() public payable {
        assert(msg.value > .01 ether);
        assert(gasleft() < block.gaslimit);
        if(tickets[msg.sender] == 0){
            players.push(msg.sender);
        }
        tickets[msg.sender] += 1;
        totalTickets +=1;
    }
    modifier restricted(){
        //Only manager can call the function
        assert(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

    function getTicketCount(bytes memory player_address) public view returns (uint256){
        return tickets[bytesToAddress(player_address)];

    }
    function getAllTicketCount() public view returns (uint256){
        return totalTickets;
    }


    function bytesToAddress (bytes memory b) private view returns (address) {
      uint result = 0;
      for (uint i = b.length-1; i+1 > 0; i--) {
        uint c = uint(uint8(b[i]));
        uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
        result += to_inc;
      }
      return address(result);
    }
}
