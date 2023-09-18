// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";


contract AirdropWF is Pausable, ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    using SafeMath for uint;

    uint256 public volume;
    bytes32 private jobId;
    uint256 private fee;

    event RequestVolume(bytes32 indexed requestId, uint256 volume);
    event Received(address, uint);


    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xdd6c758869b9AFFdE9dd234A85008BDDA2C5a5d0);
        jobId = "5ab5809787c74577bd4d363535e1f7a8";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     */
    function requestVolumeData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add(
            "get",
            "https://hwmc-34.ew.r.appspot.com/"
        );

  
        req.add("path", "Airdropped"); // Chainlink nodes 1.0.0 and later support this format



        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        uint256 _volume
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, _volume);
        volume = _volume;
    }

      //Distribution of Matic According to no. of NFTs they hold
     function airDropAmountsNew(address payable[] memory _holders, uint[] memory _amnts) public onlyOwner {
        require(_holders.length == _amnts.length);
        uint n = _holders.length;


        for (uint i = 0; i < n; i++) {
            uint eachEth = _amnts[i];
            _holders[i].transfer(eachEth);
            
        }
    }

    // Distribute Matic equally to a set of addresses
    function airDrop(address payable[] memory _addrs) public onlyOwner {
        uint nAddrs = _addrs.length;
        uint totalEth = payable(address(this)).balance;
        uint eachEth = totalEth / nAddrs;
        uint remainEth = totalEth;
        for (uint i = 0; i < nAddrs - 1; i += 1) {
            _addrs[i].transfer(eachEth);
            remainEth -= eachEth;
        }
        _addrs[nAddrs - 1].transfer(remainEth);
    }
    

     receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
