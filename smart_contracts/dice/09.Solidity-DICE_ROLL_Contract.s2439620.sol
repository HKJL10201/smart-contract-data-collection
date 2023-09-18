// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Dice_roll {
    struct Player {
        uint seed;                  // The random seed that play chooses
        bool isCommitted; 			// Status of commitment
        bool isRevealed;            // Status of reveal
        bytes32 commitment;         // The commitment value
        address addr;               // The address of current player
    }
    
    // Hardcoded value
    uint private MIN_STAKE = 3 ether;           // Minimum value to join the game
    uint private ENTRANCE_FEE = 1 ether;        // Be used to penalize player who don't reveal the value
    uint private TIME_LIMIT = 30 seconds;       // Prevents DoS
    address private ContractOwner = 0x84aba9B1eC60e01b360EF890E18a4bBb9Ef2a291;

    // Global state for gaming
    uint private BothCommitTime;
    bool private isTiming = false;
    Player[2] private players;
    mapping(address => uint256) private balance;

    event Deposit(address customer, string message);
    event Withdrawal(address customer);
   
    function commit(bytes32 hash_value) public {
        require(isTimeOut(), "Sorry, no extra place in the game!");
        require(players[0].addr != msg.sender && players[1].addr != msg.sender, "Not allow to commit twice!");
        require(balance[msg.sender] >= MIN_STAKE + ENTRANCE_FEE, "Please ensure to have enough balance to start the game!");

        uint32 playerNo = 2;
        if (players[0].isCommitted == false)
            playerNo = 0;
        else
            playerNo = 1;

        require(PayEntranceFee(msg.sender), "Please ensure to have enough balance to pay the entrance fee!");
        players[playerNo].addr = msg.sender;
        players[playerNo].isCommitted = true;
        players[playerNo].commitment = hash_value;

        // Start timing
        if(players[0].isCommitted == true && players[1].isCommitted == true){
            isTiming = true;
            BothCommitTime = block.timestamp;
        }
    }
    
    function reveal(uint value) public{
        require(players[0].isCommitted == true && players[1].isCommitted == true, 
        "Please wait for another player to commit");

        // Check if user is in the game
        uint playerNo = 2;
        if (players[0].addr == msg.sender)
            playerNo = 0;
        else if (players[1].addr == msg.sender)
            playerNo = 1;
        else
            revert("Sorry, please wait for the next round to join");

        require(players[playerNo].isRevealed == false, "Repeated reveal is not allowed!");
        
        // Verify the if c == hash(v)
        if(computeHash(value) == players[playerNo].commitment){
            players[playerNo].seed = value;
            players[playerNo].isRevealed = true;
            refundEntranceFee(msg.sender);
        }
        else
            revert("Please don't change your mind!");
        
        // If both player have revealed, evaluate the game
        if (players[0].isRevealed == true && players[1].isRevealed == true){
            outcome();
        }
    }
    
    // Normal situation: Both player reveal their number
    function outcome() private {
        address winner;
        address loser;
        uint result = pseudorandomDice(players[0].seed, players[1].seed);
        
        if(result <= 3 ether){
            winner = players[0].addr;
            loser = players[1].addr;
        }else{
            winner = players[1].addr;
            loser = players[0].addr;
            result -= 3 ether;
        }

        uint stake = WeiToETH(result);
        settle(winner, loser, stake);
    }

     // Hendling situations that if either side of player refuse to reveal its number
    function isTimeOut() public returns(bool) {
        if(isTiming) {
            if(block.timestamp - BothCommitTime < TIME_LIMIT)
                return false;
            else{
                if(players[0].isRevealed == true && players[1].isRevealed == false)
                    settle(players[0].addr, players[1].addr, MIN_STAKE);
                else if(players[1].isRevealed == true && players[0].isRevealed == false)
                    settle(players[1].addr, players[0].addr, MIN_STAKE);
                
                isTiming = false;
                return true;
            }
        }
        return true;
    }

    // Handling the internal ether transference
    function settle(address winner, address loser, uint stake) private{
        balance[winner] += stake;
        balance[loser] -= stake;

        reset(0);
        reset(1);
    }
    
    // Reset the status of both players
    function reset(uint playerNo) private{
        delete players[playerNo];
        players[playerNo].seed = 0;
        players[playerNo].isCommitted = false;
        players[playerNo].isRevealed = false;
        players[playerNo].commitment = 0;
    }

    function PayEntranceFee(address player) private returns(bool)  {
        if(balance[player] < ENTRANCE_FEE)
            return false;
        balance[player] -= ENTRANCE_FEE;
        balance[ContractOwner] += ENTRANCE_FEE;
        return true;
    }

    function refundEntranceFee(address player) private returns(bool) {
        if(balance[ContractOwner] < ENTRANCE_FEE)
            return false;
        balance[ContractOwner] -= ENTRANCE_FEE;
        balance[player] += ENTRANCE_FEE;
        return true;
    }

    // Deposit money
    function deposit(string memory message) public payable {
        require(msg.value >= 0);
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, message);
    }

    function withdraw(uint amount) public {
        // Restrict the withdraw event when conducting a game
        require(msg.sender != players[0].addr && msg.sender != players[1].addr, "Sorry, you are in a game!");        
        require(amount <= balance[msg.sender], "Sorry, your balance is not enough!");
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender);
    }
    
    function computeHash(uint m) public view returns (bytes32){
        return keccak256(abi.encodePacked(msg.sender, m));
    }

    function pseudorandomDice(uint num1, uint num2) public pure returns (uint) {
        return (num1 + num2) % 6 + 1;
    }

    function getBalance() public view returns (uint256) {
        return balance[msg.sender];
    }

    function WeiToETH(uint value) private pure returns(uint) {
        return value * 1e18;
    }

    // Tool functions to check the information of current block
    function getPreviousBlock() public view returns (bytes32){
        return blockhash(block.number-1);
    }

    function getFutureBlock() public view returns (bytes32){
        return blockhash(block.number+1);
    }

    function getBlockNum() public view returns (uint){
        return block.number;
    }

    function getBlockTimeStamp() public view returns (uint){
        return block.timestamp;
    }
}