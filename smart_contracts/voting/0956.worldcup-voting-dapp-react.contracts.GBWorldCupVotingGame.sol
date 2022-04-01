pragma solidity ^0.4.2;
// Specify compiler version we are using.
// Note: this code is written using the latest solidity best practices,
// for example using 'constructor(){}' rather than 'function GBWorldCupVotingGame(){}'
// and using string return values for require() statements

contract GBWorldCupVotingGame {
    
    /* CONTRACT STATE VARIABLES */
    
    // State machine for this voting game,
    // tracking which state of gameplay we are in.
    enum GameState { 
        AcceptingVotes,
        WinnerDeclared,
        PayoutsCompleted
    }
    
    // A vote object tracks the address of the account that voted
    // and the Ether backing the account staked against the vote (denominated in wei)
    struct Vote {
        address voter;
        uint voteBackingInWei;
    }
    
    // keep track of total Ether backing for each team (denominated in wei)
    mapping (bytes32 => uint) teamBackingInWei;
    
    // keep track of Votes for each team, so that payouts can be computed in the future
    mapping (bytes32 => Vote[]) teamVotes;
    
    uint16 totalNumVotes;
    uint totalVoteBacking;
    
    // We include the 'private' here just for educational purposes.
    // The use of 'private' does not hide the value of the variable.
    // Contract data storage (on EtherScan, e.g.) would still reveal value of 'currentState'.
    // It simply prevents solidity from making an automatic getter function for it
    GameState private currentState; 
    GameState private constant INITIAL_STATE = GameState.AcceptingVotes;
    
    // The ONLY address that is allowed to declare game outcome
    // and restart game
    address public gameReferee;
    
    // Solidity doesn't let you pass in an array of strings in the constructor (yet).
    // We will use an array of bytes32 instead to store the list of teams
    // available for voting.
    bytes32[] public teamNames;

    // stores name of team that won the last round of the game, if any
    bytes32 public lastWinningTeam;
  
    // max value = 255
    uint8 private gameIterationCounter;
    
    /* CUSTOM FUNCTION MODIFIERS */
    
    modifier forRefereeOnly() {
        require(msg.sender == gameReferee);
        _;
    }
    
    modifier inState(GameState _state) {
        require(currentState == _state);
        _;
    }
    
    /* EVENTS */
    event GameStarted(uint8 gameIteration, address referee);
    event WinningTeamDeclared(uint8 gameIteration, bytes32 winningTeam);
    event YouAreAWinner(uint8 gameIteration, address indexed winnerAddress, uint amountWon);
    event PayoutsCompleted(uint8 gameIteration, uint16 numWinners, uint totalWeiDistributed);
    event NewVote(uint8 gameIteration, address indexed voter, bytes32 teamName, uint voteBacking);
    
    event TeamStateUpdate(uint8 gameIteration, bytes32 teamName, uint16 votesForThisTeam, uint backingForThisTeam);
    event GameStateUpdate(uint8 gameIteration, uint16 totalVotesInGame, uint totalBackingInGame);
    
    /* CONSTRUCTOR */
    constructor(bytes32[] _teamNames) public {
        
        // This is the FIRST time the game is being played.
        // subsequent iterations of the game will not require constructor to be called
        gameIterationCounter = 1;
        
        // start out in the "accepting votes" state
        currentState = INITIAL_STATE;
        
        // store a reference to this list of team names
        // we'll be using it elsewhere in the contract
        teamNames = _teamNames;
        
        // assign the role of referee to the creator of this contract
        gameReferee = msg.sender;
        
        // go through each team name
        for (uint i = 0; i < teamNames.length; i++) {
            
            // and initialize backing for all teams to zero.
            // we'll increment this later as votes come in
            teamBackingInWei[teamNames[i]] = 0;
        }
        
        emit GameStarted(gameIterationCounter, gameReferee);
    }
    
    /* FUNCTIONS (TRANSACTIONS) 
     * 
     * These change the state of our system,
     * and take time to return.
     */
    
    function voteForTeam(bytes32 _teamName) public payable inState(GameState.AcceptingVotes) {
        
        require(validTeamName(_teamName), "invalid team name");
        
        uint _voteBackingInWei = msg.value;
        address _voter = msg.sender;
        
        teamBackingInWei[_teamName] += _voteBackingInWei;
        teamVotes[_teamName].push(Vote({
            voter: _voter,
            voteBackingInWei: _voteBackingInWei
        }));
        
        totalNumVotes += 1;
        totalVoteBacking += _voteBackingInWei;
    
        emit NewVote(gameIterationCounter, _voter, _teamName, _voteBackingInWei);
        emit TeamStateUpdate(gameIterationCounter, _teamName, uint16(teamVotes[_teamName].length), teamBackingInWei[_teamName]);
        emit GameStateUpdate(gameIterationCounter, totalNumVotes, totalVoteBacking);

    }
    
    // can only restart game once payouts are completed
    function restartGame() public forRefereeOnly() inState(GameState.PayoutsCompleted) {
        
        // pro-actively handle overflow
        if (gameIterationCounter == 255)
            gameIterationCounter = 0;
        else
            gameIterationCounter += 1;

        totalNumVotes = 0;
        totalVoteBacking = 0;

        // this should recover some gas
        for(uint i = 0; i < teamNames.length; i++) {
            delete teamBackingInWei[teamNames[i]];
            delete teamVotes[teamNames[i]];
        }

        // reset state
        currentState = GameState.AcceptingVotes;

        emit GameStarted(gameIterationCounter, gameReferee);
    }

    function declareWinner(bytes32 winningTeam) public forRefereeOnly() inState(GameState.AcceptingVotes) {

        require(validTeamName(winningTeam), "nonexistent team selected as winner");

        //update contract state
        currentState = GameState.WinnerDeclared;
        lastWinningTeam = winningTeam;

        //log event
        emit WinningTeamDeclared(gameIterationCounter, winningTeam);

        //call internal function to pay out winners
        _doPayouts(winningTeam);
    }
    
    // "private" means this function is only visible to this contract.
    // can only be called from within this contract
    function _doPayouts(bytes32 winningTeam) private inState(GameState.WinnerDeclared) {
        
        // money to be split
        uint totalWeiToBeSplit = address(this).balance;

        // identify winning Votes.
        // note: arrays and structs are stored in 'storage' 
        // rather than memory eventhough they're local vars
        Vote[] storage winningVotes = teamVotes[winningTeam];

        // PAYOUT ALGORITHM:
        //
        // Voters who voted for the winning team split the pool of ether
        // staked by all voters (including losers).
        //
        // The fraction of the overall pool that each correct voter receives
        // is equal to:
        //
        // Voter's individual backing for the winning team / total backing for the winning team

        // identify total Wei backing for this winning team
        uint totalBackingForWinningTeam = teamBackingInWei[winningTeam];

        // identify each voter's payout as a fraction of overall backing pool
        for(uint i = 0; i < winningVotes.length; i++) {
            
            // WHO
            address winningVoter = winningVotes[i].voter;
            
            // HOW MUCH HE OR SHE PUT IN
            uint winningVotersBacking = winningVotes[i].voteBackingInWei;

            // PAYOUT = WINNING FRACTION * TOTAL TO BE SPLIT
            // 
            // NOTE: the 'fixed' datatype (a.k.a float or double in other languages) is 
            // not yet fully supported in solidity so rather than
            // separately calculating winning fraction and then multiplying
            // total by fraction, we re-order the math to avoid truncation. 
            //
            // 'amountWon' will still be truncated to an integer value but because it's denominated
            // in Wei, the trunctation error is miniscule as a fraction of the voter's backing
            uint amountWon = winningVotersBacking * totalWeiToBeSplit / totalBackingForWinningTeam;

            // send the money
            winningVoter.transfer(amountWon);

            // log that we sent the money to this winner
            emit YouAreAWinner(gameIterationCounter, winningVoter, amountWon);
        }

        //finally, update state 
        currentState = GameState.PayoutsCompleted;

        // log that payouts were completed so that listening web3 clients
        // can update their UI state
        emit PayoutsCompleted(gameIterationCounter, uint16(winningVotes.length), totalWeiToBeSplit);
    }
    
    /* FUNCTIONS (CALLS) 
     * 
     * These do not change the state of our system,
     * and return immediately.
     */

    function getGameIteration() public view returns (uint8){
        return gameIterationCounter;
    }

    function getCurrentState() public view returns (GameState) {
        return currentState;
    }

    function getRefereeAddress() public view returns (address) {
        return gameReferee;
    }

    function getTeamNames() public view returns (bytes32[]) {
        return teamNames;
    }

    function getTeamCount() public view returns (uint) {
        return teamNames.length;
    }
    
    function getTotalVoteCount() public view returns (uint16) {
        return totalNumVotes;
    }
    
    function getTotalVoteBackingInWei() public view returns (uint) {
        return totalVoteBacking;
    }
    
    function getVoteCountForTeam(bytes32 _teamName) public view returns (uint16) {
        require(validTeamName(_teamName), "invalid team name");
        
        return uint16(teamVotes[_teamName].length);
    } 
    
    function getVoteBackingInWeiForTeam(bytes32 _teamName) public view returns (uint) {
        require(validTeamName(_teamName), "invalid team name");
        
        return teamBackingInWei[_teamName];
    }

    // this should return the same value as getTotalVoteBackingInWei().
    // we create it for testing purposes
    // and use in our truffle scripts for educational purposes
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getLastWinner() public view returns (bytes32) {
        return lastWinningTeam;
    }
    
    function validTeamName(bytes32 _teamName) public view returns (bool) {
        for(uint i = 0; i < teamNames.length; i++) {
            if (teamNames[i] == _teamName) {
                return true;
            }
        }
        return false;
    }
}