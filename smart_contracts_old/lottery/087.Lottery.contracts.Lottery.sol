pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] players;
    uint fee = .001 ether;
    
    modifier onlyOwner() {
        require(msg.sender == manager);    
        _;
    }
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(fee <= msg.value);
        
        // /// @dev Return any change owned.
        // if (fee < msg.value) {
        //     msg.sender.transfer(msg.value-fee);
        // }

        players.push(msg.sender);
    }
    
    function getTotalPlayers() public view returns (uint) {
        return players.length;
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyOwner {
        uint index = random() % players.length;
        /// @dev .transfer will attempt to take some amount of money frmo the current contract and send it.
        players[index].transfer(this.balance);
        /// @dev Create a new dynamic array with an initial size of 0.
        players = new address[](0);
        /// @dev players = [0, 0, 0, 0, 0]
        // players = new address[](5);
    }
    
    function getPlayers() external view onlyOwner returns (address[]){
        return players;
    }
}

/// @notes 10 % 3 = 1