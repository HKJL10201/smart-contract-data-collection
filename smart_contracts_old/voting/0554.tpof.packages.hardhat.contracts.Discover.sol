pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ApproveAndCallFallBack.sol";
import "./BancorFormula.sol";
// learn more: https://docs.openzeppelin.com/contracts/3.x/erc20


contract Discover is Ownable, ApproveAndCallFallBack, BancorFormula {
    // Could be any MiniMe token
    IERC20 sheet;

    // Total SHEET in circulation
    uint public total;

    // Parameter to calculate Max SHEET any one DApp can stake
    uint public ceiling;

    // The max amount of tokens it is possible to stake, as a percentage of the total in circulation
    uint public max;

    // Decimal precision for this contract
    uint public decimals;

    // Prevents overflows in votesMinted
    uint public safeMax;

    // Whether we need more than an id param to identify arbitrary data must still be discussed.
    struct Data {
        address developer;
        bytes32 id;
        bytes32 metadata;
        uint balance;
        uint rate;
        uint available;
        uint votesMinted;
        uint votesCast;
        uint effectiveBalance;
    }

    Data[] public orientations;
    mapping(bytes32 => uint) public id2index;
    mapping(bytes32 => bool) public existingIDs;

    event OrientationCreated(bytes32 indexed id, uint newEffectiveBalance);
    event Upvote(bytes32 indexed id, uint newEffectiveBalance);
    event Downvote(bytes32 indexed id, uint newEffectiveBalance);
    event Withdraw(bytes32 indexed id, uint newEffectiveBalance);
    event MetadataUpdated(bytes32 indexed id);
    event CeilingUpdated(uint oldCeiling, uint newCeiling);


    constructor(address _SHEET) {
        sheet = IERC20(_SHEET);

        total = 6942002400;

        ceiling = 292;   // See here for more: https://observablehq.com/@andytudhope/dapp-store-SNT-curation-mechanism

        decimals = 1000000; // 4 decimal points for %, 2 because we only use 1/100th of total in circulation

        max = total * ceiling / decimals;

        safeMax = uint(77) * max / 100; // Limited by accuracy of BancorFormula
    }

    /**
     * @dev Update ceiling
     * @param _newCeiling New ceiling value
     */
    function setCeiling(uint _newCeiling) external onlyOwner {
        emit CeilingUpdated(ceiling, _newCeiling);

        ceiling = _newCeiling;
        max = total * ceiling / decimals;
        safeMax = uint(77) * max / 100;
    }

    /**
     * @dev Anyone can create an Orientation. You can also restrict it, adding an onlyOwner modifier
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake on initial ranking.
     * @param _metadata metadata hex string
     */
    function createOrientation(bytes32 _id, uint _amount, bytes32 _metadata) external {
        _createOrientation(
            msg.sender,
            _id,
            _amount,
            _metadata);
    }

    /**
     * @dev Sends SHEET directly to the contract, not the developer. This gets added to the DApp's balance, no curve required.
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake on DApp's ranking. Used for upvoting + staking more.
     */
    function upvote(bytes32 _id, uint _amount) external {
        _upvote(msg.sender, _id, _amount);
    }

    /**
     * @dev Sends SHEET to the developer and lowers the DApp's effective balance by 1%
     * @param _id bytes32 unique identifier.
     * @param _amount uint, included for approveAndCallFallBack
     */
    function downvote(bytes32 _id, uint _amount) external {
        _downvote(msg.sender, _id, _amount);
    }

    /**
     * @dev Developers can withdraw an amount not more than what was available of the
        SHEET they originally staked minus what they have already received back in downvotes.
     * @param _id bytes32 unique identifier.
     * @return max SHEET that can be withdrawn == available SHEET for DApp.
     */
    function withdrawMax(bytes32 _id) external view returns(uint) {
        Data storage d = _getOrientationById(_id);
        return d.available;
    }

    /**
     * @dev Developers can withdraw an amount not more than what was available of the
        SHEET they originally staked minus what they have already received back in downvotes.
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to withdraw from DApp's overall balance.
     */
    function withdraw(bytes32 _id, uint _amount) external {

        Data storage d = _getOrientationById(_id);

        uint256 tokensQuantity = _amount / (1 ether);

        require(msg.sender == d.developer, "Only the developer can withdraw SHEET staked on this data");
        require(tokensQuantity <= d.available, "You can only withdraw a percentage of the SHEET staked, less what you have already received");

        uint precision;
        uint result;

        d.balance = d.balance - tokensQuantity;
        d.rate = decimals - (d.balance * decimals / max);
        d.available = d.balance * d.rate;

        (result, precision) = BancorFormula.power(
            d.available,
            decimals,
            uint32(decimals),
            uint32(d.rate));

        d.votesMinted = result >> precision;
        if (d.votesCast > d.votesMinted) {
            d.votesCast = d.votesMinted;
        }

        uint temp1 = d.votesCast * d.rate * d.available;
        uint temp2 = d.votesMinted * decimals * decimals;
        uint effect = temp1 / temp2;

        d.effectiveBalance = d.balance - effect;

        require(sheet.transfer(d.developer, _amount), "Transfer failed");

        emit Withdraw(_id, d.effectiveBalance);
    }

    /**
     * @dev Set the content for the dapp
     * @param _id bytes32 unique identifier.
     * @param _metadata metadata info
     */
    function setMetadata(bytes32 _id, bytes32 _metadata) external {
        uint orientationIdx = id2index[_id];
        Data storage d = orientations[orientationIdx];
        require(d.developer == msg.sender, "Only the developer can update the metadata");
        d.metadata = _metadata;
        emit MetadataUpdated(_id);
    }

    /**
     * @dev Get the content for the dapp
     * @param _id bytes32 unique identifier.
     */
    function getMetadata(bytes32 _id) external view returns(bytes32){
        uint orientationIdx = id2index[_id];
        Data memory d = orientations[orientationIdx];
        return d.metadata;
    }

    /**
     * @dev Used in UI in order to fetch all orientations
     * @return orientations count
     */
    function getOrientationsCount() external view returns(uint) {
        return orientations.length;
    }

    /**
     * @notice Support for "approveAndCall".
     * @param _from Who approved.
     * @param _amount Amount being approved, needs to be equal `_amount` or `cost`.
     * @param _token Token being approved, needs to be `SHEET`.
     * @param _data Abi encoded data with selector of `register(bytes32,address,bytes32,bytes32)`.
     */
    function receiveApproval (
        address _from,
        uint256 _amount,
        address _token,
        bytes calldata _data
    )
        external override
    {
        require(_token == address(sheet), "Wrong token");
        require(_token == address(msg.sender), "Wrong account");
        require(_data.length <= 196, "Incorrect data");

        bytes4 sig;
        bytes32 id;
        uint256 amount;
        bytes32 metadata;

        (sig, id, amount, metadata) = abiDecodeRegister(_data);
        require(_amount == amount, "Wrong amount");

        if (sig == bytes4(0x7e38d973)) {
            _createOrientation(
                _from,
                id,
                amount,
                metadata);
        } else if (sig == bytes4(0xac769090)) {
            _downvote(_from, id, amount);
        } else if (sig == bytes4(0x2b3df690)) {
            _upvote(_from, id, amount);
        } else {
            revert("Wrong method selector");
        }
    }

    /**
     * @dev Used in UI to display effect on ranking of user's donation
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake/"donate" to this DApp's ranking.
     * @return effect of donation on DApp's effectiveBalance
     */
    function upvoteEffect(bytes32 _id, uint _amount) external view returns(uint effect) {
        Data memory d = _getOrientationById(_id);
        require(d.balance + _amount <= safeMax, "You cannot upvote by this much, try with a lower amount");

        // Special case - no downvotes yet cast
        if (d.votesCast == 0) {
            return _amount;
        }

        uint precision;
        uint result;

        uint mBalance = d.balance + _amount;
        uint mRate = decimals - (mBalance * decimals / max);
        uint mAvailable = mBalance * mRate;

        (result, precision) = BancorFormula.power(
            mAvailable,
            decimals,
            uint32(decimals),
            uint32(mRate));

        uint mVMinted = result >> precision;

        uint temp1 = d.votesCast * mRate * mAvailable;
        uint temp2 = mVMinted * decimals * decimals;
        uint mEffect = temp1 / temp2;

        uint mEBalance = mBalance - mEffect;

        return (mEBalance - d.effectiveBalance);
    }

     /**
     * @dev Downvotes always remove 1% of the current ranking.
     * @param _id bytes32 unique identifier.
     */
    function downvoteCost(bytes32 _id) external view returns(uint b, uint vR, uint c) {
        Data memory d = _getOrientationById(_id);
        return _downvoteCost(d);
    }

    function _createOrientation(
        address _from,
        bytes32 _id,
        uint _amount,
        bytes32 _metadata
        )
      internal
      {
        require(!existingIDs[_id], "You must submit a unique ID");

        uint256 tokensQuantity = _amount / (1 ether);

        require(tokensQuantity > 0, "You must spend some SHEET to submit a ranking in order to avoid spam");
        require (tokensQuantity <= safeMax, "You cannot stake more SHEET than the ceiling dictates");

        uint orientationIdx = orientations.length;

        Data memory d;
        d.developer = _from;
        d.id = _id;
        d.metadata = _metadata;

        uint precision;
        uint result;

        d.balance = tokensQuantity;
        d.rate = decimals - (d.balance * decimals / max);
        d.available = d.balance * (d.rate);

        (result, precision) = BancorFormula.power(
            d.available,
            decimals,
            uint32(decimals),
            uint32(d.rate));

        d.votesMinted = result >> precision;
        d.votesCast = 0;
        d.effectiveBalance = tokensQuantity;

        orientations.push(d);

        id2index[_id] = orientationIdx;
        existingIDs[_id] = true;

        require(sheet.transferFrom(_from, address(this), _amount), "Transfer failed");

        emit OrientationCreated(_id, d.effectiveBalance);
    }

    function _upvote(address _from, bytes32 _id, uint _amount) internal {
        uint256 tokensQuantity = _amount / (1 ether);
        require(tokensQuantity > 0, "You must send some SHEET in order to upvote");

        Data storage d = _getOrientationById(_id);

        require(d.balance + (tokensQuantity) <= safeMax, "You cannot upvote by this much, try with a lower amount");

        uint precision;
        uint result;

        d.balance = d.balance + (tokensQuantity);
        d.rate = decimals - ((d.balance)*(decimals)/(max));
        d.available = d.balance * (d.rate);

        (result, precision) = BancorFormula.power(
            d.available,
            decimals,
            uint32(decimals),
            uint32(d.rate));

        d.votesMinted = result >> precision;

        uint temp1 = d.votesCast*(d.rate)*(d.available);
        uint temp2 = d.votesMinted*(decimals)*(decimals);
        uint effect = temp1/(temp2);

        d.effectiveBalance = d.balance-(effect);

        require(sheet.transferFrom(_from, address(this), _amount), "Transfer failed");

        emit Upvote(_id, d.effectiveBalance);
    }

    function _downvote(address _from, bytes32 _id, uint _amount) internal {
        uint256 tokensQuantity = _amount/(1 ether);
        Data storage d = _getOrientationById(_id);
        (uint b, uint vR, uint c) = _downvoteCost(d);

        require(tokensQuantity == c, "Incorrect amount: valid iff effect on ranking is 1%");

        d.available = d.available-(tokensQuantity);
        d.votesCast = d.votesCast+(vR);
        d.effectiveBalance = d.effectiveBalance-(b);

        require(sheet.transferFrom(_from, d.developer, _amount), "Transfer failed");

        emit Downvote(_id, d.effectiveBalance);
    }

    function _downvoteCost(Data memory d) internal view returns(uint b, uint vR, uint c) {
        uint balanceDownBy = (d.effectiveBalance/(100));
        uint votesRequired = (balanceDownBy*(d.votesMinted)*(d.rate))/(d.available);
        uint votesAvailable = d.votesMinted-(d.votesCast)-(votesRequired);
        uint temp = (d.available/(votesAvailable))*(votesRequired);
        uint cost = temp/(decimals);
        return (balanceDownBy, votesRequired, cost);
    }

    /**
     * @dev Used internally in order to get a dapp while checking if it exists
     */
    function _getOrientationById(bytes32 _id) internal view returns(Data storage d) {
        uint orientationIdx = id2index[_id];
        d = orientations[orientationIdx];
        require(d.id == _id, "Error fetching correct data");
    }

     /**
     * @dev Decodes abi encoded data with selector for "functionName(bytes32,uint256)".
     * @param _data Abi encoded data.
     */
    function abiDecodeRegister(
        bytes memory _data
    )
        private
        pure
        returns(
            bytes4 sig,
            bytes32 id,
            uint256 amount,
            bytes32 metadata
        )
    {
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
            id := mload(add(_data, 36))
            amount := mload(add(_data, 68))
            metadata := mload(add(_data, 100))
        }
    }
}
