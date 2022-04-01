pragma solidity >=0.5.7 <0.6.0;


/// @title A simple blocktime based lottery for educational purposes
/// @author Thomas Haller <tha@lab10.coop>, Dietmar Hofer <dho@lab10.coop>
///
/// @notice
/// This contract implements a reusable lottery which can be played by sending simple transactions,
/// thus doesn't depend on the players using a specific DApp.
/// The duration of rounds and pauses in between are configured on deployment, expressed in number of blocks.
/// A new round is started by the first incoming transaction after deployment or after a pause.
/// The bid amount is constant per round and either configured for all rounds on deployment or - if not done so -
/// set per round by the transaction starting that round.
/// Once a round is over, the first following transaction triggers payout of the collected funds to the winner,
/// the winner being determined in a raffle based on a simple block hash based RNG (see inline comments).
contract EduLottery {
    // positive number indicates the block number when the current round got started.
    // negative number indicates the minimal block number at which the next round can be started (implying that the lottery is currently paused).
    int256 public roundStartBlock;

    // timeframe in blocks a round will take.
    uint256 public roundRuntimeInBlocks;

    // minimum timeframe in blocks the lottery is paused after a round.
    // During that timeframe, incoming transactions are rejected.
    uint256 public minPauseRuntimeInBlocks;

    // indicates if the bidAmount is set per round (defined by the opening tx) or not.
    bool public dynamicBidAmount;

    // the bid amount in wei to be transferred by participants of the current round.
    uint256 public bidAmount;

    // stores a list of all players who participated in the current round by transferring <bidAmount>.
    // those sending multiple transactions will be listed in this array multiple times.
    // due to gas economics, the array is not cleared between rounds, thus <nrPlayers> holds the current length.
    address payable[] public players;

    // current size of the <players> array. Is always less or equal to players.length.
    uint256 nrPlayers;


    event RoundStarted(uint256 bidAmount);
    event Bid(address player);
    // the RoundPayout event also indicates the end of a lottery round and the start of a pause period.
    event RoundPayout(address winner, uint256 amount);

    /// create a new instance EduLottery
    /// @param _bidAmount amount in wei required for bids, 0 (zero) means the bid amount is not pre-set, but set per round
    /// @param _roundRuntimeInBlocks Lottery runtime in blocks for a round.
    /// @param _minPauseRuntimeInBlocks pause time after a lottery round.
    constructor(uint256 _bidAmount, uint256 _roundRuntimeInBlocks, uint256 _minPauseRuntimeInBlocks) public {
        require(_roundRuntimeInBlocks > 0, 'roundRuntimeInBlocks must not bet null.');

        roundRuntimeInBlocks = _roundRuntimeInBlocks;
        bidAmount = _bidAmount;
        minPauseRuntimeInBlocks = _minPauseRuntimeInBlocks;
        dynamicBidAmount = (_bidAmount == 0);

        //this allows the first round to be started immediately after deployment.
        roundStartBlock = (int256)(block.number) * -1;
    }

    modifier lotteryIsNotPaused {
        require(roundStartBlock > 0 || - roundStartBlock < (int256)(block.number), 'Lottery is currently paused');
        _;
    }

    /// Fallback function handling all interaction, triggered by simple send transactions.
    /// starts a new lottery round if there is currently none running.
    /// if a round is running, it places a bid if the correct amount is provided.
    /// if a round is over, selects a winner and pays out collected funds.
    /// if paused (mininum pause timeframe after a round not reached), rejects all transactions.
    /// @notice senders need to provide enough gas. 21000 - as often set by default - will not suffice.
    function () external payable lotteryIsNotPaused {
        if(roundStartBlock < 0) {
            // a new round is started
            roundStartBlock = (int256)(block.number);
            if (dynamicBidAmount) {
                bidAmount = msg.value;
            }
            emit RoundStarted(bidAmount);
        }

        // roundStartBlock cannot be negative when getting here
        if(block.number >= uint256(roundStartBlock) + roundRuntimeInBlocks) {
            // a round is over. Pick a winner, pay out, end the round (transitioning to paused state)
            if (msg.value > 0) {
                // since the round was already over before this tx, sender funds (if any) are immediately returned
                msg.sender.transfer(msg.value);
            }
            roundStartBlock = -int256(block.number + minPauseRuntimeInBlocks);
            payout(getRandomNumber(nrPlayers));
            nrPlayers = 0;
        } else {
            // a round is running. Register the bid if the amount is correct
            require(msg.value == bidAmount, "wrong amount!");

            if(nrPlayers == players.length) {
                // array needs to grow in order to accomodate this bid, thus using push()
                players.push(msg.sender);
            } else {
                players[nrPlayers] = msg.sender;
            }
            nrPlayers++;

            emit Bid(msg.sender);
        }
    }

    /// Pays out the collected funds to the given player
    /// @param luckyPlayerIndex valid index in the players array
    /// @dev Re-entrancy issues (see https://solidity.readthedocs.io/en/latest/security-considerations.html#re-entrancy)
    /// should be avoided by the caller (should call this method after having done everything else). However even in case of
    /// re-entrancy, not much could go wrong as the winner gets all funds on first transfer anyway.
    function payout(uint256 luckyPlayerIndex) internal {
        address payable luckyPlayer = players[luckyPlayerIndex];
        uint256 amount = address(this).balance;
        luckyPlayer.transfer(amount);
        emit RoundPayout(luckyPlayer, amount);
    }

    /// get a random number.
    /// @param range upper range bound for the retrieved random number.
    /// @return a number calculated out of the last blockhash.
    /// @notice Assumption for this RNG to have any meaning: block author doesn't care about it.
    /// Context: https://ethereum.stackexchange.com/questions/191/how-can-i-securely-generate-a-random-number-in-my-smart-contract
    /// (PS: in a PoA network, it's much easier for the block author to manipulate the block hash than it is in a PoW network)
    /// Also, if nobody else triggers payout, smart players could wait for a "favourable" block...
    function getRandomNumber(uint256 range) public view returns(uint256) {
        // hash of last block is the randomness source (hash of current block not yet known at the time of execution)
        return uint256(blockhash(block.number-1)) % range;
    }
}
