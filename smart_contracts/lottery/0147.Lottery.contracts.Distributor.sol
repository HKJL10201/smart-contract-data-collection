// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Distributor is VRFConsumerBase, ERC721Holder {
    bytes32 internal immutable keyHash;
    LinkTokenInterface public immutable link;

    mapping(bytes32 => address) public rewardAddress;
    mapping(bytes32 => uint256) public rewardId;

    // Info for the VRF call to consume
    mapping(bytes32 => address) public nftRecipientAddress;
    // Both start and end are inclusive indices
    mapping(bytes32 => uint256) public nftRecipientStart;
    mapping(bytes32 => uint256) public nftRecipientEnd;

    mapping(bytes32 => uint256) internal requestIdToRandomness;

    event RecipientSelected(
        address indexed prize,
        uint256 id,
        address indexed to
    );

    constructor(
        address _vrf,
        address _link,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrf, _link) {
        link = LinkTokenInterface(_link);
        keyHash = _keyHash;
    }

    function randomForRequestID(bytes32 _requestID)
        external
        view
        returns (uint256)
    {
        require(isRequestIDFulfilled(_requestID), "Not fulfilled");
        return requestIdToRandomness[_requestID];
    }

    function isRequestIDFulfilled(bytes32 _requestID)
        public
        view
        returns (bool)
    {
        return requestIdToRandomness[_requestID] != 0;
    }

    function distributeToNftHolders(
        uint256 fee,
        address _nftRecipientAddress,
        uint256 startIndex,
        uint256 endIndex,
        address _rewardAddress,
        uint256 _rewardId
    ) external {
        link.transferFrom(msg.sender, address(this), fee);
        IERC721(_rewardAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _rewardId
        );
        bytes32 requestId = requestRandomness(keyHash, fee);
        nftRecipientAddress[requestId] = _nftRecipientAddress;
        nftRecipientStart[requestId] = startIndex;
        nftRecipientEnd[requestId] = endIndex;
        rewardAddress[requestId] = _rewardAddress;
        rewardId[requestId] = _rewardId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        requestIdToRandomness[requestId] = randomness;

        uint256 startIndex = nftRecipientStart[requestId];
        uint256 endIndex = nftRecipientEnd[requestId];
        address recipient = IERC721(nftRecipientAddress[requestId]).ownerOf(
            (randomness % (endIndex + 1 - startIndex)) + startIndex
        );
        IERC721(rewardAddress[requestId]).transferFrom(
            address(this),
            recipient,
            rewardId[requestId]
        );
        emit RecipientSelected(
            rewardAddress[requestId],
            rewardId[requestId],
            recipient
        );
        delete nftRecipientAddress[requestId];
        delete nftRecipientStart[requestId];
        delete nftRecipientEnd[requestId];
    }
}
