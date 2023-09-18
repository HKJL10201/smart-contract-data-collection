pragma solidity >=0.4.22 <0.6.0;

contract Betting {
    
    // fallback function
    function() external payable {
        revert();
    }
    
    // public state variables
    address public owner;
    address public oracle;
    address public market;
    
    string public assertion;
    uint public deadline;
    uint public oracleFee;
    uint public betAmount;
    uint public winnerEarnings;
    bool public outcome;
    
    bool public decisionMade;
    
    /*
    constructor (address _market) public {
        owner = msg.sender;
        assertion = 'The Golden State Warriors will win the 2019 NBA championship';
        oracle = 0x692a70D2e424a56D2C6C27aA97D1a86395877b3A;
        market = _market;
        deadline = 1577836800;
        oracleFee = 500;
        betAmount = 5000;
        winnerEarnings = betAmount * 2 - oracleFee;
    }
    */
    
    constructor (
        string memory _assertion,
        address _oracle,
        address _market,
        uint _deadline,
        uint _oracleFee,
        uint _betAmount
    ) public {
        owner = msg.sender;
        assertion = _assertion;
        oracle = _oracle;
        market = _market;
        deadline = _deadline;
        oracleFee = _oracleFee;
        betAmount = _betAmount;
        winnerEarnings = _betAmount * 2 - _oracleFee;
    }
  
    // mappings and modifiers
    mapping (bool => address) public bets;
    mapping (address => uint) public earnings;
    
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    
    function isOwner() public view returns(bool) {
        return msg.sender == owner;
    }
    
    modifier onlyOracle() {
        require(isOracle());
        _;
    }
    
    function isOracle() public view returns(bool) {
        return msg.sender == oracle;
    }
    
    function isMarket() public view returns(bool) {
        return msg.sender == market;
    }
    
    modifier onlyMarket() {
        require(isMarket());
        _;
    }
    
    // Bets on an outcome, first bet must be made by contract owner.
    function makeBet(bool _outcome) public payable {
        require(isOwner() || (bets[_outcome] == address(0) && bets[!_outcome] != address(0)));
        require(!isOracle());
        require(msg.value >= betAmount);
        if (msg.value > betAmount) {
            msg.sender.transfer(msg.value - betAmount);
        }
        bets[_outcome] = msg.sender;
        earnings[msg.sender] = betAmount;
    }
    
    // Oracle imputs the correct outcome
    function makeDecision(bool _outcome) public onlyOracle {
        require(now <= deadline);
        outcome = _outcome;
        decisionMade = true;
        earnings[oracle] = oracleFee;
        earnings[bets[outcome]] = winnerEarnings;
        earnings[bets[!outcome]] = 0;
    }
    
    // Check the outcome an address bet on 
    function checkBet(address _bettor) public view returns (bool) {
        require(bets[true] == _bettor || bets[false] == _bettor);
        if (bets[true] == _bettor) {
            return true;
        } else {
            return false;
        }
    }
    
    // Check earnings of an address
    function checkEarnings(address _bettor) public view returns (uint) {
        return earnings[_bettor];
    }
    
    // Withdraw ether from contract, only after decision made or deadline passed
    function withdraw() public {
        require(earnings[msg.sender] > 0);
        require(decisionMade || now > deadline);
        msg.sender.transfer(earnings[msg.sender]);
    }
    
    // Public transfer function: send own betting position to another address
    function transferBet(address _to) public {
        _transfer(msg.sender, _to);
    }
    
    // Public transfer function accessible by trusted market
    function marketTransfer(address _from, address _to) public onlyMarket {
        _transfer(_from, _to);
    } 
    
    // Private transfer function
    function _transfer(address _from, address _to) private {
        require(!decisionMade && _to != oracle);
        outcome = checkBet(_from);
        bets[outcome] = _to;
        earnings[_to] = earnings[_from];
        earnings[_from] = 0;
    }
    
}

