pragma solidity 0.5.3;

import "./Pool.sol";

contract Factory {
    // @notice some structures to keep track of what pairs have been created
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    // @notice an event indicating when a pair has been created
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address quoting,
        address dex,
        bytes32 tickerQ,
        bytes32 tickerT
    ) external returns (address pair) {
        // Require conditions
        require(tickerQ == "PIN", "First token in pair is not quote token");
        require(tokenA != tokenB, "Identical addresses");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        uint256 whichP = tokenA < tokenB ? 1 : 2;
        require(
            tokenA != address(0) &&
                tokenB != address(0) &&
                quoting != address(0) &&
                dex != address(0),
            "Zero address error"
        );
        require(
            getPair[token0][token1] == address(0) || getPair[token1][token0] == address(0),
            "Pair already exists"
        );

        // Deploy a smart contract using a create2 opcode in assembly.
        bytes memory bytecode = type(Pool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Initialize the pool properly, and record the pair created properly in this contract.
        Pool(pair).initialize(token0, token1, dex, whichP, tickerQ, tickerT);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}
