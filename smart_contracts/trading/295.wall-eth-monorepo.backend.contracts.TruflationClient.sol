// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract TruflationClient is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    address public oracleId;
    string public jobId;
    uint256 public fee;

    int256 public inflation;
    uint256 public lastTimeStamp; // in seconds

    // Please refer to
    // https://github.com/truflation/quickstart/blob/main/network.md
    // for oracle address. job id, and fee for a given network

    // use this for Goerli (chain: 5)
    constructor(
        address link_, // 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        address oracleId_, // 0xcf72083697aB8A45905870C387dC93f380f2557b
        string memory jobId_, // 8b459447262a4ccf8863962e073576d9
        uint256 fee_ // 0,01 LINK
    ) ConfirmedOwner(msg.sender) {
        setChainlinkToken(link_);

        oracleId = oracleId_;
        jobId = jobId_;
        fee = fee_;
    }

    // This will require a int256 rather than a uint256 as inflation
    // can be negative
    function requestInflation() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            bytes32(bytes(jobId)),
            address(this),
            this.fulfillInflation.selector
        );

        req.add('service', 'truflation/current');
        req.add('keypath', 'yearOverYearInflation');
        req.add('abi', 'int256');
        req.add('multiplier', '1000000000000000000'); // 10**18

        return sendChainlinkRequestTo(oracleId, req, fee);
    }

    function transferAndRequestInflation() public returns (bytes32 requestId) {
        require(
            LinkTokenInterface(getChainlinkToken()).transferFrom(msg.sender, address(this), fee),
            'transfer failed'
        );

        Chainlink.Request memory req = buildChainlinkRequest(
            bytes32(bytes(jobId)),
            address(this),
            this.fulfillInflation.selector
        );

        req.add('service', 'truflation/current');
        req.add('keypath', 'yearOverYearInflation');
        req.add('abi', 'int256');
        req.add('multiplier', '1000000000000000000'); // 10**18
        req.add('refundTo', Strings.toHexString(uint160(msg.sender), 20));

        return sendChainlinkRequestTo(oracleId, req, fee);
    }

    function fulfillInflation(bytes32 _requestId, bytes memory _inflation)
        public
        recordChainlinkFulfillment(_requestId)
    {
        inflation = toInt256(_inflation);
        lastTimeStamp = block.timestamp;
    }

    function toInt256(bytes memory _bytes) internal pure returns (int256 value) {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function changeOracle(address _oracle) public onlyOwner {
        oracleId = _oracle;
    }

    function changeJobId(string memory _jobId) public onlyOwner {
        jobId = _jobId;
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }
}
