pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interface/IUniversity.sol";
import "./interface/IStudent.sol";
import "./interface/IClassroom.sol";
import "./interface/IStudentApplication.sol";
import "./interface/IStudentAnswer.sol";
import "./interface/IClassroomChallenge.sol";


contract StudentApplication is Ownable, IStudentApplication {
    using SafeMath for uint256;

    IERC20 public daiToken;
    IClassroomChallenge _challenge;

    enum ApplicationState {New, Ready, Active, Success, Failed, Empty, Expired}

    IStudentAnswer _answer;
    ApplicationState _applicationState;
    address _studentAddress;
    address public classroomAddress;
    bytes32 _seed;
    bool _hasAnswer;
    uint256 _principalReturned;
    uint256 _completionPrize;
    uint256 _entryPrice;
    bytes32 _answerSecret;

    constructor(
        address studentAddress,
        address classroomAddress_,
        address daiAddress,
        address challengeAddress,
        bytes32 seed
    ) public {
        _applicationState = ApplicationState.New;
        _studentAddress = studentAddress;
        classroomAddress = classroomAddress_;
        _hasAnswer = false;
        daiToken = IERC20(daiAddress);
        _seed = seed;
        _challenge = IClassroomChallenge(challengeAddress);
        _entryPrice = IClassroom(classroomAddress).entryPrice();
    }

    function studentAddress() public view override returns (address) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return _studentAddress;
    }

    function applicationState() public view override returns (uint256) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return uint256(_applicationState);
    }

    function entryPrice() public view override returns (uint256) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return _entryPrice;
    }

    function challengeAddress() public view returns (address) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return address(_challenge);
    }

    function payEntryPrice() external override {
        require(
            _applicationState == ApplicationState.New,
            "StudentApplication: application is not New"
        );
        require(
            daiToken.balanceOf(_msgSender()) >= _entryPrice,
            "StudentApplication: sender can't pay the entry price"
        );
        TransferHelper.safeTransferFrom(
            address(daiToken),
            _msgSender(),
            classroomAddress,
            _entryPrice
        );
        _applicationState = ApplicationState.Ready;
    }

    function activate() public override onlyOwner {
        require(
            _applicationState == ApplicationState.Ready,
            "StudentApplication: application is not Ready"
        );
        _applicationState = ApplicationState.Active;
    }

    function expire() public override onlyOwner {
        require(
            _applicationState == ApplicationState.New,
            "StudentApplication: application is not New"
        );
        _applicationState = ApplicationState.Expired;
    }

    function setAnswerSecret(bytes32 secret) public override {
        require(
            _msgSender() == _studentAddress,
            "StudentApplication: write permission denied"
        );
        require(
            secret != bytes32(0),
            "StudentApplication: must set a valid secret"
        );
        _answerSecret = secret;
    }

    function registerAnswer(bytes32 secret) public override {
        require(
            _answerSecret != bytes32(0),
            "StudentApplication: application secret not set"
        );
        require(
            secret == _answerSecret, 
            "StudentApplication: wrong secret"
        );
        require(
            _applicationState == ApplicationState.Active,
            "StudentApplication: application is not active"
        );
        IStudentAnswer answer = IStudentAnswer(_msgSender());
        require(
            answer.getOwner() == IStudent(_studentAddress).ownerStudent(),
            "StudentApplication: getOwner result is wrong"
        );
        _answer = answer;
        _hasAnswer = true;
    }

    function viewChallengeMaterial() public view override returns (string memory) {
        require(
            _msgSender() == _studentAddress || _msgSender() == owner(),
            "StudentApplication: read permission denied"
        );
        return _challenge.viewMaterial();
    }

    function getHint(uint256 index) public view override returns (bytes32) {
        require(_hasAnswer, "StudentApplication: answer not registered");
        require(
            _msgSender() == address(_answer),
            "StudentApplication: are you cheating?"
        );
        require(
            index < _challenge.hintsCount(),
            "StudentApplication: hint not available"
        );
        return _challenge.getHint(index, _seed);
    }

    function verifyAnswer() public view returns (bool) {
        try _answer.getSeed() returns (bytes32 seed) {
            return seed == _seed;
        } catch {
            return false;
        }
    }

    function registerFinalAnswer() public override onlyOwner {
        if (!_hasAnswer) {
            _applicationState = ApplicationState.Empty;
        } else {
            if (verifyAnswer()) _applicationState = ApplicationState.Success;
            else _applicationState = ApplicationState.Failed;
        }
    }

    function accountAllowance(uint256 principal, uint256 prize)
        public
        override
        onlyOwner
    {
        require(
            applicationState() > 2,
            "StudentApplication: application not finished yet"
        );
        _principalReturned = principal;
        _completionPrize = prize;
    }

    function viewPrincipalReturned() public view returns (uint256) {
        require(
            _msgSender() == _studentAddress || _msgSender() == IStudent(_studentAddress).ownerStudent(),
            "StudentApplication: read permission denied"
        );
        return _principalReturned;
    }

    function viewPrizeReturned() public view returns (uint256) {
        require(
            _msgSender() == _studentAddress || _msgSender() == IStudent(_studentAddress).ownerStudent(),
            "StudentApplication: read permission denied"
        );
        return _completionPrize;
    }

    function withdrawAllResults(address to) public override {
        withdrawResults(to, _principalReturned + _completionPrize);
    }

    function withdrawResults(address to, uint256 val) public override {
        require(
            _msgSender() == _studentAddress,
            "StudentApplication: only student can withdraw"
        );
        require(
            applicationState() > 2,
            "StudentApplication: application not finished"
        );
        TransferHelper.safeTransfer(address(daiToken), to, val);
    }
}
