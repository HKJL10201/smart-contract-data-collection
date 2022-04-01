pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@nomiclabs/buidler/console.sol";
import "./interface/Aave/aToken.sol";
import "./interface/Aave/ILendingPool.sol";
import "./interface/Aave/ILendingPoolAddressesProvider.sol";
import "./interface/IUniversity.sol";
import "./interface/IStudent.sol";
import "./interface/IClassroom.sol";
import "./interface/IStudentApplication.sol";
import "./interface/IClassroomChallenge.sol";
import "./interface/IStudentApplicationFactory.sol";
import "./MyUtils.sol";


contract Classroom is Ownable, ChainlinkClient, IClassroom {
    IUniversity public university;
    bool public openForApplication;
    bool public courseFinished;
    bool public classroomActive;
    uint256 public startDate;
    bool _timestampAlarm;
    address[] _studentApplications;
    address[] _validStudentApplications;
    mapping(address => address) _studentApplicationsLink;
    uint256 _endDate;
    uint256 _courseBalance;
    bytes32 _seed;

    //Classroom parameters
    bytes32 public name;
    uint24 public principalCut;
    uint24 public poolCut;
    int32 public minScore;
    uint256 public override entryPrice;
    uint256 public duration;
    uint256 public compoundApplyPercentage;
    address public challengeAddress;

    //Tokens
    address public daiToken;
    address public cDAI;

    //Factory
    IStudentApplicationFactory public studentApplicationFactory;

    //Chainlink config
    address public oracleRandom;
    bytes32 public requestIdRandom;
    uint256 public oraclePaymentRandom;
    address public oracleTimestamp;
    bytes32 public requestIdTimestamp;
    uint256 public oraclePaymentTimestamp;
    address public linkToken;

    //Uniswap Config
    address public uniswapDAI;
    address public uniswapLINK;
    IUniswapV2Router01 public uniswapRouter;

    //Aave Config
    ILendingPoolAddressesProvider public aaveProvider;
    ILendingPool public aaveLendingPool;
    address public aaveLendingPoolCore;
    address public aTokenDAI;

    constructor(
        bytes32 name_,
        uint24 principalCut_,
        uint24 poolCut_,
        int32 minScore_,
        uint256 entryPrice_,
        uint256 duration_,
        address payable universityAddress,
        address challengeAddress_,
        address daiAddress,
        address compoundDAIAddress,
        address studentApplicationFactoryAddress
    ) public {
        name = name_;
        principalCut = principalCut_;
        poolCut = poolCut_;
        minScore = minScore_;
        entryPrice = entryPrice_;
        duration = duration_;
        compoundApplyPercentage = 0.5 * 1e6;
        university = IUniversity(universityAddress);
        challengeAddress = challengeAddress_;
        openForApplication = false;
        classroomActive = false;
        daiToken = daiAddress;
        cDAI = compoundDAIAddress;
        studentApplicationFactory = IStudentApplicationFactory(
            studentApplicationFactoryAddress
        );
    }

    event LogOpenApplications();
    event LogCloseApplications();
    event LogCourseFinished();
    event LogChangeChallenge(address);
    event LogChangeName(bytes32);
    event LogChangePrincipalCut(uint24);
    event LogChangePoolCut(uint24);
    event LogChangeMinScore(int32);
    event LogChangeEntryPrice(uint256);
    event LogChangeDuration(uint256);

    // @dev "Stack too deep" error if done in the constructor
    function configureOracles(
        address oracleRandom_,
        bytes32 requestIdRandom_,
        uint256 oraclePaymentRandom_,
        address oracleTimestamp_,
        bytes32 requestIdTimestamp_,
        uint256 oraclePaymentTimestamp_,
        address linkToken_,
        bool generateSeed
    ) public onlyOwner {
        oracleRandom = oracleRandom_;
        requestIdRandom = requestIdRandom_;
        oraclePaymentRandom = oraclePaymentRandom_;
        oracleTimestamp = oracleTimestamp_;
        requestIdTimestamp = requestIdTimestamp_;
        oraclePaymentTimestamp = oraclePaymentTimestamp_;
        linkToken = linkToken_;
        setChainlinkToken(linkToken_);
        require(
            LinkTokenInterface(linkToken).balanceOf(address(this)) >=
                oraclePaymentRandom,
            "Classroom: not enough Link tokens"
        );
        if (generateSeed) _generateSeed();
        else _seed = blockhash(0);
    }

    function configureUniswap(
        address uniswapDAI_,
        address uniswapLINK_,
        address uniswapRouter_
    ) public onlyOwner {
        uniswapDAI = uniswapDAI_;
        uniswapLINK = uniswapLINK_;
        uniswapRouter = IUniswapV2Router01(uniswapRouter_);
    }

    function configureAave(address lendingPoolAddressesProvider)
        public
        onlyOwner
    {
        aaveProvider = ILendingPoolAddressesProvider(
            lendingPoolAddressesProvider
        );
        aaveLendingPoolCore = aaveProvider.getLendingPoolCore();
        aaveLendingPool = ILendingPool(aaveProvider.getLendingPool());
        aTokenDAI = ILendingPoolCore(aaveLendingPoolCore)
            .getReserveATokenAddress(daiToken);
    }

    function transferOwnershipClassroom(address newOwner) public override {
        transferOwnership(newOwner);
    }

    function ownerClassroom() public view override returns (address) {
        return owner();
    }

    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    function changePrincipalCut(uint24 val) public onlyOwner {
        principalCut = val;
        emit LogChangePrincipalCut(principalCut);
    }

    function changePoolCut(uint24 val) public onlyOwner {
        poolCut = val;
        emit LogChangePoolCut(poolCut);
    }

    function changeMinScore(int32 val) public onlyOwner {
        minScore = val;
        emit LogChangeMinScore(minScore);
    }

    function changeEntryPrice(uint256 val) public onlyOwner {
        entryPrice = val;
        emit LogChangeEntryPrice(entryPrice);
    }

    function changeDuration(uint256 val) public onlyOwner {
        duration = val;
        emit LogChangeDuration(duration);
    }

    function changeCompoundApplyPercentage(uint256 ppm) public onlyOwner {
        require(ppm <= 1e6, "Classroom: can't be more that 100% in ppm");
        compoundApplyPercentage = ppm;
    }

    function changeChallenge(address addr) public onlyOwner {
        require(isClassroomEmpty(), "Classroom: can't change challenge now");
        challengeAddress = addr;
        emit LogChangeChallenge(challengeAddress);
    }

    function viewMyApplication() public view override returns (address) {
        return viewApplication(_msgSender());
    }

    function viewApplication(address addr) public view returns (address) {
        require(
            addr == _msgSender() || _msgSender() == owner(),
            "Classroom: read permission denied"
        );
        return _studentApplicationsLink[addr];
    }

    function isClassroomEmpty() public view returns (bool) {
        return
            _studentApplications.length.add(_validStudentApplications.length) ==
            0;
    }

    function isCourseOngoing() public view returns (bool) {
        return _validStudentApplications.length > 0;
    }

    function openApplications() public onlyOwner {
        require(oracleRandom != address(0), "Classroom: setup oracles first");
        require(uniswapDAI != address(0), "Classroom: setup Uniswap first");
        require(
            aaveLendingPoolCore != address(0),
            "Classroom: setup Aave first"
        );
        require(
            !openForApplication,
            "Classroom: applications are already opened"
        );
        require(
            _studentApplications.length == 0,
            "Classroom: students list not empty"
        );
        require(
            LinkTokenInterface(linkToken).balanceOf(address(this)) >=
                oraclePaymentTimestamp,
            "Classroom: not enough Link tokens"
        );
        openForApplication = true;
        emit LogOpenApplications();
    }

    function closeApplications() public onlyOwner {
        require(
            openForApplication,
            "Classroom: applications are already closed"
        );
        openForApplication = false;
        emit LogCloseApplications();
    }

    //public onlyOwner allow the professor to apply money before and after closing applications
    function applyDAI() public onlyOwner {
        uint256 balance = IERC20(daiToken).balanceOf(address(this));
        if (balance <= 0) return;
        uint256 compoundApply = compoundApplyPercentage.mul(balance).div(1e6);
        uint256 aaveApply = balance.sub(compoundApply);
        applyFundsCompound(compoundApply);
        applyFundsAave(aaveApply);
    }

    function applyFundsCompound(uint256 val) public onlyOwner {
        if (val == 0) return;
        TransferHelper.safeApprove(daiToken, cDAI, val);
        CERC20(cDAI).mint(val);
    }

    function applyFundsAave(uint256 val) public onlyOwner  {
        if (val == 0) return;
        TransferHelper.safeApprove(
            daiToken,
            aaveLendingPoolCore,
            val
        );
        aaveLendingPool.deposit(daiToken, val, 0);
    }

    function studentApply() public override {
        require(
            IStudent(_msgSender()).ownerStudent() != owner(),
            "Classroom: professor can't be its own student"
        );
        require(
            university.studentIsRegistered(_msgSender()),
            "Classroom: student is not registered"
        );
        IStudent applicant = IStudent(_msgSender());
        require(
            applicant.score() >= minScore,
            "Classroom: student doesn't have enough score"
        );
        require(openForApplication, "Classroom: applications closed");
        address application = _createStudentApplication(address(applicant));
        _studentApplications.push(application);
    }

    function _createStudentApplication(address student)
        internal
        returns (address)
    {
        address newApplication = studentApplicationFactory
            .newStudentApplication(
            student,
            address(this),
            address(daiToken),
            challengeAddress,
            generateNewSeed()
        );
        _studentApplicationsLink[student] = newApplication;
        university.registerStudentApplication(student, newApplication);
        return newApplication;
    }

    function generateNewSeed() internal returns (bytes32) {
        _mutateSeed();
        return keccak256(abi.encode(blockhash(0) ^ _seed));
    }

    function countNewApplications()
        public
        view
        onlyOwner
        returns (uint256 count)
    {
        for (uint256 i = 0; i < _studentApplications.length; i++) {
            if (
                IStudentApplication(_studentApplications[i])
                    .applicationState() == 0
            ) count++;
        }
    }

    function countReadyApplications()
        public
        view
        onlyOwner
        returns (uint256 count)
    {
        for (uint256 i = 0; i < _studentApplications.length; i++) {
            if (
                IStudentApplication(_studentApplications[i])
                    .applicationState() == 1
            ) count++;
        }
    }

    function countActiveApplications()
        public
        view
        onlyOwner
        returns (uint256 count)
    {
        return _validStudentApplications.length;
    }

    function beginCourse(bool setAlatm)
        public
        onlyOwner
    {
        require(!openForApplication, "Classroom: applications are still open");
        require(!classroomActive, "Classroom: course already open");
        require(
            IERC20(daiToken).balanceOf(address(this)) == 0,
            "Classroom: invest all balance before begin"
        );
        checkApplications();
        _studentApplications = new address[](0);
        if (_validStudentApplications.length == 0) return;
        classroomActive = true;
        startDate = block.timestamp;
        if (setAlatm) _setAlarm();
        else _timestampAlarm = true;
    }

    function checkApplications() internal {
        for (uint256 i = 0; i < _studentApplications.length; i++) {
            if (
                IStudentApplication(_studentApplications[i])
                    .applicationState() == 1
            ) {
                IStudentApplication(_studentApplications[i]).activate();
                _validStudentApplications.push(_studentApplications[i]);
            } else {
                IStudentApplication(_studentApplications[i]).expire();
            }
        }
    }

    function finishCourse() public onlyOwner {
        require(
            _validStudentApplications.length > 0,
            "Classroom: no applications"
        );
        require(_timestampAlarm, "Classroom: too soon to finish course");
        _courseBalance = IERC20(daiToken).balanceOf(address(this));
        _recoverInvestment();
        courseFinished = true;
        emit LogCourseFinished();
    }

    function courseBalance() public view onlyOwner() returns (uint256) {
        return
            courseFinished
                ? IERC20(daiToken).balanceOf(address(this)).sub(_courseBalance)
                : 0;
    }

    function _recoverInvestment() internal {
        uint256 balanceCompound = CERC20(cDAI).balanceOf(address(this));
        CERC20(cDAI).redeem(balanceCompound);
        uint256 balanceAave = aToken(aTokenDAI).balanceOf(address(this));
        aToken(aTokenDAI).redeem(balanceAave);
    }

    uint256 public coursePostBalance;
    uint256 public successCount;
    uint256 public emptyCount;
    uint256 public universityCut;
    uint256[] public studentAllowances;

    uint16 _processPhase;

    function viewProcessPhase() public view returns (uint16) {
        if (!courseFinished) return (uint16(-1));
        return _processPhase;
    }

    /*
    processResults();
    startAnswerVerification();
    accountValues();
    resolveStudentAllowances();
    resolveUniversityCut();
    updateStudentScores();
    endProcessResults();
    */
    function processResults() public {
        require(courseFinished, "Classroom: course not finished");
        coursePostBalance = courseBalance();
        require(
            coursePostBalance >= entryPrice.mul(_validStudentApplications.length),
            "Classroom: not enough DAI to proceed"
        );
        _processPhase = 1;
        studentAllowances = new uint256[](_validStudentApplications.length);
    }

    function startAnswerVerification() public  {
        require(_processPhase > 0, "Classroom: call processResults first");
        require(_processPhase < 2, "Classroom: step already done");
        _startAnswerVerification();
        _processPhase = 2;
    }

    function _startAnswerVerification() internal {
        assert(_processPhase == 1);
        for (uint256 i = 0; i < _validStudentApplications.length; i++) {
            IStudentApplication(_validStudentApplications[i])
                .registerFinalAnswer();
            uint256 appState = IStudentApplication(_validStudentApplications[i])
                .applicationState();
            if (appState == 3) successCount++;
            if (appState == 5) emptyCount++;
        }
    }

    function accountValues() public {
        require(_processPhase > 1, "Classroom: call startAnswerVerification first");
        require(_processPhase < 3, "Classroom: step already done");
        _accountValues();
        _processPhase = 3;
    }

    function _accountValues()
        internal
    {
        assert(_processPhase == 2);
        uint256 nStudents = _validStudentApplications.length;
        uint256 returnsPool = coursePostBalance.sub(entryPrice.mul(nStudents));
        uint256 professorPaymentPerStudent = entryPrice.mul(principalCut).div(
            1e6
        );
        uint256 studentPrincipalReturn = entryPrice.sub(
            professorPaymentPerStudent
        );
        uint256 successPool = returnsPool.mul(successCount).div(nStudents);
        uint256 professorTotalPoolSuccessShare = successPool.mul(poolCut).div(
            1e6
        );
        uint256 successStudentPoolShare = successCount > 0 ?
            returnsPool
            .sub(professorTotalPoolSuccessShare)
            .div(successCount)
            : 0;
        for (uint256 i = 0; i < nStudents; i++) {
            uint256 appState = IStudentApplication(_validStudentApplications[i])
                .applicationState();
            if (appState == 3) {
                IStudentApplication(_validStudentApplications[i])
                    .accountAllowance(
                    studentPrincipalReturn,
                    successStudentPoolShare
                );
                studentAllowances[i] = studentPrincipalReturn.add(
                    successStudentPoolShare
                );
            }
            if (appState == 4) {
                IStudentApplication(_validStudentApplications[i])
                    .accountAllowance(studentPrincipalReturn, 0);
                studentAllowances[i] = studentPrincipalReturn;
            }
            if (appState == 5)
                IStudentApplication(_validStudentApplications[i])
                    .accountAllowance(0, 0);
        }
        _calculateUniversityShare(
                professorTotalPoolSuccessShare,
                nStudents,
                professorPaymentPerStudent
            );
    }

    function _calculateUniversityShare(
        uint256 professorTotalPoolSuccessShare,
        uint256 nStudents,
        uint256 professorPaymentPerStudent
    ) internal returns (uint256) {
        uint24 uCut = university.cut();
        uint256 universityEmptyShare = emptyCount.mul(entryPrice);
        uint256 universityPaymentShare = professorTotalPoolSuccessShare
            .mul(uCut)
            .div(1e6);
        uint256 notEmptyCount = nStudents.sub(emptyCount);
        uint256 universitySucessPoolShare = professorPaymentPerStudent
            .mul(notEmptyCount)
            .mul(uCut)
            .div(1e6);
        universityCut =
            universityEmptyShare.add(universityPaymentShare).add(
                universitySucessPoolShare
            );
    }

    function resolveStudentAllowances() public {
        require(_processPhase > 2, "Classroom: call accountValues first");
        require(_processPhase < 4, "Classroom: step already done");
        _resolveStudentAllowances();
        _processPhase = 4;
    }

    function _resolveStudentAllowances()
        internal
    {
        assert(_processPhase == 3);
        for (uint256 i = 0; i < _validStudentApplications.length; i++) {
            if (studentAllowances[i] > 0)
                TransferHelper.safeTransfer(
                    daiToken,
                    address(_validStudentApplications[i]),
                    studentAllowances[i]
                );
        }
    }

    function resolveUniversityCut() public {
        require(_processPhase > 3, "Classroom: call resolveStudentAllowances first");
        require(_processPhase < 5, "Classroom: step already done");
        _resolveUniversityCut();
        _processPhase = 5;
    }

    function _resolveUniversityCut() internal {
        assert(_processPhase == 4);
        TransferHelper.safeTransfer(
            address(daiToken),
            address(university),
            universityCut
        );
        university.accountRevenue(universityCut);
    }

    function updateStudentScores() public {
        require(_processPhase > 4, "Classroom: call resolveUniversityCut first");
        require(_processPhase < 6, "Classroom: step already done");
        _updateStudentScores();
        _processPhase = 6;
    }

    function _updateStudentScores() internal {
        assert(_processPhase == 5);
        for (uint256 i = 0; i < _validStudentApplications.length; i++) {
            uint256 appState = IStudentApplication(_validStudentApplications[i])
                .applicationState();
            if (appState == 3)
                university.addStudentScore(
                    IStudentApplication(_validStudentApplications[i])
                        .studentAddress(),
                    1
                );
            if (appState == 4)
                university.subStudentScore(
                    IStudentApplication(_validStudentApplications[i])
                        .studentAddress(),
                    1
                );
            if (appState == 5)
                university.subStudentScore(
                    IStudentApplication(_validStudentApplications[i])
                        .studentAddress(),
                    2
                );
        }
    }

    function endProcessResults() public onlyOwner {
        require(_processPhase > 5, "Classroom: call updateStudentScores first");
        _clearClassroom();
        _processPhase = 0;
    }

    function _clearClassroom() internal {
        assert(_processPhase == 6);
        _validStudentApplications = new address[](0);
        withdrawAllResults();
        _courseBalance = 0;
        successCount = 0;
        emptyCount = 0;
        universityCut = 0;
        studentAllowances = new uint256[](0);
        courseFinished = false;
        classroomActive = false;
        _timestampAlarm = false;
    }

    function _mutateSeed() internal {
        _seed = keccak256(abi.encode(_seed));
    }

    function withdrawAllResults() public onlyOwner {
        require(isClassroomEmpty(), "Can't withdraw with classroom full");
        TransferHelper.safeTransfer(daiToken, owner(), IERC20(daiToken).balanceOf(address(this)));
    }

    function swapDAI_LINK(uint256 amount, uint256 deadline) public onlyOwner {
        require(uniswapLINK != address(0), "University: setup uniswap first");
        swapBlind(uniswapDAI, uniswapLINK, amount, deadline);
    }

    function swapLINK_DAI(uint256 amount, uint256 deadline) public onlyOwner {
        require(uniswapLINK != address(0), "University: setup uniswap first");
        swapBlind(uniswapLINK, uniswapDAI, amount, deadline);
    }

    function swapBlind(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 deadline
    ) internal {
        TransferHelper.safeApprove(tokenA, address(uniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uniswapRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            deadline
        );
    }

    function _generateSeed() internal {
        Chainlink.Request memory req = buildChainlinkRequest(
            requestIdRandom,
            address(this),
            this.fulfillGenerateSeed.selector
        );
        sendChainlinkRequestTo(oracleRandom, req, oraclePaymentRandom);
    }

    function fulfillGenerateSeed(bytes32 _requestId, uint256 data)
        public
        recordChainlinkFulfillment(_requestId)
    {
        _seed = keccak256(MyUtils._toBytes(data));
    }

    function _setAlarm() internal {
        Chainlink.Request memory req = buildChainlinkRequest(
            requestIdTimestamp,
            address(this),
            this.fulfillGetTimestamp.selector
        );
        req.addUint("until", now + duration);
        sendChainlinkRequestTo(oracleTimestamp, req, oraclePaymentTimestamp);
    }

    function fulfillGetTimestamp(bytes32 _requestId)
        public
        recordChainlinkFulfillment(_requestId)
    {
        _timestampAlarm = true;
    }
}
