pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players; //there are 2 types of address (payable & non-payable)
    address public manager; //EOA that deploys the contract

    constructor() {
        manager = msg.sender;
       // players.push(payable(manager));
    }

    //Players enter lottery by sending 0.1ETH to the contract address. Players' address will be recorded
    //into dynamic array called players
    //For contract to receive ETH from EOA -> need receive() or fallback()
    receive () external payable {
        //make sure that the manager cannot participate in the lottery
        //require(msg.sender != manager);

        require(msg.value == 0.1 ether);

        //adds the address of the sender
        players.push(payable(msg.sender));//converting the address to payable address
    }
    
    //Returns contract's balance in wei
    function getBalance() public view returns(uint) {
        require(msg.sender == manager, "Only manager can check the balance");
        return address(this).balance;
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
        //returning a random number
    }

    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 3);

        uint r = random(); //getting the randomly generated number
        address payable winner;

        //Getting the index based off of the random number
        uint index = r % players.length;
        winner = players[index];

        uint managerFee = (getBalance() * 10) / 100;
        
        payable(manager).transfer(managerFee);
        winner.transfer(getBalance());
        //transfer is a member function of any payable address & will transfer the amount
        //wei given as argument to the payable address, in this case winner

        //after sending the winning money, resetting the players state variable
        players = new address payable[](0); //0 means the size of the new dynamic array
    }
}