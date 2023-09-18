// SPDX-License-Identifier: Apache License, Version 2.0
// Inspired by https://github.com/SetProtocol/index-coop-smart-contracts/blob/master/contracts/manager/ICManager.sol

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { ISetToken } from "@setprotocol/index-coop-contracts/contracts/interfaces/ISetToken.sol";
import { IStreamingFeeModule } from "@setprotocol/index-coop-contracts/contracts/interfaces/IStreamingFeeModule.sol";
import { MutualUpgrade } from "@setprotocol/index-coop-contracts/contracts/lib/MutualUpgrade.sol";
import { PreciseUnitMath } from "@setprotocol/index-coop-contracts/contracts/lib/PreciseUnitMath.sol";

import { ITradeModule } from "../interfaces/ITradeModule.sol";
import { IBinaryIndicator } from "../interfaces/IBinaryIndicator.sol";

/// @title Binary Indicator Manager 
/// @author pblivin0x
/// @notice Allocates Set Token between a risk-on asset and risk-off asset based on the signals of a binary indicator.
contract BinaryIndicatorManager is MutualUpgrade {
    using Address for address;
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeCast for int256;

    /* ============ Events ============ */

    /// @notice Emitted when streaming fees are accrued
    /// @param _totalFees         Total fees accrued
    /// @param _operatorTake      Operator take of the total fees
    /// @param _methodologistTake Methodologist take of the total fees
    event FeesAccrued(
        uint256 _totalFees,
        uint256 _operatorTake,
        uint256 _methodologistTake
    );

    /// @notice Emitted when the methodologist is changed
    /// @param _oldMethodologist Address of the old methodologist
    /// @param _newMethodologist Address of the new methodologist
    event MethodologistChanged(
        address _oldMethodologist,
        address _newMethodologist
    );

    /// @notice Emitted when the operator is changed
    /// @param _oldOperator Address of the old operator
    /// @param _newOperator Address of the new operator
    event OperatorChanged(
        address _oldOperator,
        address _newOperator
    );

    /// @notice Emitted when the keeper is changed
    /// @param _oldKeeper Address of the old keeper
    /// @param _newKeeper Address of the new keeper
    event KeeperChanged(
        address _oldKeeper,
        address _newKeeper
    );

    /// @notice Emitted when rebalance is called and the target allocation based on the trigger changes
    /// @param _wasBullish Boolean to indicate whether previous status was bullish (risk-on) or bearish (risk-off)
    /// @param _wasBullish Boolean to indicate whether new status is bullish (risk-on) or bearish (risk-off)
    event RiskStatusChanged(
        bool _wasBullish,
        bool _nowBullish
    );

    /// @notice Emitted when rebalance is called but the target allocation based on the trigger remains the same
    /// @param _isBullish Boolean to indicate whether the unchanged status is bullish (risk-on) or bearish (risk-off)
    event RiskStatusUnchanged(
        bool _isBullish
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "Must be methodologist");
        _;
    }

    /**
     * Throws if the sender is not the SetToken keeper
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "Must be keeper");
        _;
    }

    /* ============ State Variables ============ */

    // Address of the Set Token
    ISetToken public setToken;

    // Address of the Set Protocol TradeModule
    ITradeModule public tradeModule;

    // Address of the Set Protocol StreamingFeeModule
    IStreamingFeeModule public feeModule;

    // Address of the binary indicator contract to determine bullish/bearish signal
    IBinaryIndicator public binaryIndicator;

    // Address of operator which typically executes manager only functions on Set Protocol modules
    address public operator;

    // Address of methodologist which serves as manager of streaming fees
    address public methodologist;

    // Percent in 1e18 of streaming fees sent to operator
    uint256 public operatorFeeSplit;

    // Address of keeper which calls rebalance function when indicator status changes
    address public keeper;

    // Address of the component to allocate to when bullish (risk-on)
    address public riskOnComponent;

    // Address of the component to allocate to when bearish (risk-off)
    address public riskOffComponent;

    // Status of the binary indicator, updated every rebalance
    bool public isBullish;

    /* ============ Constructor ============ */

    /**
     * @notice Initialize new BinaryIndicatorManager instance
     * @param _setToken         Address of the Set Token
     * @param _tradeModule      Address of the Set Protocol TradeModule
     * @param _feeModule        Address of the Set Protocol StreamingFeeModule
     * @param _binaryIndicator  Address of the binary indicator contract to determine bullish/bearish signal
     * @param _operator         Address of operator which typically executes manager only functions on Set Protocol modules
     * @param _methodologist    Address of methodologist which serves as manager of streaming fees
     * @param _operatorFeeSplit Percent in 1e18 of streaming fees sent to operator
     * @param _keeper           Address of keeper which calls rebalance function when indicator status changes
     * @param _riskOnComponent  Address of the component to allocate to when bullish (risk-on)
     * @param _riskOffComponent Address of the component to allocate to when bearish (risk-off)
     * @param _isBullish        Initial status of binary indicator
     */
    constructor(
        ISetToken _setToken,
        ITradeModule _tradeModule,
        IStreamingFeeModule _feeModule,
        IBinaryIndicator _binaryIndicator,
        address _operator,
        address _methodologist,
        uint256 _operatorFeeSplit,
        address _keeper,
        address _riskOnComponent,
        address _riskOffComponent,
        bool _isBullish
    )
        public
    {
        require(
            _operatorFeeSplit <= PreciseUnitMath.preciseUnit(),
            "Operator Fee Split must be less than 1e18"
        );

        require(
            _setToken.isComponent(_riskOnComponent),
            "Risk On component must be in Set Token"
        );

        require(
            _setToken.isComponent(_riskOffComponent),
            "Risk Off component must be in Set Token"
        );

        setToken = _setToken;
        tradeModule = _tradeModule;
        feeModule = _feeModule;
        binaryIndicator = _binaryIndicator;
        operator = _operator;
        methodologist = _methodologist;
        operatorFeeSplit = _operatorFeeSplit;
        keeper = _keeper;
        riskOnComponent = _riskOnComponent;
        riskOffComponent = _riskOffComponent;
        isBullish = _isBullish;
    }

    /* ============ External Functions ============ */

    /**
     * Accrue fees from streaming fee module and transfer tokens to operator / methodologist addresses based on fee split
     */
    function accrueFeeAndDistribute() public {
        feeModule.accrueFee(setToken);

        uint256 setTokenBalance = setToken.balanceOf(address(this));

        uint256 operatorTake = setTokenBalance.preciseMul(operatorFeeSplit);
        uint256 methodologistTake = setTokenBalance.sub(operatorTake);

        setToken.transfer(operator, operatorTake);

        setToken.transfer(methodologist, methodologistTake);

        emit FeesAccrued(setTokenBalance, operatorTake, methodologistTake);
    }
    
    /**
     * OPERATOR OR METHODOLOGIST ONLY: Update the SetToken manager address. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newManager           New manager address
     */
    function updateManager(address _newManager) external mutualUpgrade(operator, methodologist) {
        require(_newManager != address(0), "Zero address not valid");
        setToken.setManager(_newManager);
    }

    /**
     * OPERATOR ONLY: Add a new module to the SetToken.
     *
     * @param _module           New module to add
     */
    function addModule(address _module) external onlyOperator {
        setToken.addModule(_module);
    }

    /**
     * OPERATOR ONLY: Remove a new module from the SetToken.
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module) external onlyOperator {
        setToken.removeModule(_module);
    }

    /**
     * @notice Rebalance set token allocation based on signal from binary indicator
     * @param _exchangeName           Human readable name of the exchange in the integrations registry
     * @param _data                   Arbitrary bytes to be used to construct trade call data
     */
    function rebalance(
        string memory _exchangeName,
        bytes memory _data
    ) 
        external 
        onlyKeeper 
    {
        bool updateIsBullish = binaryIndicator.isBullish();

        if (isBullish && !updateIsBullish) { 
            
            // Switch to bearish allocation
            uint sendUnits = setToken.getDefaultPositionRealUnit(riskOnComponent).toUint256();
            _trade(_exchangeName, riskOnComponent, sendUnits, riskOffComponent, 0, _data);
            emit RiskStatusChanged(isBullish, updateIsBullish);
            isBullish = updateIsBullish;

        } else if (!isBullish && updateIsBullish) { 
            
            // Switch to bullish allocation
            uint sendUnits = setToken.getDefaultPositionRealUnit(riskOffComponent).toUint256();
            _trade(_exchangeName, riskOffComponent, sendUnits, riskOnComponent, 0, _data);
            emit RiskStatusChanged(isBullish, updateIsBullish);
            isBullish = updateIsBullish;

        } else {

            // Trigger same as last rebalance, no trade takes place
            emit RiskStatusUnchanged(isBullish);
        }
    }

    /**
     * METHODOLOGIST ONLY: Update the streaming fee for the SetToken. Subject to timelock period agreed upon by the
     * operator and methodologist
     *
     * @param _newFee           New streaming fee percentage
     */
    function updateStreamingFee(uint256 _newFee) external onlyMethodologist {
        feeModule.updateStreamingFee(setToken, _newFee);
    }

    /**
     * OPERATOR OR METHODOLOGIST ONLY: Update the fee recipient address. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newFeeRecipient           New fee recipient address
     */
    function updateFeeRecipient(address _newFeeRecipient) external mutualUpgrade(operator, methodologist) {
        feeModule.updateFeeRecipient(setToken, _newFeeRecipient);
    }

    /**
     * OPERATOR OR METHODOLOGIST ONLY: Update the fee split percentage. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newFeeSplit           New fee split percentage
     */
    function updateFeeSplit(uint256 _newFeeSplit) external mutualUpgrade(operator, methodologist) {
        require(
            _newFeeSplit <= PreciseUnitMath.preciseUnit(),
            "Operator Fee Split must be less than 1e18"
        );

        // Accrue fee to operator and methodologist prior to new fee split
        accrueFeeAndDistribute();
        operatorFeeSplit = _newFeeSplit;
    }

    /**
     * OPERATOR ONLY: Update the trade module address
     *
     * @param _newTradeModule           New trade module address
     */
    function updateTradeModule(ITradeModule _newTradeModule) external onlyOperator {
        tradeModule = _newTradeModule;
    }

    /**
     * OPERATOR ONLY: Update the streaming fee module address
     *
     * @param _newStreamingFeeModule           New streaming fee module address
     */
    function updateStreamingFeeModule(IStreamingFeeModule _newStreamingFeeModule) external onlyOperator {
        feeModule = _newStreamingFeeModule;
    }

    /**
     * OPERATOR ONLY: Update the binary indicator address
     *
     * @param _newBinaryIndicator           New binary indicator address
     */
    function updateBinaryIndicator(IBinaryIndicator _newBinaryIndicator) external onlyOperator {
        binaryIndicator = _newBinaryIndicator;
    }

    /**
     * METHODOLOGIST ONLY: Update the methodologist address
     *
     * @param _newMethodologist           New methodologist address
     */
    function updateMethodologist(address _newMethodologist) external onlyMethodologist {
        emit MethodologistChanged(methodologist, _newMethodologist);
        methodologist = _newMethodologist;
    }

    /**
     * OPERATOR ONLY: Update the operator address
     *
     * @param _newOperator           New operator address
     */
    function updateOperator(address _newOperator) external onlyOperator {
        emit OperatorChanged(operator, _newOperator);
        operator = _newOperator;
    }

    /**
     * OPERATOR ONLY: Update the keeper address
     *
     * @param _newKeeper           New keeper address
     */
    function updateKeeper(address _newKeeper) external onlyOperator {
        emit KeeperChanged(keeper, _newKeeper);
        keeper = _newKeeper;
    }

    /* ============ External Getter Functions ============ */

    /**
     * @notice Get current status of binary indicator
     */
    function getIndicator() 
        public
        view
        returns (bool)
    {
        return binaryIndicator.isBullish();
    }

    /**
     * @notice Check if current status of binary indicator is different than last rebalance 
     */
    function getIndicatorIsChanged() 
        public
        view
        returns (bool)
    {
        return binaryIndicator.isBullish() != isBullish;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Executes a trade on a supported DEX. Only callable by the operator. 
     * @dev Although the SetToken units are passed in for the send and receive quantities, the total quantity
     * sent and received is the quantity of SetToken units multiplied by the SetToken totalSupply.
     *
     * @param _exchangeName         Human readable name of the exchange in the integrations registry
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _sendQuantity         Units of token in SetToken sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _minReceiveQuantity   Min units of token in SetToken to be received from the exchange
     * @param _data                 Arbitrary bytes to be used to construct trade call data
     */
    function _trade(
        string memory _exchangeName,
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _minReceiveQuantity,
        bytes memory _data
    ) internal {
        tradeModule.trade(setToken, _exchangeName, _sendToken, _sendQuantity, _receiveToken, _minReceiveQuantity, _data);
    }
}