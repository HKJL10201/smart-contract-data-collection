// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract user is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _counter;
    address public _XpTokenAddress; ///////XpToken ADDRESS SAVES HERE

    struct InfoXP {
        uint16 G_code;
        uint16 B_code;
        /////uint256 counter; //////////IT WILL BE USEFUL IF WE DECIDED TO GO WITH(!!3) DP ALGO  --- !!4
        uint256 XpNumber;
        uint256 Date;
    }

    struct InfoBurnXP {
        uint16 B_code;
        /////uint256 counter; //////////IT WILL BE USEFUL IF WE DECIDED TO GO WITH(!!3) DP ALGO  --- !!4
        uint256 XpNumber;
        uint256 Date;
        address Address;
    }

    mapping(address => InfoXP[]) public GainHistory;
    mapping(address => InfoXP[]) public BurnHistory;
    mapping(uint256 => InfoBurnXP) public BurnHistoryWithOrder;

    function GetUserGainList(address account)
        public
        view
        returns (InfoXP[] memory)
    {
        InfoXP[] memory list = GainHistory[account];
        return list;
    }

    function GetBurnHistoryList(address account)
        public
        view
        returns (InfoXP[] memory)
    {
        InfoXP[] memory list = BurnHistory[account];
        return list;
    }

    function AddXpToGainHistory(
        address account,
        uint16 g_code,
        uint256 amount
    ) public {
        require(
            msg.sender == _XpTokenAddress,
            "msg sender should be the XpToken contract"
        );
        GainHistory[account].push(InfoXP(g_code, 0, amount, block.timestamp));
    }

    function AddXpToBurnList(
        address account,
        uint16 b_code,
        uint256 amount
    ) public {
        require(
            msg.sender == _XpTokenAddress,
            "msg sender should be the XpToken contract"
        );
        BurnHistoryWithOrder[_counter.current()] = (
            InfoBurnXP(b_code, amount, block.timestamp, account)
        );
        BurnHistory[account].push(InfoXP(b_code, 0, amount, block.timestamp));
        _counter.increment();
    }

    ////////////////////////////////////////////THIS FUNCTION IS JUST FOR TEST PURPOSES(!!0) --- !!1
    function setAddress(address add) public onlyOwner {
        _XpTokenAddress = add;
    }
}
