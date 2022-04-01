pragma solidity ^0.5.0;
import "@gnosis.pm/mock-contract/contracts/MockContract.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";

contract IDutchExchange {

    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public sellerBalances;
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public buyerBalances;
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public claimedAmounts;
    mapping(address => mapping(address => uint)) public balances;

    function withdraw(address tokenAddress, uint amount) public returns (uint);
    function deposit(address tokenAddress, uint amount) public returns (uint);
    function ethToken() public returns(address);
    function frtToken() public returns(address);
    function owlToken() public returns(address);
    function getAuctionIndex(address token1, address token2) public view returns(uint256);
    function postBuyOrder(address token1, address token2, uint256 auctionIndex, uint256 amount) public returns(uint256);
    function postSellOrder(address token1, address token2, uint256 auctionIndex, uint256 tokensBought) public returns(uint256, uint256);
    function getCurrentAuctionPrice(address token1, address token2, uint256 auctionIndex) public view returns(uint256, uint256);
    function claimSellerFunds(address sellToken, address buyToken, address user, uint auctionIndex) public returns (uint returned, uint frtsIssued);
}