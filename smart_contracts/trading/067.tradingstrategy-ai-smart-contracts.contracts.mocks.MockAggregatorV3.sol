import "../interfaces/AggregatorV3Interface.sol";

contract MockAggregatorV3 is AggregatorV3Interface {

    constructor() public {

    }

    function decimals() external view override returns (uint8) {
        revert("Unsupported");
    }

    function description() external view override returns (string memory) {
        revert("Unsupported");
    }

    function version() external view override returns (uint256) {
        revert("Unsupported");
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        revert("Unsupported");
    }

    function latestRoundData()
    external
    view
    override
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        revert("Unsupported");
    }

}
