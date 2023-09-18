pragma solidity ^0.8.0;
import "./erc20.sol";


contract Ico {

    uint256 public maxMintable;
    uint256 public totalMinted;
    uint public endDate;
    uint public startDate;
    uint public exchangeRate;
    bool public isFunding;
    ERC20 public Token;
    address public ETHWallet;
    uint256 public heldTotal;

    bool private configSet;
    address public creator;

    mapping (address => uint256) public heldTokens;
    mapping (address => uint) public heldTimeline;

    event Contribution(address from, uint256 amount);
    event ReleaseTokens(address from, uint256 amount);

    constructor (uint _startDate, uint _maxMintable, uint _exchangeRate) {
        startDate = _startDate;
        maxMintable = _maxMintable;
        ETHWallet = msg.sender;
        isFunding = true;
        creator = msg.sender;
        exchangeRate = _exchangeRate;
    }

    // setup function to be ran only 1 time
    // setup token address
    // setup end Block number
    function setup(address token_address, uint _endDate) public {
        require(msg.sender == creator, "You are not allowed.");
        require(!configSet);
        Token = ERC20(token_address);
        endDate = _endDate;
        configSet = true;
    }

    function closeSale() external {
      require(msg.sender==creator);
      isFunding = false;
    }

    function buy() public payable {
        require(msg.value>0);
        require(isFunding);
        require(block.timestamp <= endDate);
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += total;
        payable(ETHWallet).transfer(msg.value);
        Token._mint(msg.sender, amount);
        emit Contribution(msg.sender, amount);
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable {
        require(msg.value>0);
        require(isFunding);
        require(block.timestamp <= endDate);
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += total;
        payable(ETHWallet).transfer(msg.value);
        Token._mint(msg.sender, amount);
        emit Contribution(msg.sender, amount);
    }

    // update the ETH/COIN rate
    function updateRate(uint256 _rate) external {
        require(msg.sender==creator);
        require(isFunding);
        exchangeRate = _rate;
    }



    // public function to get the amount of tokens held for an address
    function getHeldCoin(address _address) public view returns (uint256) {
        return heldTokens[_address];
    }

    // function to create held tokens for developer
    function createHoldToken(address _to, uint256 amount) internal {
        heldTokens[_to] = amount;
        heldTimeline[_to] = block.number + 0;
        heldTotal += amount;
        totalMinted += heldTotal;
    }

    // function to release held tokens for developers
    function releaseHeldCoins() external {
        uint256 held = heldTokens[msg.sender];
        uint heldBlock = heldTimeline[msg.sender];
        require(!isFunding);
        require(held >= 0);
        require(block.number >= heldBlock);
        heldTokens[msg.sender] = 0;
        heldTimeline[msg.sender] = 0;
        Token._mint(msg.sender, held);
        emit ReleaseTokens(msg.sender, held);
    }


}