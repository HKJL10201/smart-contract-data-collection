pragma solidity ^0.5.0;

import "./DxMgnPool.sol";
contract Coordinator {

    DxMgnPool public dxMgnPool1;
    DxMgnPool public dxMgnPool2;

    constructor (
        ERC20 _token1,
        ERC20 _token2,
        IDutchExchange _dx,
        uint _poolingTime
    ) public {
        dxMgnPool1 = new DxMgnPool(_token1, _token2, _dx, _poolingTime);
        dxMgnPool2 = new DxMgnPool(_token2, _token1, _dx, _poolingTime);
    }

    function participateInAuction() public {
        dxMgnPool1.participateInAuction();
        dxMgnPool2.participateInAuction();
    }

    function canParticipate() public returns (bool) {
        uint auctionIndex = dxMgnPool1.dx().getAuctionIndex(
            address(dxMgnPool1.depositToken()),
            address(dxMgnPool1.secondaryToken())
        );
        // update the state before checking the currentState
        dxMgnPool1.checkForStateUpdate();
        // Since both auctions start at the same time, it suffices to check one.
        return auctionIndex > dxMgnPool1.lastParticipatedAuctionIndex() && dxMgnPool1.currentState() == DxMgnPool.State.Pooling;
    }

}
