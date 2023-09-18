pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//import "./mint.sol";
import "./formulas.sol";
import "./safemath.sol";
import "./interface.sol";
//import "./helpers/PredicateHelper.sol";
    contract orderss
    {
         using SafeMath for uint256;
        
  //  event Transfer(address indexed from, address indexed to, uint value);
//    event Approval(address indexed owner, address indexed spender, uint value);
        event makerAssetData(address sender, address tokenBuy,uint amount);
        event takerAssetData(address tokenSold, address tokenBuy, uint amount);
        bool success;
        bool error;
            AggregatorV3Interface internal priceFeed;
      
        
    IERC20 public token1;
    address public owner1;
    uint public amount1;
    IERC20 public token2;
    address public owner2;
    uint public amount2;

    constructor (
        address _token1,
        address _owner1,
        uint _amount1,
        address _token2,
        address _owner2,
        uint _amount2
    )public {
        token1 = IERC20(_token1);
        owner1 = _owner1;
        amount1 = _amount1;
        token2 = IERC20(_token2);
        owner2 = _owner2;
        amount2 = _amount2;
        priceFeed = AggregatorV3Interface(_token2);
    }
        
        struct order{
            uint salt;
           address token1; //eth
           address token2; //eth into BUSD when target
             //transterfrom, signer,____,  amount
            // transferto, sender, signer, amount
            uint getMakerAmount;// 
            uint getTakerAmount;
            bytes predicate;
            bytes permit;
            bytes interaction;
        } //this struct will be used to track the nessicary info to buy and swap assets
        
      
        function fillOrder(
            uint _salt,
            address _token1,
            address _token2,
            uint _getMakerAmount,
            uint _getTakerAmount,
            bytes memory _predicate,
            bytes memory _permit,
            bytes memory _interaction
            )public payable returns(bool){
            //fill order struct
            success= true;
            error = false;
           
            //getLatestPriceForToken1.call(token1);
            order memory neworder = order(
                _salt,
                _token1,
                _token2,
                _getMakerAmount, //find out about staticcal  
                _getTakerAmount, // check with staticcall
                _predicate, // GET THE .CALL predicate
                _permit,
                _interaction
                );
        
         //msg.sender.call{value: getLatestPriceForToken2}("");
        //return (token2price);
         emit makerAssetData(msg.sender, owner2, _getMakerAmount);
      
        return (true);
        }


      function AskToBuy(
        uint index,
        IERC20 token,
        address sender,
        address recipient,
        uint amount
                ) public returns  (bool) {
     uint token2Price;
    token2Price = 1;
     //mainnet BUSD/USD 0xcBb98864Ef56E9042e7d2efef76141f15731B82f
    /**
     * Network: MainNet
     * Aggregator: BUSD/USD
     * Address: 0xcBb98864Ef56E9042e7d2efef76141f15731B82f
     */
    /*
     * Returns the latest price
     */
        (
            uint80 roundID, 
            int token2price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
 
        require(token1 != token2, "You cannot sell the token you are buying");
      //require(token2price<=allowbuy)

        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");

        return(true);
        
        
    }
        
function AskToSell(
  uint index,
               IERC20 token,
        address sender,
        address recipient,
        uint amount
)public returns (bool){
    uint token2Price;
    token2Price = 1;
    int allowsell;
    uint allowbuy;
    allowsell = 9990;
               //mainnet BUSD/USD 0xcBb98864Ef56E9042e7d2efef76141f15731B82f
    /**
     * Network: MainNet
     * Aggregator: BUSD/USD
     * Address: 0xcBb98864Ef56E9042e7d2efef76141f15731B82f
     */
    /*
     * Returns the latest price
     */
        (
            uint80 roundID, 
            int token2price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        token2price * 10**4;
        require(token1 != token2, "You cannot sell the token you are buying");
        if(token2price >= allowsell){
        
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
        return(true);  
        }
      }
        
        
        
        
        
    }
