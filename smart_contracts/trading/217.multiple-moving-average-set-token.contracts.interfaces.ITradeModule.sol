// SPDX-License-Identifier: Apache License, Version 2.0
// Custom trade module to interact with Set Protocol's TradeModule
// TradeModule: https://github.com/SetProtocol/set-protocol-v2/blob/master/contracts/protocol/modules/TradeModule.sol

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ISetToken } from "@setprotocol/index-coop-contracts/contracts/interfaces/ISetToken.sol";

import { IExchangeAdapter } from "@setprotocol/set-protocol-v2/contracts/interfaces/IExchangeAdapter.sol";

/// @title Trade Module interface for Set Protocol's TradeModule
/// @notice Module enables SetTokens to perform atomic trades using a DEX
interface ITradeModule {
    struct TradeInfo {
        ISetToken setToken;                             // Instance of SetToken
        IExchangeAdapter exchangeAdapter;               // Instance of exchange adapter contract
        address sendToken;                              // Address of token being sold
        address receiveToken;                           // Address of token being bought
        uint256 setTotalSupply;                         // Total supply of SetToken in Precise Units (10^18)
        uint256 totalSendQuantity;                      // Total quantity of sold token (position unit x total supply)
        uint256 totalMinReceiveQuantity;                // Total minimum quantity of token to receive back
        uint256 preTradeSendTokenBalance;               // Total initial balance of token being sold
        uint256 preTradeReceiveTokenBalance;            // Total initial balance of token being bought
    }

    /// @notice Initialize trade module
    /// @notice Necessary to complete the process of adding a module
    function initialize(ISetToken _setToken) external;

    /**
     * @notice Trade underlying collateral
     * @notice Executes a trade on a supported DEX. Only callable by the operator. 
     * @dev Although the SetToken units are passed in for the send and receive quantities, the total quantity
     * sent and received is the quantity of SetToken units multiplied by the SetToken totalSupply.
     *
     * @param _setToken             Instance of the SetToken to trade
     * @param _exchangeName         Human readable name of the exchange in the integrations registry
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _sendQuantity         Units of token in SetToken sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _minReceiveQuantity   Min units of token in SetToken to be received from the exchange
     * @param _data                 Arbitrary bytes to be used to construct trade call data
     */
    function trade(ISetToken _setToken, 
                   string memory _exchangeName, 
                   address _sendToken, 
                   uint256 _sendQuantity,
                   address _receiveToken,
                   uint256 _minReceiveQuantity,
                   bytes memory _data
    ) external;
}