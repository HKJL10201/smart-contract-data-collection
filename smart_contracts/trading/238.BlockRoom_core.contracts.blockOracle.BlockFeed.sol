// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IBlockAddresses.sol";
import "../helpers/zeroAddressPreventer.sol";

/**
 * @title BlockFeed
 * @author javadyakuza
 * @notice this contract is used to fetch, store and verify the off-chain data about blocks and blockers
 */

contract BlockFeed is Ownable, Pausable, ZAP {
    /// @dev emited when a blocker is verified
    event BlockerVerified(uint64 _nationalId, address indexed _blocker);

    address public feeder;
    IBlockAddresses public immutable Addresses;

    mapping(uint256 => mapping(uint64 => uint8)) private blockOf;
    mapping(uint256 => mapping(uint64 => uint8)) private isBlocked;
    mapping(uint256 => mapping(uint8 => uint256)) public blockAge; // since it has been verified
    mapping(address => bool) private isBlocker;
    mapping(uint64 => address) private blockersAddresses;

    struct BlockOfParams {
        uint256 blockId;
        uint64 nationalId;
        uint8 component;
        bool reducedOutside;
    }

    constructor(
        address _feeder,
        IBlockAddresses _tempIAddresses
    ) nonZeroAddress(_feeder) nonZeroAddress(address(_tempIAddresses)) {
        Addresses = _tempIAddresses;
        feeder = _feeder;
    }

    modifier isFeeder() {
        require(
            msg.sender == feeder,
            "only feeder is allowed to change state !!"
        );
        _;
    }

    // set functions //
    // receiving an array because it will be called once in a day containing all changes in a day
    function setBlockOf(
        BlockOfParams[] calldata _blockBatch
    ) external isFeeder {
        for (uint i = 0; i < _blockBatch.length; i++) {
            // zero values for BlockId and the nationalId is not accepted
            require(
                _blockBatch[i].blockId != 0 && _blockBatch[i].nationalId != 0,
                string.concat(
                    "wrong blockBatch Error: 01 >> index",
                    Strings.toString(i) // the wrong item index, usefull in high scale
                )
            );
            if (_blockBatch[i].reducedOutside) {
                // the components are reduced outside of the Blockroom, reducing or deleting
                if (_blockBatch[i].component == 0) {
                    blockOf[_blockBatch[i].blockId][
                        _blockBatch[i].nationalId
                    ] = 0;
                } else {
                    // some components are left reducing the existing component
                    blockOf[_blockBatch[i].blockId][
                        _blockBatch[i].nationalId
                    ] -= _blockBatch[i].component;
                }
            } else {
                // component is only acceptable as zero when reducedOutside is true
                require(
                    _blockBatch[i].component != 0,
                    string.concat(
                        "wrong blockBatch Error: 01 >> index",
                        Strings.toString(i)
                    )
                );
                if (
                    isBlocked[_blockBatch[i].blockId][
                        _blockBatch[i].nationalId
                    ] == 0
                ) {
                    // means that block is not wrapped so checking its components with BlockOf {contract(this)}
                    require(
                        blockOf[_blockBatch[i].blockId][
                            _blockBatch[i].nationalId
                        ] +
                            _blockBatch[i].component <=
                            6,
                        string.concat(
                            "wrong blockBatch Error: 02 >> index",
                            Strings.toString(i)
                        )
                    );
                    blockOf[_blockBatch[i].blockId][
                        _blockBatch[i].nationalId
                    ] += _blockBatch[i].component;
                    // restarting the BlockAge fot this blockId and component
                    blockAge[_blockBatch[i].blockId][
                        _blockBatch[i].component
                    ] = block.timestamp;
                } else {
                    // means the Block is wrapped so checking its components with isBlocked {BlockWrapper}
                    require(
                        isBlocked[_blockBatch[i].blockId][
                            _blockBatch[i].nationalId
                        ] +
                            _blockBatch[i].component <=
                            6,
                        string.concat(
                            "wrong blockBatch Error: 02 >> index",
                            Strings.toString(i)
                        )
                    );
                    blockOf[_blockBatch[i].blockId][
                        _blockBatch[i].nationalId
                    ] = _blockBatch[i].component;
                    // restarting the BlockAge fot this blockId and component
                    blockAge[_blockBatch[i].blockId][
                        _blockBatch[i].component
                    ] = block.timestamp;
                }
            }
        }
    }

    function setIsBlocked(BlockOfParams calldata _params) external {
        // checking is the Block is wrapped by its blocker os not
        require(
            Addresses.modifierIsBlockWrapper(msg.sender),
            "only accessible by wrapper contract"
        );
        isBlocked[_params.blockId][_params.nationalId] = _params.component;
    }

    function setBlockerAddress(
        uint64 _nationalId,
        address _blockerAddress
    ) external isFeeder nonZeroAddress(_blockerAddress) {
        require(
            blockersAddresses[_nationalId] == address(0) &&
                !isBlocker[_blockerAddress],
            "nationalId or address already defined !!"
        );
        blockersAddresses[_nationalId] = _blockerAddress;
        isBlocker[_blockerAddress] = true;
        emit BlockerVerified(_nationalId, _blockerAddress);
    }

    // set functions //
    //---------------//
    // get functions //
    function getBlockerAddress(
        uint64 _nationalId
    ) external view whenNotPaused returns (address _blockerAddress) {
        return blockersAddresses[_nationalId];
    }

    function getBlockOf(
        uint256 _blockId,
        uint64 _nationalId,
        uint8 _component
    ) external view whenNotPaused returns (bool isUsersBlock) {
        return blockOf[_blockId][_nationalId] == _component;
    }

    function isBlockPending(
        uint256 _blockId,
        uint8 _component
    ) public view returns (bool isPending) {
        uint256 oneDay = 86400; // number of seconds in a day
        return (block.timestamp >= blockAge[_blockId][_component] + oneDay);
    }

    // get functions //
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function changeFeeder(
        address _newFeeder
    ) external onlyOwner nonZeroAddress(_newFeeder) {
        require(_newFeeder != feeder, "existing feeder !!");
        feeder = _newFeeder;
    }
}
