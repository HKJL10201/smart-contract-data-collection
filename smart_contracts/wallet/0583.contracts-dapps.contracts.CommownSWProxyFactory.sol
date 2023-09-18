// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CommownSW.sol";
import {slice, toUint256, toAddress} from "./BytesUtils.sol";

/// @title Commown Shared Wallet Proxy Factory
/// @author Aurélien ALBE - Younès MANJAL 😎
/// @notice Proxy factory contract for creation of a Commown Shared Wallet
/// @dev Proxy factory contract. State variables stored in the proxy. Logic will be in the Commown Shared Wallet contract.
contract CommownSWProxyFactory is Ownable {
    /// @notice Emitted when a proxy is created
    /// @dev Emitted when a proxy is created, can be use for front end purpose to get owners
    /// @param adrs Proxy's address created
    /// @param owners Owners of the proxy created
    event ProxyCreated(address indexed adrs, address[] owners);

    /// @dev Logic contract : address of the CommownSW.sol deployed
    address public logic;

    /// @notice A user can have several CommownSW so several proxies
    /// @dev mapping of user => proxy address
    mapping(address => address[]) public commownProxiesPerUser;

    /// @notice A user can have several CommownSW so several proxies
    /// @dev mapping of user => number of proxy address
    mapping(address => uint256) public nbProxiesPerUser;

    /// @dev list of all proxies
    address[] public proxiesList;

    /// @notice constructor of the factory
    /// @dev constructor of the factory : has to change to un upgradable contract, or to permit the upgrade of the immutable logic main contract
    constructor() {
        logic = address(new CommownSW());
    }

    function defineNewLogic(address _contract) public onlyOwner {
        logic = _contract;
    }

    /// @notice function called from the front when you create a commown shared wallet
    /// @dev Function to call when you want to create a proxy for owners
    /// @param _data bytes data composed of the selector function the proxy will initialize, and parameters : owners' array, number of confirmation and owners
    /// @return address of the proxy
    function createProxy(bytes calldata _data) external returns (address) {
        //address[] memory _owners, uint8 _confirmationNeeded,
        //Exemple : initial message
        //0xeb53a05700000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000002000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922660000000000000000000000000000000000000000000000000000000000000003000000000000000000000000bda5747bfd65f08deb54cb465eb87d40e51b197e000000000000000000000000dd2fd4581271e230360230f9337d5c0430bf44c00000000000000000000000008626f6940e2eb28930efb4cef49b2d1f2c9c1199

        //It can be decomposed in chunks of 32 bytes after the first 4bytes
        //eb53a057 															> bytes memory _selector  = slice(_data, 0, 4);
        //0000000000000000000000000000000000000000000000000000000000000060	> position of the array in the bytes
        //																	  uint256 _uint256positionOwners = toUint256(slice(_params, 0, 32));

        //0000000000000000000000000000000000000000000000000000000000000002  > second param "confirmation needed" as it is a value, it is directly printed
        //																	  uint8 __uint8confirmationN = uint8(toUint256(slice(_params,32,32)));

        //000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266	> third param is the owner() of both contracts
        //																	  address own = toAddress(slice(_params,64,32),12);

        //0000000000000000000000000000000000000000000000000000000000000003  > we are at the 96dec = 60hex, here defines the length of the array of owners
        //																	  uint8 __uint8size = uint8(toUint256(slice(_params,_uint256positionOwners,32)));

        //000000000000000000000000bda5747bfd65f08deb54cb465eb87d40e51b197e  > owners[0]
        //000000000000000000000000dd2fd4581271e230360230f9337d5c0430bf44c0	> owners[1]
        //0000000000000000000000008626f6940e2eb28930efb4cef49b2d1f2c9c1199	> owners[2]

        bytes memory _params = slice(_data, 4, _data.length - 4);

        uint256 _uint256positionOwners = toUint256(slice(_params, 0, 32));

        uint8 __uint8size = uint8(
            toUint256(slice(_params, _uint256positionOwners, 32))
        );
        require(__uint8size <= 255 && __uint8size > 0, "_owners.length wrong");

        //Usage of the ERC1967Proxy
        //Initialisation of the proxy by calling the initialize function with selector
        ERC1967Proxy proxy = new ERC1967Proxy(logic, _data);

        //Add the proxy to the global list
        proxiesList.push(address(proxy));

        //Declare an __owners array of size determine by __uint8size visible at _uint256positionOwners
        address[] memory __owners = new address[](__uint8size);

        for (uint8 i; i < __uint8size; i++) {
            //Get the owners from the data bytes starting at _uint256positionOwners+32
            //Because the _uint256positionOwners shows the size of the array
            __owners[i] = toAddress(
                slice(_params, _uint256positionOwners + 32 + (i * 32), 32),
                12
            );

            //For each owner add the proxy and increment the proxy number by 1
            commownProxiesPerUser[__owners[i]].push(address(proxy));
            nbProxiesPerUser[__owners[i]] += 1;
        }

        //Emit the event
        emit ProxyCreated(address(proxy), __owners);
        return address(proxy);
    }
}
