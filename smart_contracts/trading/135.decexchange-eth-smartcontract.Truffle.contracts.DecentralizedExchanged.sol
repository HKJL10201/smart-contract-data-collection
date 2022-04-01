pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
//import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';

contract DecExchange {

 using SafeMath for uint;

    enum StatusType {
        BUY,
        SELL
    }

    //STRUCT SECTIONS
    struct OrderDTO {
        uint id;
        address trader;
        StatusType statusType;
        bytes32 tokenTickerName;
        uint amount;
        uint filled;
        uint price;
        uint date;
    }
    //define the Token   to be use in the contract
    struct TokenDTO {
        address tokenAddress;
        bytes32 tokenTickerName;
    }

    //MAPPING SECTION
    //create a mapping list holding the struct Token
    mapping(bytes32 => TokenDTO) public tokenMap;
     //create a mapping of trade balance
    mapping(address => mapping(bytes32 => uint)) public tradeBalanceMap;
    //crate a mapping for Trading Orders
    mapping(bytes32 => mapping(uint => OrderDTO[])) public tradingOrderBookMap; //need to be sorted based on order type

    //VARIABLES SECTIONS
    bytes32[] public tokenArray;
    //admin address
    address public admin;
    // counter for the next order id
    uint nextOrderId;
    //const for DAI token
    bytes32 constant DAI = bytes32('DAI');
    //counter for the next trade id
    uint nextTradeId;

    //events
    event NewTrade(
      uint tradeId,
      uint orderId,
      bytes32 indexed tokentickerName,
      address indexed firstTrader,
      address indexed secondtrader,
      uint amount,
      uint price,
      uint date
    );

    constructor() public {
        admin = msg.sender;
    }

    function depositTokenDTO(uint _amount, bytes32 _tokenTickerName) external validTokenName(_tokenTickerName) {
        IERC20(tokenMap[_tokenTickerName].tokenAddress).transferFrom(msg.sender, address(this), _amount);
        tradeBalanceMap[msg.sender][_tokenTickerName] = tradeBalanceMap[msg.sender][_tokenTickerName].add(_amount);
    }

    function withdrawTokenDTO(uint _amount, bytes32 _tokenTickerName) external validTokenName(_tokenTickerName){
        require(tradeBalanceMap[msg.sender][_tokenTickerName] >= _amount,"Balance is too low");
        tradeBalanceMap[msg.sender][_tokenTickerName] = tradeBalanceMap[msg.sender][_tokenTickerName].sub(_amount);
        IERC20(tokenMap[_tokenTickerName].tokenAddress).transfer(msg.sender,  _amount);
    }

    function addTokenDTO(address _tokenAddress, bytes32 _tokenTickerName) external onlyAdmin() {
        //insert to mapping
        tokenMap[_tokenTickerName] = TokenDTO(_tokenAddress, _tokenTickerName);
        //push to tokenArray the tokentickerName
        tokenArray.push(_tokenTickerName);
    }

    function addLimitOrderDTO(bytes32 _tokenTickerName,
                              uint _amount,
                              uint _price,
                              StatusType _statusType)
                              external
                              validTokenName(_tokenTickerName)
                              notBasedDAI(_tokenTickerName)
    {
        if(_statusType == StatusType.SELL) {
            require(tradeBalanceMap[msg.sender][_tokenTickerName] >= _amount,"Balance is too low");
        }
        else {
            require(tradeBalanceMap[msg.sender][DAI] >= (_amount * _price),"DAI Balance is too low");
        }

        OrderDTO[] storage orders = tradingOrderBookMap[_tokenTickerName][uint(_statusType)];
        orders.push(OrderDTO(
            nextOrderId,
            msg.sender,
            _statusType,
            _tokenTickerName,
            _amount,
            0,
            _price,
            now
        ));
                
        uint len = (orders.length > 0 ? orders.length - 1 : 0);
        while(len > 0) {
            if(_statusType == StatusType.SELL && orders[len - 1].price > orders[len].price) break;
            if(_statusType == StatusType.BUY && orders[len - 1].price < orders[len].price) break;
            OrderDTO memory order = orders[len - 1];
            orders[len - 1] = orders[len];
            orders[len] = order;
            len = len.sub(1);
        }
        nextOrderId = nextOrderId.add(1);
    }
    
    function createMarketOrderDTO(bytes32 _tokenTickerName,
                              uint _amount,
                              StatusType _statusType)
                              external
                              validTokenName(_tokenTickerName)
                              notBasedDAI(_tokenTickerName)
    {
         if(_statusType == StatusType.SELL) {
            require(tradeBalanceMap[msg.sender][_tokenTickerName] > _amount,"Balance is too low");
         }                 
         
         OrderDTO[] storage orders = tradingOrderBookMap[_tokenTickerName][uint(_statusType == StatusType.BUY ? StatusType.SELL : StatusType.BUY)];
         uint i;
         uint remaining = _amount;
         
         while(i < orders.length && remaining > 0){
             uint available = orders[i].amount.sub(orders[i].filled);
             uint matched = (remaining > available) ? available : remaining;
             remaining = remaining.sub(matched);
             orders[i].filled = orders[i].filled.add(matched);
             emit NewTrade(nextOrderId, orders[i].id,_tokenTickerName,orders[i].trader,msg.sender,matched, orders[i].price,now);
            
            uint totalmatched = matched.mul(orders[i].price);
             
             if(_statusType == StatusType.SELL) {
                  tradeBalanceMap[msg.sender][_tokenTickerName] = tradeBalanceMap[msg.sender][_tokenTickerName].sub(matched);
                  tradeBalanceMap[msg.sender][DAI] = tradeBalanceMap[msg.sender][DAI].add(totalmatched);
                  
                  tradeBalanceMap[orders[i].trader][_tokenTickerName] = tradeBalanceMap[orders[i].trader][_tokenTickerName].add(matched);
                  tradeBalanceMap[orders[i].trader][DAI] = tradeBalanceMap[orders[i].trader][DAI].sub(totalmatched);
             }
             
             if(_statusType == StatusType.BUY) {
                 require(tradeBalanceMap[msg.sender][DAI] >= matched * orders[i].price, "DAI balance too low");
                 tradeBalanceMap[msg.sender][_tokenTickerName] = tradeBalanceMap[msg.sender][_tokenTickerName].add(matched);
                 tradeBalanceMap[msg.sender][DAI] = tradeBalanceMap[msg.sender][DAI].sub(totalmatched);
                 
                 tradeBalanceMap[orders[i].trader][_tokenTickerName] = tradeBalanceMap[orders[i].trader][_tokenTickerName].sub(matched);
                 
                 tradeBalanceMap[orders[i].trader][DAI] = tradeBalanceMap[orders[i].trader][DAI].add(totalmatched);
             }
             
             nextOrderId = nextOrderId.add(1);
             i = i.add(1);
         }
         
         //sorting
         i = 0;
         while(i < orders.length && orders[i].filled == orders[i].amount) {
             for(uint j = i; j < orders.length - 1; j++) {
                 orders[j] = orders[j + 1];
             }
             orders.pop();
             i = i.add(1);
         }
         
    }

    function getOrdersDTO(
      bytes32 _tokenTickerName, 
      StatusType _statusType) 
      external 
      view
      returns(OrderDTO[] memory) {
      return tradingOrderBookMap[_tokenTickerName][uint(_statusType)];
    }

    function getTokensDTO() 
      external 
      view 
      returns(TokenDTO[] memory) {
      TokenDTO[] memory _tokens = new TokenDTO[](tokenArray.length);
      for (uint i = 0; i < tokenArray.length; i++) {
          _tokens[i] = TokenDTO(
          tokenMap[tokenArray[i]].tokenAddress,
          tokenMap[tokenArray[i]].tokenTickerName
        );
      }
      return _tokens;
    }
    
    //modifiers
    modifier onlyAdmin() {
        require(admin == msg.sender , "Only Administrator can use this feature");
        _;
    }
    
       //should not transact with DAI based tokenMap
    modifier notBasedDAI(bytes32 _tokenTickerName) {
        require(_tokenTickerName != DAI, "DAI cant be traded");
        _;
    }
    
    modifier validTokenName(bytes32 _tokenTickerName) {
        require(tokenMap[_tokenTickerName].tokenAddress != address(0), "not a valid token");
        _;
    }
}