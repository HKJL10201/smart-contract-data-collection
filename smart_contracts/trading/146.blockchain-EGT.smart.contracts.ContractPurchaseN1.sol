// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "./EnergyToken.sol";

contract ContractPurchaseN1 {
    EnergyToken public token;
    address public seller;
    address public buyer;
    address public resvWallet;
    uint256 public timeWaiting;
    string public hashTX1;
    string public mtTX1;
    string public hashTX2;
    string public mtTX2;
    string public etat;
    string public hashTX3;
    string public mtTX3;
    bool public isCompleted;
    string public date_creation;
    string public date_completed;
    address public transporter;
    string public hashTX1_finish;
    string public hashTX2_finish;
    string public hashTX3_finish;




    constructor(
        address _tokenAddress,
        address _seller,
        address _buyer,
        address _resvWallet,
        uint256 _timeWaiting,
        string memory _hashTX1,
        string memory _mtTX1,
        string memory _hashTX2,
        string memory _mtTX2,
        string memory _etat,
        string memory _date_creation
    ) {
        token = EnergyToken(_tokenAddress);
        seller = _seller;
        buyer = _buyer;
        resvWallet = _resvWallet;
        timeWaiting = _timeWaiting;
        hashTX1 = _hashTX1;
        mtTX1 = _mtTX1;
        hashTX2 = _hashTX2;
        mtTX2 = _mtTX2;
        etat = _etat;
        date_creation = _date_creation;
    }
    function update_initiate1(
        address _transporter,
        string memory _hashTX3,
        string memory _mtTX3
    )external {
        transporter=  _transporter;
        hashTX3= _hashTX3;
        mtTX3=_mtTX3;
    }
    function update_initiate2(
        string memory _hashTX1_finish,
        string memory _hashTX2_finish,
        string memory _hashTX3_finish
    )external {
        hashTX1_finish=  _hashTX1_finish;
        hashTX2_finish= _hashTX2_finish;
        hashTX3_finish=  _hashTX3_finish;
    }
    function setHashTX3(string memory _hashTX3) external {
        //require(msg.sender == seller, "Only the seller can set the hashTX3");
        hashTX3 = _hashTX3;
    }

    function setMtTX3(string memory _mtTX3) external {
        //require(msg.sender == seller, "Only the seller can set the mtTX3");
        mtTX3 = _mtTX3;
    }
     function getTokenAddress() external view returns (address) {
        return address(token);
    }

    function setTokenAddress(address _tokenAddress) external {
        token = EnergyToken(_tokenAddress);
    }

    function getSeller() external view returns (address) {
        return seller;
    }

    function setSeller(address _seller) external {
        seller = _seller;
    }

    function getBuyer() external view returns (address) {
        return buyer;
    }

    function setBuyer(address _buyer) external {
        buyer = _buyer;
    }

    function getResvWallet() external view returns (address) {
        return resvWallet;
    }

    function setResvWallet(address _resvWallet) external {
        resvWallet = _resvWallet;
    }

    function getTimeWaiting() external view returns (uint256) {
        return timeWaiting;
    }

    function setTimeWaiting(uint256 _timeWaiting) external {
        timeWaiting = _timeWaiting;
    }

    function getMtTX1() external view returns (string memory) {
        return mtTX1;
    }

    function setMtTX1(string memory _mtTX1) external {
        mtTX1 = _mtTX1;
    }
    function getMtTX2 () external view returns (string memory) {
        return mtTX2;
    }
    function setMtTX2  (string memory _mtTX2) external {
        mtTX2 = _mtTX2;
    }
    function getHashTX2() external view returns (string memory) {
        return hashTX2;
    }

    function setHashTX2(string memory _hashTX2) external {
        hashTX2 = _hashTX2;
    }


    function getEtat() external view returns (string memory) {
        return etat;
    }

    function setEtat(string memory _etat) external {
        etat = _etat;
    }

    function getDateCreation() external view returns (string memory) {
        return date_creation;
    }

    function setDateCreation(string memory _date_creation) external {
        date_creation = _date_creation;
    }

    // Optional setter functions to update values
    function setCompleted(string memory _date_completed) external {
        require(msg.sender == buyer, "Only the buyer can set the completed status");
        isCompleted = true;
        date_completed = _date_completed;
    }
    // Getter for 'transporter' variable
    function getTransporter() public view returns (address) {
        return transporter;
    }

    // Setter for 'transporter' variable
    function setTransporter(address _transporter) public {
        transporter = _transporter;
    }

    // Getter for 'hashTX1_finish' variable
    function getHashTX1_finish() public view returns (string memory) {
        return hashTX1_finish;
    }

    // Setter for 'hashTX1_finish' variable
    function setHashTX1_finish(string memory _hashTX1_finish) public {
        hashTX1_finish = _hashTX1_finish;
    }

    // Getter for 'hashTX2_finish' variable
    function getHashTX2_finish() public view returns (string memory) {
        return hashTX2_finish;
    }

    // Setter for 'hashTX2_finish' variable
    function setHashTX2_finish(string memory _hashTX2_finish) public {
        hashTX2_finish = _hashTX2_finish;
        executeEtherTransfer();
    }

    // Getter for 'hashTX3_finish' variable
    function getHashTX3_finish() public view returns (string memory) {
        return hashTX3_finish;
    }

    // Setter for 'hashTX3_finish' variable
    function setHashTX3_finish(string memory _hashTX3_finish) public {
        hashTX3_finish = _hashTX3_finish;
    }
    event EtherTransfer(address indexed from, address indexed to, uint256 amount);
    function executeEtherTransfer() internal {
        // Perform any necessary checks or conditions before transferring Ether
        address payable sender = payable(resvWallet);
        address payable recipient = payable(seller);
        uint256 amount = parseEther(mtTX1);

        // Transfer Ether from "from" to the recipient
        recipient.transfer(amount);

        // Emit an event to indicate the Ether transfer        emit EtherTransfer(sender, recipient, amount);
            }
    function parseEther(string memory _value) internal pure returns (uint256) {
        bytes memory valueBytes = bytes(_value);
        require(valueBytes.length > 0, "Invalid value");

        uint256 factor = 1 ether;
        uint256 result = 0;
        uint256 decimalIndex = valueBytes.length;

        for (uint256 i = 0; i < valueBytes.length; i++) {
            if (valueBytes[i] == ".") {
                decimalIndex = i;
                break;
            }
        }

        for (uint256 i = 0; i < valueBytes.length; i++) {
            if (i == decimalIndex) continue;
            require(uint8(valueBytes[i]) >= 48 && uint8(valueBytes[i]) <= 57, "Invalid value");
            result = result * 10 + (uint256(uint8(valueBytes[i])) - 48);
        }

        if (decimalIndex < valueBytes.length) {
            uint256 decimalPlaces = valueBytes.length - decimalIndex - 1;
            require(decimalPlaces <= 18, "Too many decimal places");
            factor /= 10**decimalPlaces;
        }

        return result * factor;
    }
}
