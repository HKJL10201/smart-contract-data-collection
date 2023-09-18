pragma solidity ^0.4.0;
contract Lottery {

    address author;
    mapping(address => uint) tokens;
    address[] winners;
    bool finished ;
    uint collected ;
    uint lucky ;

    constructor(uint _lucky) public {
        author = msg.sender;
        finished = false;
        lucky = _lucky;
        collected = 0 ;
    }

    
    function puchaseToken() public payable returns(uint) {

        require( !finished );
        require( msg.value >= 10**18 );
        
        // convert to integer 
        uint amount = msg.value/(10**18);

        tokens[msg.sender] += amount ;
        collected += amount ; 

        return tokens[msg.sender] ;
    }
    
    function getToken() public constant returns(uint) {
        return tokens[msg.sender] ;
    }
    
    function makeGuess(uint guess) public returns(uint) {

        require( !finished );
        require( tokens[msg.sender] >= 1  );
        require( guess > 0 && guess < 1000001 );
        tokens[msg.sender] -= 1;
        if( guess == lucky ){
            winners.push(msg.sender); 
            return 1;
        }
        return 0;
        
    }
    
    
    function closeGame() public {

        require(msg.sender == author );

        finished = true ;
    }
    
    
    function winnerAddress() public returns(address) {
        // Currently Sending 50% to author and 50% to Creator.  Can Be Modified to Divide the 50% between all winners.
        // win% = 50 / winners.length 

        require(finished == true);
        
        uint s1  = collected / 2 ;
        uint s2 = collected - s1 ;
        
        if(winners.length != 0 ){
            winners[0].transfer(s1 * 10**18);
            author.transfer(s2 * 10**18);

            return winners[0];

        }

        author.transfer( collected * 10**18  );
        
        
        
    }
    
}