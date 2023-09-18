pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    //constructor function - Note caps //1
    constructor() public {
        manager = msg.sender;
    }

    // 2 , 2.1, 2.2
    function enter() public payable {
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }

    //3, 3.1, 3.2
    function random() private view returns (uint256) {
        return uint256(keccak256(block.difficulty, now, players));
    }

    //4 , 4.1
    function pickWinner() public restricted {
        uint256 index = random() % players.length; // gets index of winner
        players[index].transfer(this.balance);
        players = new address[](0); //4.2
    }

    //5
    //Modifiers
    modifier restricted() {
        require(msg.sender == manager, "You are not the manager"); //4.3 <= Was in section/block 4
        _; //5.1
    }

    //6
    //Retrieving all players
    function getPlayers() public view returns (address[]) {
        return players;
    }
}

//discussed msg object
// msg object is global - no declaration needed.
/*
//1
When contract created we need to get manager(contract creator) details.

//2 Whenever we write a function that expects to receive/send ether the function must be marked as payable. 

    //2.1 require - used for validation - Also global object like msg
            can pass in bool. if bool false then entire function
                immediately exited & no changes made to contract
                
                if true - code in contract runs as usual
    //2.2 side note* msg object is how we get access to transaction created by function            
            .value will get money sent - returns 
                val in wei (1eth * 18)
                
//3 Sha3 is global varialbe/function
    3.1 keccak256 === Sha3 => returns hash
        uint infront of Sha3 converts to uint
    3.2 block is global var 
        - Difficulty will be number. Indicates how challenging it will be to
            solve current block
            Now is current time - also global var
            
//4 
    4.1 will return address object - object has methods attached to it
        e.g transfer
            Transfer will attempt to take money from contract and 
                in this case send to winner
                players[index].transfer(1) will send 1 wei to winner
                players[index].transfer(this.balance) - will send the 
                    balance of contract to winner. 
                    'this is a reference to the instance of the current contract '
                    
    4.2 Creates brand new dynamic array of type address.
        square next to address indicates dynamic as no numbers inside.
        (0) - Want it to have initial size of 0.
            any arbitrary number would initialize the length to that number input
                e.g 5 would = [0x0000..., 0x0000..., 0x0000..., 0x0000..., 0x0000...,]
                
    4.3 Ensure that only manager has access to pickWinner function.
    
//5 can imagine that the underscore will hold the code you add a modifier to. 
    // Anytime you see repetitive logic a modifier is a // useful tool to avoid the repetition.
        
*/
