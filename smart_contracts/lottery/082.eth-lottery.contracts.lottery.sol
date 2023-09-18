pragma solidity ^0.4.0;

contract Lottery
{
    address Owner;
    address winner;
    bool private closed = false;
    
    modifier onlyowner()
    {
        if(msg.sender == Owner)
        {
            _;
        }
        else
        {
            throw;
        }
       
    }
    
    modifier onlyuser()
    {
        if(msg.sender != Owner)
        {
            _;
        }
        else
        {
            throw;
        }
       
    }
    
    modifier closedOrNot()
    {
        if(closed != true)
        {
            _;
        }
        else
        {
            throw;
        }
    }
    
    modifier onlywinner()
    {
        if(msg.sender == winner)
        {
            _;
        }
        else
        {
            throw;
        }
    }
    
    mapping(address => uint256) TokenBalances;
    mapping(bytes32 => address) UserGuesses;
    
    bytes32 private winN;
    
    function Lottery(uint winningNumber)
    {
        if(winningNumber >= 1 && winningNumber <= 1000000)
        {
            Owner = msg.sender;
            TokenBalances[Owner] = 1000000;
        
            winN = keccak256(winningNumber);
        }
        else
        {
            throw;
        }
    }
    
    
    function requestToken() payable onlyuser closedOrNot
    {
        uint value = msg.value;
        
        uint ethAmount = value/ 1 ether;
        
        if(TokenBalances[Owner] >= ethAmount)
        {
            TokenBalances[Owner] -= ethAmount;
            TokenBalances[msg.sender] += ethAmount;
            
            if((value % 1 ether) != 0)
            {
               msg.sender.transfer(value % 1 ether);
            }
            
        }
      
    }
    
    function makeGuess(uint guess) payable closedOrNot
    {
        if(guess >= 1 && guess <= 1000000)
        {
            if(TokenBalances[msg.sender] > 0)
            {
                TokenBalances[msg.sender] -= 1;
                UserGuesses[keccak256(guess)] = msg.sender;
            }
        }
        else
        {
            throw;
        }
    }
    
    function closeGame() public payable onlyowner
    {
        closed = true;
        winner = UserGuesses[winN];
        
        if(winner == 0x0000000000000000000000000000000000000000)
        {
            // if there is no winner, Owner will take call the ethers in the contract
            Owner.transfer(this.balance);
        }
        
    }
    
    function winnerAddress() constant returns (address winnerA)
    {
        return winner;
    }
    
    function getPrice() payable onlywinner
    {
        if(closed == true)
        {
            uint halfTheReward = this.balance / 2;
            
            winner.transfer(halfTheReward);
            Owner.transfer(halfTheReward);
        }
        else
        {
            throw;
        }
    }
    
    function () payable
    {
        // fallback function
    }
}