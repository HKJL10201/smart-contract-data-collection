pragma solidity ^0.4.11;

contract PingOracle {   // Ping Chain Oracle Interface
    function isTrustedDataSource(address dataSourceAddress) public view returns (bool _isTrusted);
}

/**
 * @title CrankysLottery
 * @dev The CrankysLottery contract is an ETH lottery contract
 * that allows unlimited entries at the cost of 1 ETH per entry.
 * Winners are rewarded the pot.
 */
contract CrankysLottery {

  	uint private latestBlockNumber;
    bytes32 private cumulativeHash;
    address[] private bets;
    mapping(address => uint256) winners;
    address PING_ORACLE_ADDRESS = address(0x6D0F7D4A214BF9a9F59Dd946B0211B45f6661dd4);
    PingOracle PING_ORACLE;

    function CrankysLottery() public {
	    latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
        PING_ORACLE = PingOracle(PING_ORACLE_ADDRESS);
    }

    modifier pingchainOnly() {
        bool _isTrusted = PING_ORACLE.isTrustedDataSource(msg.sender);
        require(_isTrusted);
        _;
    }

  	event LogCallback(bytes32 _triggerId, uint256 _triggerTimestamp, uint256 _triggerBlockNumber);

    function placeBet() public payable returns (bool) {
        uint _wei = msg.value;
        assert(_wei == 1000000000000000000);
        cumulativeHash = keccak256(block.blockhash(latestBlockNumber), cumulativeHash);
        latestBlockNumber = block.number;
        bets.push(msg.sender);
        return true;
    }

    function drawWinner() internal returns (address) {
        assert(bets.length > 4);
        latestBlockNumber = block.number;
        bytes32 _finalHash = keccak256(block.blockhash(latestBlockNumber-1), cumulativeHash);
        uint256 _randomInt = uint256(_finalHash) % bets.length;
        address _winner = bets[_randomInt];
        winners[_winner] = 1000000000000000000 * bets.length;
        cumulativeHash = bytes32(0);
        delete bets;
        return _winner;
    }

    function withdraw() public returns (bool) {
        uint256 amount = winners[msg.sender];
        winners[msg.sender] = 0;
        if (msg.sender.send(amount)) {
            return true;
        } else {
            winners[msg.sender] = amount;
            return false;
        }
    }

    function pingchainTriggerCallback(bytes32 _triggerId, uint256 _triggerTimestamp, uint256 _triggerBlockNumber) public pingchainOnly returns (bool)
    {
        drawWinner();
        LogCallback(_triggerId, _triggerTimestamp, _triggerBlockNumber);
        return true;
    }

    function getBet(uint256 betNumber) public view returns (address) {
        return bets[betNumber];
    }

    function getNumberOfBets() public view returns (uint256) {
        return bets.length;
    }
}

