// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    uint256 public MAX_TOKEN = 5;
    uint256 public PRICE = 0.01 ether;
    address public OWNER = 0x0000000000000000000000000000000000000000;  //Address Owner
    address public lotteryDirection;    //Address of lottery
    uint256 public token_count;
    uint256 public paused_date = 123; //Fecha de pausa en UNIX
    string public mail;
    bool public paused;

    address[] public address_lottery; //array de address_lottery
    mapping (address => string) public address_mail;
    
    constructor() ERC721("My NFT", "MNFT") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "MIURL"; //URL de la coleccion
    }

    function addMail(string memory _mail) public {  //funcion para agregar mail
        mail = _mail;
    }

    function mintNFT(address to) public payable {
        require(token_count < MAX_TOKEN, "Sold out");
        require(paused == false, "Function Paused");
        require(msg.value >= PRICE, "Must pay price");
        _mint(to, token_count);
        token_count  += 1;
        address_lottery.push(msg.sender); //pushear el msg.sender al array address_lottery
        address_mail[msg.sender] = mail; //pushear al mapping address => mail
    }

    function sendAward() public { //Enviar ether de premio al contrato de la loteria
        require(paused == true, "You can only activate this function when the pause is activated");
        require(msg.sender == OWNER);
        uint award = address(this).balance * 50 / 100;
        (bool success, ) = lotteryDirection.call{value: award}("");
        require(success, "Failed to send Ether");
    }

    function withdrawAll() public {
        require(paused == true, "You can only activate this function when the pause is activated");
        (bool success, ) = OWNER.call{value:address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setPaused(bool _paused) public {
        require(msg.sender == OWNER, "You are not the owner");
        require(block.timestamp > paused_date, "The function can only be used from the day xx/xx/xx");
        paused = _paused;
    }

    function setLotteryDirection (address _lotteryDirection) public {
        require(msg.sender == OWNER, "You are not the owner");
        lotteryDirection = _lotteryDirection;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

}