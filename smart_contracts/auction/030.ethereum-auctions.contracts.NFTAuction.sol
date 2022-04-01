pragma solidity ^0.4.18;

import "./Auction.sol";
import "./interfaces/EIP821/IAssetHolder.sol";

contract NFTAuction is Auction, IAssetHolder {

    event AuctionStarted(address bidToken, address token, uint asset);

    NFTRegistry public assetRegistry;
    uint256 public assetId;

    function initNFT(
        address _assetRegistry,
        uint256 _assetId
    ) uninitialized external
    {
        assetRegistry = NFTRegistry(_assetRegistry);
        assetId = _assetId;
        setInterfaceImplementation("IAssetHolder", this);
    }

    function untrustedTransferItem(address receiver) internal {
        assetRegistry.transfer(receiver, assetId);
    }

    function funded() public view returns (bool) {
        return assetRegistry.ownerOf(assetId) == address(this);
    }

    function logStart() internal {
        AuctionStarted(bidToken(), assetRegistry, assetId);
    }

    function untrustedTransferExcessAuctioned(address receiver, address registry, uint asset) internal returns (bool notAuctioned) {
        if (NFTRegistry(registry) == assetRegistry && asset == assetId) {
            if (!started()) {
                assetRegistry.transfer(receiver, assetId);
            }
            return false;
        } else {
            return true;
        }
    }

    function onAssetReceived(uint256 _assetId, address _previousHolder, address _currentHolder, bytes, address, bytes) public {
        require(this == _currentHolder);
        require(beneficiary == _previousHolder);
        require(assetRegistry == msg.sender);
        require(assetId == _assetId);
    }
}