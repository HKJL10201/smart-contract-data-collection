
pragma solidity ^0.6.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract DecentralizedExchange {
    
    using SafeMath for uint256;
    
    address public admin;
    address public contractAddress;
    IERC20 private liquidityCurrency0;
    IERC20 private liquidityCurrency1;
    mapping (address => uint) public liquidityPool;
    mapping (address => uint) public userPool;
    
    address[][] private userTokenAddress;
    
    // Events
    event LiquidityAdded(address userAddress, address tokenAddress, uint amount);
    event LiquiditySwaped(address userAddress, address token0Address, address token1Address, uint amount0, uint amount1);
    event LiquidityRemoved(address userAddress, address tokenAddress, uint amount);
    
    struct UserPoolExchange{
        address userAddress;
        address tokenAddress;
        uint amount;
    }
    
    UserPoolExchange[] public poolExchange;
    
    mapping(address => UserPoolExchange[]) public poolMapping;
    mapping(address => mapping (address => uint256)) public userTokenAmountMap;
    mapping(address => address[]) public userTokenMap;
    mapping(address => address[]) public tokenUserMap;

    constructor() public {
        admin  = msg.sender;
        contractAddress = address(this);
    }
    
    modifier shouldBeAdmin {
        if (msg.sender != admin)
            revert();
        _;
    }
    
    modifier onlyContractAccess(){
        require(contractAddress == address(this));
        _;
    }
    
    function addLiquidity(address _accountAddress, address _tokenAddress, uint _amount) public {
        liquidityPool[_tokenAddress] = liquidityPool[_tokenAddress].add(_amount);
        liquidityCurrency0 = IERC20(_tokenAddress);
        liquidityCurrency0.transferFrom(_accountAddress, address(this), _amount);
        if (userTokenAmountMap[_accountAddress][_tokenAddress] <= 0) {
            userTokenAddress.push([_tokenAddress, _accountAddress]);
            tokenUserMap[_tokenAddress].push(_accountAddress);
            poolExchange.push(UserPoolExchange({userAddress: _accountAddress, tokenAddress: _tokenAddress, amount: _amount}));
            userTokenMap[_accountAddress].push(_tokenAddress);
        }
        userTokenAmountMap[_accountAddress][_tokenAddress]  = userTokenAmountMap[_accountAddress][_tokenAddress].add(_amount);
        emit LiquidityAdded(_accountAddress, _tokenAddress, _amount);
    }
    
           
    function _addUserPool(address _tokenAddress, uint _amount, address _accountAddress) private {

    }

    function removeLiquidity(address _tokenAddress, uint _amount) public {
        require(_amount > 0, "Cannot remove 0");
        uint totalUserPool = userTokenAmountMap[msg.sender][_tokenAddress];
        require(totalUserPool >= _amount, "Insufficient Liquidity");
        totalUserPool = totalUserPool.sub(_amount);
        liquidityCurrency0 = IERC20(_tokenAddress);
        userPool[msg.sender] = totalUserPool;
        liquidityCurrency0.approve(address(this), _amount);
        liquidityCurrency0.transfer(msg.sender, _amount);
        emit LiquidityRemoved(msg.sender, _tokenAddress, _amount);
    }
    
    function swapLiquidity(address _srcCurrency, address _destCurrency, address _accountAddress, uint _amount0, uint _amount1) public {
        require(_amount0 > 0, "Cannot Liquidate 0");
        uint totalSupply = liquidityPool[_destCurrency];
        require(totalSupply >= _amount0, "Insufficient Liquidity Supply");
        liquidityCurrency0 = IERC20(_srcCurrency);
        liquidityCurrency0.approve(address(this), _amount0);
        liquidityCurrency0.transferFrom(_accountAddress, address(this), _amount0);
        liquidityCurrency1 = IERC20(_destCurrency);
        liquidityCurrency1.transfer(_accountAddress, _amount1);
        totalSupply = totalSupply.sub(_amount1);
        liquidityPool[_destCurrency] = totalSupply;
        updatePool(_srcCurrency, _destCurrency, _accountAddress, _amount0, _amount1, totalSupply);
        emit LiquiditySwaped(msg.sender, _srcCurrency, _destCurrency, _amount0, _amount1);
        
    }
    
    function updatePool(address _srcCurrency, address _destCurrency, address _accountAddress, uint _amount0, uint _amount1, uint totalSupply) internal {
        for (uint i = 0; i < poolExchange.length; i++) {
            uint totalUserPool = userTokenAmountMap[_accountAddress][_srcCurrency];
            uint poolPercentage = (totalUserPool/totalSupply);
            uint poolPercentage0 = _amount0*poolPercentage;
            uint poolPercentage1 = _amount1*poolPercentage;
            userTokenAmountMap[_accountAddress][_destCurrency] = userTokenAmountMap[_accountAddress][_srcCurrency].sub(poolPercentage0);
            userTokenAmountMap[_accountAddress][_srcCurrency] = userTokenAmountMap[_accountAddress][_destCurrency].add(poolPercentage1);
        }
    }
    
    function getTokenList(uint id) public view returns (address[] memory) {
        return userTokenAddress[id];
    }
    
    function getLiquidityAmount(address _tokenAddress, address _accountAddress) public view returns (uint) {
            return userTokenAmountMap[_accountAddress][_tokenAddress];
    }
    
    function getUserTokenMapping(address _accountAddress) public view returns (address[] memory){
        return userTokenMap[_accountAddress];
    }
    
    function getTokenUserMapping(address _tokenAddress) public view returns (address[] memory){
        for (uint i = 0; i < tokenUserMap[_tokenAddress].length; i++){
           return tokenUserMap[_tokenAddress];
        }
    }
    
    function totalLiquidityPool(address _tokenAddress) public view returns (uint){
        return liquidityPool[_tokenAddress];
    }
    
    function getUserLiquidityPool(address _accountAddress) public view returns(string memory, address, address, uint){
        for (uint i = 0; i < poolExchange.length; i++) {
            if (poolExchange[i].userAddress == _accountAddress) {
                return ("This User is in active state", poolExchange[i].userAddress, poolExchange[i].tokenAddress, poolExchange[i].amount);
            }
        }
        return ("This User is not present", 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0);
    }
}

