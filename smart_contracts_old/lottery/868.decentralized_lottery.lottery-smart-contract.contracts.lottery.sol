pragma solidity ^0.4.17;

/**
 * @title Lottery
 * This project aims to provide a lottery
 * smart contract that accepts Ether into its prize pool.
 * It would also store the list of entrants into the lottery.
 * The contract would assign a manager that would then
 * be able to call the function that would randomly
 * select a winner to whom the prize pool would be awarded to.
 */
contract Lottery {
    
    /**
     * Address of person who created the
     * contract and who would be able to
     * tell the contract to randomly
     * select a winner.
     */
    address public manager;
    
    // Array storing all of the addresses
    // of entrants into the lottery.
    address[] public players;
    
    /**
     * @dev Guarantees msg.sender is the same
     * address that is stored under
     * the manager variable.
     */
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    /**
     * @dev The constructor function that
     * sets the msg.sender as the value for
     * the previously declared manager variable.
     */
    function Lottery() public {
        manager = msg.sender;
    }
    
    /**
     * @dev Function that accepts a minimum of 0.01 ether
     * to enter the lottery which would then add the
     * address of the bidder into the 'players' array
     */
    function enter() public payable {
        require(msg.value > .01 ether);
        
        players.push(msg.sender);
    }
    
    /**
     * @dev Function that generates a pseudo-random uint
     * out of the current block difficulty, currenty time,
     * and addresses of players and then passes it into
     * the SHA3 algorithm.
     * @return pseudo-random uint
     */
    function random() private view returns(uint) {
        return uint(sha3(block.difficulty, now, players));
    }
    
    /**
     * @dev Function that can only be called by the
     * address saved under the manager variable
     * that then randomly selects a winner and
     * sends them the prize pool.
     * The function then clears out the players array
     * so that it may be reused.
     */
    function pickWinner() public onlyManager {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    /**
     * @dev Function that when called returns all of the
     * current addresses stored under the 'players' array
     * @return array of addresses
     */
    function getPlayers() public view returns(address[]) {
        return players;
    }
}