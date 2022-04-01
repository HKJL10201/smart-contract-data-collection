pragma solidity ^0.6.0;
import "./token.sol";

contract ERC20Manager {
    address payable seller;
    uint public price = 100 finney;
    ETHC tokenContract;

    constructor() public
    {
        seller = msg.sender;
    }

    modifier onlyOwner
    {
        require(
            msg.sender == seller,
            "Only owner can call this function."
        );
        _;
    }
    modifier isConfigured
    {
        require(
            tokenContract != ETHC(0),
            "Token is not configured yet"
        );
        _;
    }

    modifier gtPrice
    {
        require(msg.value >= price, "Value should be greater than price!");
        _;
    }

    function config(address _tokenContract) public onlyOwner
    {
        tokenContract = ETHC(_tokenContract);
    }

    // get configured token name
    function getTokenName() public view isConfigured returns (string memory)
    {
        return tokenContract.name();
    }

    // proxy balanceOf
    function balanceOf(address addr) public view isConfigured returns (uint256)
    {
        return tokenContract.balanceOf(addr);
    }

    // swap token
    function swap(uint256 amount) external isConfigured
    {
      require(tokenContract.balanceOf(msg.sender) > amount);
      tokenContract.transferFrom(msg.sender, seller, amount);
      msg.sender.transfer(amount * price);
    }
    
    // swap ether
    // function swap() external payable isConfigured gtPrice
    // {
    //   uint amount = msg.value / price;
    //   tokenContract.transferFrom(seller, msg.sender, amount);
    // }

    // buy with ref
    function buy(address ref) external payable isConfigured gtPrice
    {
        if(tokenContract.balanceOf(ref) > 0) {
            // reward referral token
            tokenContract.transferFrom(seller, ref, 1);
        }
        uint amount = msg.value / price;
        tokenContract.transferFrom(seller, tx.origin, amount);
    }

    function transferTo(uint256 amount, address toAddr) external payable isConfigured gtPrice
    {
      require(tokenContract.balanceOf(msg.sender) > amount);
      require(msg.value > price * amount);
      tokenContract.transferFrom(msg.sender, toAddr, amount);
    }

    // fallback
    fallback() external payable
    {
        revert("Not enough Ether provided.");
    }
}