//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ITicket.sol";
import "./TicketProxy.sol";

error OnlyOneTicketAtTime();

contract TicketFactory is Ownable {
    /**
     * @dev addresses of beacon and vrf consumer
     */
    address public immutable BEACON_ADDRESS;
    address public immutable VRF_CONSUMER;
    address[] _deployedTicketProxies;

    event NewLotteryDeployed(address indexed newLottery);

    /// @notice Constructs the contract setting the needed dependecies' addresses
    constructor(address _beaconAddress, address _vrfConsumerAddress) {
        BEACON_ADDRESS = _beaconAddress;
        VRF_CONSUMER = _vrfConsumerAddress;
    }

    /**
      @notice Deploys new ticket proxies
      @param _name The name passed to the proxy initizaling function
      @param _symbol The symbol passed to the proxy initizaling function
      @param _start The start block number passed to the proxy initizaling function
      @param _end The end block number passed to the proxy initizaling function
      @param _ticketPrice The ticket price passed to the proxy initizaling function
      @dev Invokes deployTicketProxyDeterministic() passing 0 as _salt in order to deploy the new proxy using just "create"
     */

    function deployTicketProxy(
        string calldata _name,
        string calldata _symbol,
        uint64 _start,
        uint64 _end,
        uint128 _ticketPrice
    ) external onlyOwner {
        deployTicketProxyDeterministic(
            _name,
            _symbol,
            _start,
            _end,
            _ticketPrice,
            0
        );
    }

    /// @notice Deploys new ticket proxies using "create2"
    /// @param _salt The salt passed to "create2" in order to form the address of the new proxy
    /// @dev If _salt == 0 does not use "create2"
    function deployTicketProxyDeterministic(
        string calldata _name,
        string calldata _symbol,
        uint64 _start,
        uint64 _end,
        uint128 _ticketPrice,
        uint256 _salt
    ) public onlyOwner {
        address _latestTicketProxy = latestTicketProxy();
        if (
            _latestTicketProxy != address(0x0) &&
            !ITicket(_latestTicketProxy).finished()
        ) revert OnlyOneTicketAtTime();

        address newTicketProxy;
        _salt == 0
            ? newTicketProxy = address(new TicketProxy(BEACON_ADDRESS))
            : newTicketProxy = address(
            new TicketProxy{salt: bytes32(_salt)}(BEACON_ADDRESS)
        );

        ITicket(newTicketProxy).initialize(
            _name,
            _symbol,
            _start,
            _end,
            _ticketPrice,
            VRF_CONSUMER
        );
        _deployedTicketProxies.push(newTicketProxy);

        emit NewLotteryDeployed(newTicketProxy);
    }

    /// @notice Returns an array of the addresses of all the deployed proxies ever
    /// @return _deployedTicketProxies All the deployed proxies ever
    function deployedTicketProxies() public view returns (address[] memory) {
        return _deployedTicketProxies;
    }

    /// @notice Returns the latest ticket proxy deployed
    /// @return _latestTicketProxy The latest ticket proxy deployed
    function latestTicketProxy()
        public
        view
        returns (address _latestTicketProxy)
    {
        address[] memory deployedTicketProxies_ = _deployedTicketProxies;
        deployedTicketProxies_.length == 0
            ? _latestTicketProxy = address(0x0)
            : _latestTicketProxy = deployedTicketProxies_[
            deployedTicketProxies_.length - 1
        ];
    }
}
