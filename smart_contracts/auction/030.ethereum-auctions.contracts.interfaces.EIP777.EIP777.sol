pragma solidity ^0.4.18;

interface EIP777 {
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function granularity() public constant returns (uint256);
    function totalSupply() public constant returns (uint256);
    function balanceOf(address owner) public constant returns (uint256);

    function send(address to, uint256 value) public;
    function send(address to, uint256 value, bytes userData) public;

    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;
    function isOperatorFor(address operator, address tokenHolder) public constant returns (bool);
    function operatorSend(address from, address to, uint256 value, bytes userData, bytes operatorData) public;

    event Sent(address indexed from, address indexed to, uint256 value, address indexed operator, bytes userData, bytes operatorData);
    event Minted(address indexed to, uint256 amount, address indexed operator, bytes operatorData);
    event Burnt(address indexed from, uint256 value);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}