//SPDX-License-Identifier: None
pragma solidity >=0.4.0;

import './Lottery.sol';

/**
@title Storage of all the loterries
@notice This contract contains all the lotteries created in the system
@dev This contract makes easy to update the logic by dividing the logic and the storage
*/
contract LotteryStorage {

    address owner;
    address latestVersion;

    // Structures where loteries are saved
    mapping(address => Lottery) lotteryStorage;
    Lottery[] lotteries;

    constructor(address _sender) public {
        owner = _sender;
        latestVersion = msg.sender;
    }


    /**
    @notice checks if the contract calling is the latest version provided
    */
    modifier onlyLatestVersion() {
       require(msg.sender == latestVersion, 'only latest version');
        _;
    }

    /**
    @notice upgrade the address of the logic
    @dev this will be called by the owner of the contract (user) when an upgrade of the logic is made
    @param _newVersion address of the new contract logic
    */
    function upgradeVersion(address _newVersion, address _sender) public {
        require(_sender == owner,'only owner');
        latestVersion = _newVersion;
    }

    // *** Getter Methods ***
    /**
    @notice gets a lottery by its address
    @param _key address of the lottery
    @return the lottery
    */
    function getLottery(address _key) external view returns(Lottery){
        return lotteryStorage[_key];
    }

    /**
    @notice gets all the lotteries saved
    @return the lotteries
    */
    function getLotteries() external view returns (Lottery[] memory){
        return lotteries;
    }

    // *** Setter Methods ***
    /**
    @notice adds a new lottery to the storage mapping and array
    @dev can only be executed by the latest version contract
    @param _key the address of the lottery
    @param _value the lottery to save
    */
    function setLottery(address _key, Lottery _value) external onlyLatestVersion {
        lotteryStorage[_key] = _value;
        lotteries.push(_value);
    }
}