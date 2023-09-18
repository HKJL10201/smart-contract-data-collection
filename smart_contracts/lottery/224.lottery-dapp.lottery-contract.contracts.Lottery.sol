pragma solidity ^0.4.23;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
      // 同じ人が何度も参加できないようにしましょう
        for (uint i=0; i<players.length; i++) {
            require(msg.sender != players[i]);
        }
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    // コントラクト作成者にしか呼び出せないようにしよう
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    }
    
    // コントラクト作成者にしか呼び出せない修飾子を作ろう
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
    
    function getLotteryBalance() public view returns (uint) {
        return address(this).balance;
    }
}