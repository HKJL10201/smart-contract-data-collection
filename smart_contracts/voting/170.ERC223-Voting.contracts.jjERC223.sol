

pragma solidity ^0.4.18;

import './SafeMath.sol';

contract ERC223 {
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    
    function balanceOf(address _owner) public view returns (uint256);
    
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    
    function transfer(address _to, uint256 _value) external;
    function transfer(address _to, uint256 _value, bytes32 _data) external;
    function _transfer(address _from, address _to, uint256 _value, bytes32 _data) internal returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value, bytes32 indexed data);
}

contract StandardToken is ERC223{
  using SafeMath for uint;
  
    mapping (address => uint256) balances;
    
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) external{
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        _transfer(msg.sender,_to,_value,"");
    }
    function transfer(address _to, uint256 _value, bytes32 _data) external{
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        _transfer(msg.sender,_to,_value,_data);
        
    }
    
    function _transfer(address _from, address _to, uint256 _value, bytes32 _data) internal returns(bool){
        require(_value > 0 );
        if(isContract(_to)) {
            _to.call(bytes4(sha3("tokenFallback(address,uint256,bytes32)")), _from,_value,_data);
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value, _data);
        return true;
    }
    
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}

contract jjERC223 is StandardToken{
    
    string internal _name;                   // Token Name
    uint8 internal _decimals;                // How many decimals to show. To be standard complicant keep it 18
    string internal _symbol;                 // An identifier: eg SBX, XPR etc..
    uint256 public totalSupply;
    string public version = 'J1.0'; 
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We'll store the total ETH raised via our ICO here.  
    address public fundsWallet;           // Where should the raised ETH go?
    
    
    function totalSupply() constant returns (uint256 totalSupply){
        return totalSupply;
    }
    function name() constant returns (string _name){
        return _name;
    }
    function symbol() constant returns (bytes32 _symbol){
        return _symbol;
    }
    function decimals() constant returns (uint8 _decimals){
        return _decimals;
    }

    
    
    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);

        Transfer(fundsWallet, msg.sender, amount, ""); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);                               
    }
    
    function jjERC223(){
        balances[msg.sender] = 1000000000000000000000;               // Give the creator all initial tokens. This is set to 1000 for example. If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE THIS)
        totalSupply = 1000000000000000000000;                        // Update total supply (1000 for example) (CHANGE THIS)
        _name = "jjERC223";                                   // Set the name for display purposes (CHANGE THIS)
        _decimals = 18;                                               // Amount of decimals for display purposes (CHANGE THIS)
        _symbol = "jE2";                                             // Set the symbol for display purposes (CHANGE THIS)
        unitsOneEthCanBuy = 10;                                      // Set the price of your token for the ICO (CHANGE THIS)
        fundsWallet = msg.sender;                                    // The owner of the contract gets ETH
    }
}
