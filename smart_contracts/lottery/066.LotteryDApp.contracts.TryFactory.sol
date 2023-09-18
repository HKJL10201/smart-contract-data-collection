// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Try.sol";

/**
 * @title TryFactory
 * @dev A standard factory for Try contract
 */

contract TryFactory {

    // Try contract
    Try public lottery;
    // Interface for communicate with KittyNFT contract
    IKittyNFT iKittyNFT;
    // Address of KittyNFT contract
    address kittyNFT;
    // Owner of the factory
    address owner;

    event LotteryCreated();

    constructor(){
        owner = msg.sender;
    }

    /**
     * @dev Instantiate a new Try contract and emit the event
     * @param _M: Number of round for the new lottery
     * @param _K: Parameter K used for randomness
     */
    function createNewLottery(uint _M, uint _K, uint price) public {
        require(msg.sender == owner, "Only the owner can create a new lottery");
        lottery = new Try(_M, _K, price, kittyNFT, owner);
        iKittyNFT.setLotteryAddress(address(lottery));
        emit LotteryCreated();
    }

    /**
     * @dev Return the address of the instantiated contract
     */
    function getLottteryAddr() public view returns(Try){
        return lottery;
    }

    /**
     * @dev Associate the address of the KittyNFT contract
     * @param addr: Address of kittyNFT contract
     */
    function setKittyNFTAddress(address addr) public {
        require(msg.sender == owner, "Only the owner can set the address");
        iKittyNFT = IKittyNFT(addr);
        kittyNFT = addr;
    }

    /**
     * @dev Tell to KittyNFT which is the active Try contract address
     * @param _lottery: Address of active lottery
     */
    function setLotteryAddr(address _lottery) public {
        require(msg.sender == owner, "Only the owner can set the address");
        iKittyNFT.setLotteryAddress(_lottery);
    }
}