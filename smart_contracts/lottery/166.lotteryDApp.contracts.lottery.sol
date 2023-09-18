pragma solidity ^0.6.12;

contract Lottery {
    
    struct gambler{
        uint gamblersGuess;
    }
    
    address payable[] private addressIndices;
    address payable[] private winnerIndices;
    
    mapping (address => gambler) _accounts;
    
    bool gameStatus = false;
    address payable owner;
    // uint private winningGuess;
    uint winningGuess;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        startNewLottery();
    }
    
    function startNewLottery() public onlyOwner{
        delete winnerIndices;
        require (gameStatus == false);
        gameStatus = true;
        winningGuess = uint(keccak256(abi.encodePacked(now, block.difficulty, msg.sender))) % 1000000;
    }
    
    function makeGuess(uint guess) public payable{
        require (msg.sender != owner);
        require (gameStatus == true);
        require(guess > 0);
        require(guess <= 1000000);
        require (msg.value == 1 ether);
        _accounts[msg.sender].gamblersGuess = guess;
        addressIndices.push(msg.sender);
    }
    
    function closeGame() public onlyOwner returns(bool){
        require(gameStatus == true);
        uint arrayLength = addressIndices.length;
        for (uint i = 0; i < arrayLength; i++){
            if(_accounts[addressIndices[i]].gamblersGuess == winningGuess){
                winnerIndices.push(addressIndices[i]);
            }
        }
        if (winnerIndices.length > 0){
            uint winnersCount = winnerIndices.length;
            uint balance = address(this).balance - 1000000000000000000;
            uint winnerShare = balance/winnersCount;
        for (uint i = 0; i < winnersCount ; i++) {
            winnerIndices[i].transfer(winnerShare);
        }
        }
        delete addressIndices;
        return gameStatus = false;
    }
    
    
    function getGuess() public view returns (uint) {
        return _accounts[msg.sender].gamblersGuess;
    }
    
    function getStatus() public view returns (bool ) {
        return gameStatus;
    }  
    
    function getOwner() public view returns (address ) {
        return owner;
    } 
    
    function getWinningNumber() public view returns (uint ){
        return winningGuess;
    }
    
    function getWinnersList() public view returns (address payable[] memory){
        return winnerIndices;
    }
    
    function withdrawAdminFees() public onlyOwner {
        require (gameStatus == false);
        owner.transfer(address(this).balance - 1000000000000000000);
    }
}