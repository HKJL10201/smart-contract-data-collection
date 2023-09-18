//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./components/IsPausable.sol";
import "../ZoKrates/target/release/verifier.sol";

/// @title Lottery Smart Contract using block timestamp/difficulty as a source of randomness.
/// @author eludius18
/// @notice This Smart Contract allow to enter ETH and takes prizes
contract Lottery is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IsPausable,
    Verifier
{
    //============== CONSTRUCTOR ==============
    constructor() {
        _disableInitializers();
    }

    //============== INITIALIZE ==============

    function initialize(uint256 _miniumPayment, address _selectWinnerOwner) initializer public {
        miniumPayment = _miniumPayment;
        selectWinnerOwner = _selectWinnerOwner;
        islotteryOngoing = true;
        __Ownable_init();
        __IsPausable_init();
    }

    //============== VARIABLES ==============

    address payable[] public players;
    uint256 public miniumPayment;
    bool public islotteryOngoing;
    address public selectWinnerOwner;
    address public player;
    address public winner;
    uint256 public value;
    uint256 public totalQtyWon;

    //============== EVENTS ===============

    event newPlayer(address player, uint256 value);
    event selectedWinner(address winner, uint256 totalQtyWon);
    event newMiniumPayment(uint256 miniumPayment);
    event newselectWinnerOwner(address selectWinnerOwner);

    //============== MODIFIERS ==============

    /// @notice This modifier checks if Lottery is Ongoing
    modifier lotteryOngoing() {
        require(islotteryOngoing, "Lottery has ended");
        _;
    }
    modifier OnlySelectedWinnerOwner(address _selectWinnerOwner) {
        require(selectWinnerOwner == _selectWinnerOwner, "Only selectWinnerOwner");
        _;
    }
    /// @notice This modifier checks if user sets correctly payment
    modifier paymentMeetRequirements() {
        require(msg.sender == tx.origin, "Only EOA");
        require(msg.value > 0, "You must send Ether to enter the lottery");
        require(msg.value >= miniumPayment, "You must send a Minium amout of Ether");
        _;
    }

    /// @notice Enter function to send ETH
    function enterLottery(
        Proof memory proof, 
        uint[3] memory input
        )public payable
        nonReentrant
        whenNotPaused
        paymentMeetRequirements
        lotteryOngoing
    {
        // Verify the proof using the verification keys and the inputs
        require(verifyTx(proof, input), "Must be at least 18 years old");
        players.push(payable(msg.sender));
        emit newPlayer(msg.sender, msg.value);
    }
    /// @notice Select function OnlyOwner to select Winner using GetRandom and tranfer amounto to winner
    function selectWinner() 
        public 
        OnlySelectedWinnerOwner(msg.sender)
    {
        islotteryOngoing = false;
        uint index = getRandomNumber() % players.length;
        address lotteryWinner = players[index];
        // reset the state of the contract
        players = new address payable[](0);
        (bool success, ) = payable(lotteryWinner).call{value: address(this).balance}("");
        require(success, "error sending BNB");
        islotteryOngoing = true;
        emit selectedWinner(lotteryWinner, address(this).balance);
    }

    /// @notice Function to change the ownership of the Smart Contract
    /// @param newOwner new Owner Wallet

    function changeContractOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        transferOwnership(newOwner);
    }

    /// @notice Change Oener of selectWinner function
    /// @param _selectWinnerOwner new selectWinnerOwner

    function changeSelectWinnerOwner(address _selectWinnerOwner) public onlyOwner {
        require(_selectWinnerOwner != address(0), "Ownable: new owner is the zero address");
        selectWinnerOwner = _selectWinnerOwner;
        emit newselectWinnerOwner(selectWinnerOwner);
    }

    /// @notice Function OnlyOwner to change the minium investment defined in intilization
    /// @param _newMiniumPayment new minium Payment
    function changeDefaultMiniumPayment(uint256 _newMiniumPayment)
        public
        onlyOwner
    {
        require(_newMiniumPayment != 0, "New Minium Payment should be up to 0");
        miniumPayment = _newMiniumPayment;
        emit newMiniumPayment(miniumPayment);
    }

    /// @notice Get funtion which returns MiniumPayment Value
    function getMiniumPayment() public view returns (uint256) {
        return miniumPayment;
    }
    /// @notice Get funtion which returns Random Number used to get lottery winner
    function getRandomNumber() internal view returns (uint) {
        uint256 seed = uint256(block.timestamp) / uint256(block.difficulty);
        return uint256(keccak256(abi.encodePacked(seed)));
    }

    /// @notice Get funtion which returns an array of players in current lottery
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    /// @notice Get funtion which returns total balance in lottery Smart Contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Get funtion which returns select Winner function Owner
    function getSelectWinnerOwner() public view returns (address) {
        return selectWinnerOwner;
    }
}