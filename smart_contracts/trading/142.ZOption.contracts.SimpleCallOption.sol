pragma solidity ^0.5.0;

contract SimpleCallOption {
    address payable owner;
    address public callOptionWriter; 
    address public callOptionBuyer;
    uint8 spotPrice;
    
    constructor (address _callOptionSeller, address _callOptionBuyer) public payable {
        owner = msg.sender;
        callOptionWriter = _callOptionSeller;
        callOptionBuyer = _callOptionBuyer;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender, "you don't have authority");
        _;
    }
    
    struct optionInfo{
        string assets;
        uint8 strikePrice;
        uint8 timeToMaturity;
        uint8 riskFreeRate;
        bool exercised;
    }
    
    mapping (address => optionInfo ) private option;
    optionInfo[] public optionList;
    event newOption(address addr, string assets, uint8 strikePrice, uint8 marketPrice, uint8 timeToMaturity, uint8 riskFreeRate, bool exercised);
    
    function setCurrentMarketPrice(uint8 _spotPrice) public onlyOwner returns (uint8)  {
        spotPrice = _spotPrice;
        return spotPrice;
    }
    
    function getCurrentMarketPrice() public view returns (uint8){
        return spotPrice;
    }
    
    function addOption (address _addr, string memory _assets, uint8 _strikePrice, uint8 _timeToMaturity, uint8 _riskFreeRate) public returns(address, string memory, uint8, uint8, uint8, bool, uint8){
        require(msg.sender == callOptionWriter || msg.sender == owner, "you don't have authority");
        require(spotPrice > 0, 'transaction cannot be processed, current market price is unavailable right now');
        spotPrice = getCurrentMarketPrice();
        bool exercised = false;
        option[_addr]=optionInfo(_assets, _strikePrice, _timeToMaturity, _riskFreeRate, exercised);
        optionList.push(option[_addr]);
        emit newOption(_addr, _assets, _strikePrice, spotPrice, _timeToMaturity, _riskFreeRate, exercised);
        return (_addr, _assets, _strikePrice, _timeToMaturity, _riskFreeRate, exercised, spotPrice);
    }
    //static scenario, i.e. in a scenario in which buyer knows he/she/they will or won’t exercise the option
    function CallOptionPremiumCalculator(address addr) public view returns(uint8){
        require(option[addr].timeToMaturity >= 0, 'time to maturity has to be positve');
        uint8 marketPrice = getCurrentMarketPrice();
        uint8 presentValueFactor = 1/((1+(option[addr].riskFreeRate)/100)**option[addr].timeToMaturity);
        uint8 premium = marketPrice - option[addr].strikePrice*presentValueFactor;
        return premium;
    }
    
    function payPremium(address addr) public payable returns (uint8){
        require(msg.sender == callOptionBuyer || msg.sender == owner, "you don't have authority");
        uint8 premium = CallOptionPremiumCalculator(addr);
        //owner.transfer(premium);
        return premium;
    }
    
    function tradeOptionBeforeExpiry(address addr, address newCallBuyer) public returns(bool){
        require(msg.sender == callOptionBuyer || msg.sender == owner, "you don't have authority");
        require(option[addr].timeToMaturity > 0, "it's expired");
        callOptionBuyer = newCallBuyer;
        return true;
    }
    
    
}