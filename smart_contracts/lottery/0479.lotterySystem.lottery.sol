pragma solidity ^0.8.0;

contract lottery {

    address payable public owner;
    address[] public userlist;
    mapping(address => uint256) public users;
    uint public registrationFee = 10 wei; 

    constructor() {
        owner = payable(msg.sender);
    }

    function register(address ad) public payable returns (string memory) {
        require(msg.value >= registrationFee, "Insufficient registration fee");
        userlist.push(ad); 
        users[ad] += msg.value - registrationFee; 
        owner.transfer(registrationFee); 
        return "Registered successfully";
    }

    function pickWinner() public view returns (address) {
          require(msg.sender == owner, "Only the owner can pick a winner");
          require(userlist.length > 0, "No users registered yet");
         uint index = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % userlist.length; 
         address winner = userlist[index]; 
         return winner;
    }

    function ulist() public view returns(address [] memory)
    {
        return userlist;
    }

}
