

interface IThorChainRouter {
    function swap(
        address _srcToken,
        address _dstToken,
        uint256 _srcAmount,
        uint256 _minDstAmount,
        address _recipient
    ) external returns (uint256);
}
contract ThorChainAggregator {
    address public ETH_ADDRESS;
    address public BSC_ADDRESS;
    address public POLYGON_ADDRESS;
    address public THORCHAIN_ADDRESS;
    IThorChainRouter public thorChainRouter;
    event Swap(
        address indexed srcToken,
        address indexed dstToken,
        uint256 srcAmount,
        uint256 dstAmount,
        address indexed recipient
    );
    constructor(
        address _thorChainRouter,
        address _ethAddress,
        address _bscAddress,
        address _polygonAddress,
        address _thorChainAddress
    ) {
        thorChainRouter = IThorChainRouter(_thorChainRouter);
        ETH_ADDRESS = _ethAddress;
        BSC_ADDRESS = _bscAddress;
        POLYGON_ADDRESS = _polygonAddress;
        THORCHAIN_ADDRESS = _thorChainAddress;
    }
    function swapTokens(
        address _srcToken,
        address _dstToken,
        uint256 _srcAmount,
        uint256 _minDstAmount,
        address _recipient
    ) external {
        require(
            _srcToken == ETH_ADDRESS ||
                _srcToken == BSC_ADDRESS ||
                _srcToken == POLYGON_ADDRESS ||
                _srcToken == THORCHAIN_ADDRESS,
            "Unsupported source token"
        );
        require(
            _dstToken == ETH_ADDRESS ||
                _dstToken == BSC_ADDRESS ||
                _dstToken == POLYGON_ADDRESS ||
                _dstToken == THORCHAIN_ADDRESS,
            "Unsupported destination token"
        );
        require(_recipient != address(0), "Recipient address cannot be zero");
        if (_srcToken != ETH_ADDRESS) {
            IERC20(_srcToken).transferFrom(
                msg.sender,
                address(this),
                _srcAmount
            );
            IERC20(_srcToken).approve(address(thorChainRouter), _srcAmount);
        }
        uint256 dstAmount = thorChainRouter.swap(
            _srcToken,
            _dstToken,
            _srcAmount,
            _minDstAmount,
            _recipient
        );
        require(dstAmount >= _minDstAmount, "Insufficient output amount");
        emit Swap(_srcToken, _dstToken, _srcAmount, dstAmount, _recipient);
    }
}
