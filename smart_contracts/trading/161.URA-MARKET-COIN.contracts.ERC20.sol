pragma solidity ^0.5.2;


import "./SafeMath.sol";
import "./Address.sol";


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// @wiki: https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function tokensOwner() public view returns (uint256);
    function contracBalance() public view returns (uint256);
    function balanceOf(address _tokenOwner) public view returns (uint256 balanceOwner);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event EtherTransfer(address indexed from, address indexed to, uint256 etherAmount);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol.
// ----------------------------------------------------------------------------
contract ERC20 is ERC20Interface {
    using SafeMath for uint;
    using ToAddress for *;

    string constant public symbol = "URA";
    string constant public  name = "URA market coin";
    uint8 constant internal decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;


    // ------------------------------------------------------------------------
    // Get balance on contract
    // ------------------------------------------------------------------------
    function contracBalance() public view returns (uint256 contractBalance) {
        contractBalance = address(this).balance;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) public view returns (uint256 balanceOwner) {
        return balances[_tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Addon shows caller tokens.
    // ------------------------------------------------------------------------
    function tokensOwner() public view returns (uint256 tokens) {
        tokens = balances[msg.sender];
    }

}
