pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@opengsn/gsn/contracts/interfaces/IRelayHub.sol";
import "@opengsn/gsn/contracts/utils/GSNTypes.sol";
import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";
import "./interface/IClassroom.sol";
import "./interface/IStudent.sol";
import "./interface/IStudentApplication.sol";
import "./interface/IClassroomFactory.sol";
import "./interface/IStudentFactory.sol";
import "./interface/IUniversity.sol";
import "./interface/IUniversityFund.sol";
import "./interface/IGrantsManager.sol";
import "./interface/ENSInterfaces.sol";
import "./MyUtils.sol";

//TODO: Natspec Document ENVERYTHING
//TODO: Sort function order from all contracts

contract University is Ownable, AccessControl, BaseRelayRecipient, IUniversity {
    using SafeMath for uint256;

    //CLASSLIST_ADMIN_ROLE can add new manually created classes to the list
    bytes32 public constant CLASSLIST_ADMIN_ROLE = keccak256(
        "CLASSLIST_ADMIN_ROLE"
    );
    // FUNDS_MANAGER_ROLE can withdraw funds from the contract
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256(
        "FUNDS_MANAGER_ROLE"
    );
    // GRANTS_MANAGER_ROLE can approve/decline grant claims
    bytes32 public constant GRANTS_MANAGER_ROLE = keccak256(
        "GRANTS_MANAGER_ROLE"
    );
    /// STUDENT_IDENTITY_ROLE allow asking for grants and requesting a classroom from a successful application
    bytes32 public constant STUDENT_IDENTITY_ROLE = keccak256(
        "STUDENT_IDENTITY_ROLE"
    );
    /// CLASSROOM_PROFESSOR_ROLE can manage itself inside the University and registering student applications
    bytes32 public constant CLASSROOM_PROFESSOR_ROLE = keccak256(
        "CLASSROOM_PROFESSOR_ROLE"
    );
    /// UNIVERSITY_OVERSEER_ROLE can inspect Grant Managers and Fund Managers, and present cases for funders to vote upon
    bytes32 public constant UNIVERSITY_OVERSEER_ROLE = keccak256(
        "UNIVERSITY_OVERSEER_ROLE"
    );/// REGISTERED_SUPPLIER_ROLE can receive transactions to consume the operational budget
    bytes32 public constant REGISTERED_SUPPLIER_ROLE = keccak256(
        "REGISTERED_SUPPLIER_ROLE"
    );

    // Parameter: Name of this University
    bytes32 public override name;
    // Parameter: University cut from professor (Parts per Million)
    uint24 public override cut;
    // Parameter: GSN funds to give students
    uint256 _studentGSNDeposit;
    // List of every registered classroom
    address[] _classList;
    // Mapping of each student's applications
    mapping(address => address[]) _studentApplicationsMapping;
    // Mapping of each student(owner) to student(smart contract)
    mapping(address => address) _ownerToStudent;
    // Mapping of every donor and donations
    mapping(address => uint256) public donators;
    // Total amount of donations received so far
    uint256 public donationsReceived;
    // Total amount of operational revenue received so far
    uint256 public revenueReceived;
    // Total amount of financial returns received so far
    uint256 public returnsReceived;
    // Total amount of endowment locked in the fund
    uint256 public endowmentLocked;
    // Total amount of funds allowed for expenses
    uint256 public operationalBudget;
    // University Fund
    address public override universityFund;

    //Tokens
    address public daiToken;
    address public cDAI;

    //GSN
    IRelayHub public relayHub;

    //Factory
    address public classroomFactory;
    address public studentFactory;
    address public studentApplicationFactory;

    //ENS
    address public ensContract;
    address public ensTestRegistrar; //change on prod
    address public ensPublicResolver;
    address public ensReverseRegistrar;

    /// @notice Constructor setup the basic variables
    /// @dev Not all variables can be defined in this constructor because the limitation of the stack size
    /// @param name_ Given name for the university
    /// @param cut_ Cut from professor payments, in PPM
    /// @param daiAddress Adress of contract in the network
    /// @param relayHubAddress Adress of contract in the network
    /// @param classroomFactoryAddress Adress of contract in the network
    /// @param studentFactoryAddress Adress of contract in the network
    /// @param studentApplicationFactoryAddress Adress of contract in the network
    constructor(
        bytes32 name_,
        uint24 cut_,
        address daiAddress,
        address compoundDai,
        address relayHubAddress,
        address classroomFactoryAddress,
        address studentFactoryAddress,
        address studentApplicationFactoryAddress,
        address ensContractAddress,
        address ensTestRegistrarAddress,
        address ensPublicResolverAddress,
        address ensReverseRegistrarAddress
    ) public {
        name = name_;
        cut = cut_;
        _studentGSNDeposit = 1e15;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(CLASSLIST_ADMIN_ROLE, _msgSender());
        daiToken = daiAddress;
        cDAI = compoundDai;
        relayHub = IRelayHub(relayHubAddress);
        classroomFactory = classroomFactoryAddress;
        studentFactory = studentFactoryAddress;
        studentApplicationFactory = studentApplicationFactoryAddress;
        ensContract = ensContractAddress;
        ensTestRegistrar = ensTestRegistrarAddress;
        ensPublicResolver = ensPublicResolverAddress;
        ensReverseRegistrar = ensReverseRegistrarAddress;
    }

    /// @notice Allow receiving ETH
    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH from the contract
    function withdraw(uint256 val) public onlyOwner {
        TransferHelper.safeTransferETH(_msgSender(), val);
    }

    /// @notice Transfer ETH to the relayHub
    function refilRelayHub(uint256 val) public onlyOwner {
        relayHub.depositFor{value:val}(address(this));
    }

    /// @notice Withdraw ETH to the relayHub
    function withdrawRelayHub(uint256 val) public onlyOwner {
        relayHub.withdraw(val, address(this));
    }

    /// @notice Records the name and address of every new classroom created
    event LogNewClassroom(bytes32, address);
    /// @notice Records the name and address of every new student created
    event LogNewStudent(bytes32, address);
    /// @notice Records the name changes of this University
    event LogChangeName(bytes32);
    /// @notice Records the changes in the Cut parameter
    event LogChangeCut(uint24);
    /// @notice Records ETH received
    event LogReceived(address, uint256);
    /// @notice Records donations received and the address of the donor
    event LogDonation(address, uint256);
    /// @notice Records investment returns received and the address of the caller
    event LogReturn(address, uint256);
    /// @notice Records revenues received and the address of the souce
    event LogRevenue(address, uint256);

    /// @notice Update external contracts addresses
    /// @param daiAddress Address of contract in the network
    /// @param relayHubAddress Address of contract in the network
    /// @param classroomFactoryAddress Address of contract in the network
    /// @param studentFactoryAddress Address of contract in the network
    /// @param studentApplicationFactoryAddress Address of contract in the network
    /// @param ensTestRegistrarAddress Address of contract in the network    
    /// @param ensPublicResolverAddress Address of contract in the network
    /// @param ensReverseRegistrarAddress Address of contract in the network    
    function updateAddresses(
        address daiAddress,
        address compoundDai,
        address relayHubAddress,
        address classroomFactoryAddress,
        address studentFactoryAddress,
        address studentApplicationFactoryAddress,
        address ensContractAddress,
        address ensTestRegistrarAddress,
        address ensPublicResolverAddress,
        address ensReverseRegistrarAddress) public onlyOwner{
        daiToken = daiAddress == address(0) ? daiToken : daiAddress;
        cDAI = compoundDai == address(0) ? cDAI : compoundDai;
        relayHub = relayHubAddress == address(0) ? relayHub : IRelayHub(relayHubAddress);
        classroomFactory = classroomFactoryAddress == address(0) ? classroomFactory : classroomFactoryAddress;
        studentFactory = studentFactoryAddress == address(0) ? studentFactory : studentFactoryAddress;
        studentApplicationFactory = studentApplicationFactoryAddress == address(0) ? studentApplicationFactory : studentApplicationFactoryAddress;
        ensContract = ensContractAddress == address(0) ? ensContract : ensContractAddress;
        ensTestRegistrar = ensTestRegistrarAddress == address(0) ? ensTestRegistrar : ensTestRegistrarAddress;
        ensPublicResolver = ensPublicResolverAddress == address(0) ? ensPublicResolver : ensPublicResolverAddress;
        ensReverseRegistrar = ensReverseRegistrarAddress == address(0) ? ensReverseRegistrar : ensReverseRegistrarAddress;
    }

    // Parameters setup

    /// @notice Attach the University Fund after creation
    /// @param addr New value
    function attachFund(address addr) public onlyOwner {
        require(
            IUniversityFund(addr).ownerFund() == address(this),
            "University: this university is not owner of this fund"
        );
        universityFund = addr;
    }
    
    /// @notice Change the name of the University
    /// @param val New value
    function changeName(bytes32 val) public onlyOwner {
        name = val;
        emit LogChangeName(name);
    }

    /// @notice Change the cut charged from the professors
    /// @param val New value, in PPM
    function changeCut(uint24 val) public onlyOwner {
        cut = val;
        emit LogChangeCut(cut);
    }

    /// @notice Change the value of ETH deposited in students relay hub
    /// @param val New value, in WEI
    function changeStudentGSNDeposit(uint256 val) public onlyOwner {
        _studentGSNDeposit = val;
    }

    // ENS operations

    function registerInRegistrar(bytes32 label, address _owner) public onlyOwner {
        IRegistrar(ensTestRegistrar).register(label, _owner);
    }

    function registerInReverseRegistrar(string memory _name) public onlyOwner {
        IReverseRegistrar(ensReverseRegistrar).setName(_name);
    }

    function setResolver(bytes32 node, address resolver) public onlyOwner {
        IENS(ensContract).setResolver(node, resolver);
    }

    function setAddressInResolver(bytes32 node, address val) public onlyOwner {
        setAddressInResolver(node, val, ensPublicResolver);
    }

    function setAddressInResolver(bytes32 node, address val, address resolver) public onlyOwner {
        IResolver(resolver).setAddr(node, val);
    }

    function setTextInResolver(bytes32 node, string memory key, string memory val) public onlyOwner {
        setTextInResolver(node, key, val, ensPublicResolver);
    }

    function setTextInResolver(bytes32 node, string memory key, string memory val, address resolver) public onlyOwner {
        IResolver(resolver).setText(node, key, val);
    }

    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) public onlyOwner {
        IENS(ensContract).setSubnodeRecord(node, label, owner, resolver, ttl);
    }

    function claimSubnodeClassroom(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl, address classroom) public {
        require(
            owner == _msgSender(),
            "University: delegated claim not allowed"
        );
        require(
            IClassroom(classroom).ownerClassroom() == _msgSender(),
            "University: caller is not owner of this classroom"
        );
        setSubnodeRecord(node, label, owner, resolver, ttl);
    }

    function claimSubnodeStudent(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl, address student) public {
        require(
            owner == _msgSender(),
            "University: delegated claim not allowed"
        );
        require(
            IStudent(student).ownerStudent() == _msgSender(),
            "University: caller is not owner of this student registry"
        );
        setSubnodeRecord(node, label, owner, resolver, ttl);
    }
    
    // Contract Logic

    // Public view functions 

    /// @return the ammount of DAI able for investing
    /// @dev ETH is not considered as part of investment funds
    function availableFundsForInvestment() public view override returns (uint256) {
        uint256 funds = IERC20(daiToken).balanceOf(address(this));
        if (funds < operationalBudget) return 0;
        return funds.sub(operationalBudget);
    }

    /// @return the ammount of DAI able for giving grants
    /// @dev ETH is not considered as part of funds
    function availableFunds() public view override returns (uint256) {
        uint256 funds = IERC20(daiToken).balanceOf(address(this));
        if (funds < endowmentLocked.add(operationalBudget)) return 0;
        return funds.sub(endowmentLocked).sub(operationalBudget);
    }

    /// @return true if the classroom is registered in this University 
    function isValidClassroom(address classroom) public view override returns (bool) {
        return hasRole(CLASSROOM_PROFESSOR_ROLE, classroom);
    }

    /// @return true if the student is registered in this University 
    function studentIsRegistered(address student) public view override returns (bool) {
        return hasRole(STUDENT_IDENTITY_ROLE, student);
    }

    /// @return address of this student
    function myStudentAddress() public view returns (address) {
        require(
            _ownerToStudent[_msgSender()] != address(0),
            "University: caller doesn't have a student registry"
        );
        return _ownerToStudent[_msgSender()];
    }

    /// @return the address of the application of a Student
    function viewMyApplications() public view override returns (address[] memory) {
        return viewStudentApplications(_msgSender());
    }

    /// @return the address of the application of a Student, called from the owner
    function viewMyStudentApplications(address student) public view returns (address[] memory) {
        require(
            IStudent(student).ownerStudent() == _msgSender(),
            "University: invalid student address"
        );
        return _studentApplicationsMapping[student];
    }

    /// @param addr Address of the student
    /// @return the addresses of the applications of a the supplied address
    function viewStudentApplications(address addr)
        public
        view
        override
        returns (address[] memory)
    {
        require(
            addr == _msgSender() || hasRole(GRANTS_MANAGER_ROLE, _msgSender()),
            "Classroom: read permission denied"
        );
        return _studentApplicationsMapping[addr];
    }

    // Student registry logic

    /// @notice Self-register function where an address can create an instance of a Student in this University
    /// @dev This GSN implementation is buggy
    /// @param sName Name of the Student
    function studentSelfRegisterGSN(bytes32 sName) public {
        address student = _newStudent(sName, _msgSender());
        relayHub.depositFor{value:_studentGSNDeposit}(student);
    }

    /// @notice Self-register function where an address can create an instance of a Student in this University
    /// @param sName Name of the Student
    function studentSelfRegister(bytes32 sName) public {
        _newStudent(sName, _msgSender());
    }

    function _newStudent(bytes32 sName, address caller)
        internal
        returns (address) {
        require(
            _ownerToStudent[caller] == address(0),
            "University: student already registered"
        );
        address student = IStudentFactory(studentFactory).newStudent(sName, address(this));
        _ownerToStudent[caller] = student;
        IStudent(student).transferOwnershipStudent(caller);
        _setupRole(STUDENT_IDENTITY_ROLE, student);
        emit LogNewStudent(name, student);
        return student;
    }

    // Classroom operation logic

    /// @notice Register function where an Admin can can create an instance of a Classroom in this University
    /// @param owner Address to own this classroom
    /// @param cName Name this classroom
    /// @param cCut Cut of the principal amount deposited that is charged from students, in PPM
    /// @param cPCut Cut of the pooled returns from successful students, in PPM
    /// @param minScore Minimum score value required from students to be able to apply in this classroom
    /// @param entryPrice Required deposit to be applied as principal an locked for the duration of the course, in decimal units of DAI
    /// @param duration Lock time between course opening and closing, in Timestamp
    /// @param challengeAddress Address to the challenge to be solved in this Classroom's courses
    /// @return the smart contract address for this Classroom instance in this University
    function newClassRoom(
        address owner,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challengeAddress
    ) public returns (address) {
        require(
            hasRole(CLASSLIST_ADMIN_ROLE, _msgSender()),
            "University: caller doesn't have CLASSLIST_ADMIN_ROLE"
        );
        return
            _newClassRoom(
                owner,
                cName,
                cCut,
                cPCut,
                minScore,
                entryPrice,
                duration,
                challengeAddress
            );
    }

    function _newClassRoom(
        address owner,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challengeAddress
    ) internal returns (address) {
        address classroom = IClassroomFactory(classroomFactory).newClassroom(
            cName,
            cCut,
            cPCut,
            minScore,
            entryPrice,
            duration,
            payable (address(this)),
            challengeAddress,
            daiToken,
            cDAI,
            studentApplicationFactory
        );
        IClassroom(classroom).transferOwnershipClassroom(owner);
        address classroomAddr = address(classroom);
        _classList.push(classroomAddr);
        _setupRole(CLASSROOM_PROFESSOR_ROLE, classroomAddr);
        emit LogNewClassroom(cName, classroomAddr);
        return classroomAddr;
    }

    /// @notice Register function where an Student can can create an instance of a Classroom in this University, upon being successful in any classroom
    /// @param applicationAddr Address of the successful application
    /// @param cName Name this classroom
    /// @param cCut Cut of the principal amount deposited that is charged from students, in PPM
    /// @param cPCut Cut of the pooled returns from successful students, in PPM
    /// @param minScore Minimum score value required from students to be able to apply in this classroom
    /// @param entryPrice Required deposit to be applied as principal an locked for the duration of the course, in decimal units of DAI
    /// @param duration Lock time between course opening and closing, in Timestamp
    /// @param challenge Address to the challenge to be solved in this Classroom's courses
    /// @return the smart contract address for this Classroom instance in this University
    function studentRequestClassroom(
        address applicationAddr,
        bytes32 cName,
        uint24 cCut,
        uint24 cPCut,
        int32 minScore,
        uint256 entryPrice,
        uint256 duration,
        address challenge
    ) public override returns (address) {
        require(
            hasRole(STUDENT_IDENTITY_ROLE, _msgSender()),
            "University: caller doesn't have STUDENT_IDENTITY_ROLE"
        );
        require(
            checkForStudentApplication(_msgSender(), applicationAddr),
            "University: caller is not student of this application"
        );
        IStudentApplication application = IStudentApplication(applicationAddr);
        require(
            application.applicationState() == 3,
            "University: application is not successful"
        );
        return
            _newClassRoom(
                IStudent(_msgSender()).ownerStudent(),
                cName,
                cCut,
                cPCut,
                minScore,
                entryPrice,
                duration,
                challenge
            );
    }

    /// @notice Register and map a Student's application to this Student
    /// @param student Address of the Student
    /// @param application Address of the application
    function registerStudentApplication(
        address student,
        address application
    ) public override
    {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        _studentApplicationsMapping[student].push(application);
    }

    /// @notice Check if an application belongs to a specific Student
    /// @param studentAddress Address of the Student
    /// @param applicationAddress Address of the application
    /// @return true if the application belongs to the Student
    function checkForStudentApplication(
        address studentAddress,
        address applicationAddress
    ) internal view returns (bool) {
        for (
            uint256 i = 0;
            i < _studentApplicationsMapping[studentAddress].length;
            i++
        ) {
            if (
                _studentApplicationsMapping[studentAddress][i] ==
                applicationAddress
            ) return true;
        }
        return false;
    }

    // Student score management

    /// @notice Increase a Student's score upon successful application
    /// @param student Address of the Student
    /// @param val Value to be added
    function addStudentScore(address student, int32 val) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        IStudent(student).addScore(val);
    }

    /// @notice Decrease a Student's score upon failed application
    /// @param student Address of the Student
    /// @param val Value to be subtracted
    function subStudentScore(address student, int32 val) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        IStudent(student).subScore(val);
    }

    // Funds asset value management 

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function applyFunds(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            availableFundsForInvestment() >= val,
            "University: not enough funds to invest"
        );
        require(
            universityFund != address(0),
            "University: attach fund first"
        );
        TransferHelper.safeTransfer(address(daiToken), universityFund, val);
    }

    /// @notice Get the ammount of DAI applied in Fund
    /// @return ammount of DAI applied in Fund
    function appliedFunds() public view returns (uint256) {
        require(
            universityFund != address(0),
            "University: attach fund first"
        );
        return IERC20(daiToken).balanceOf(universityFund);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function recoverFunds(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            universityFund != address(0),
            "University: attach fund first"
        );
        TransferHelper.safeTransferFrom(address(daiToken), universityFund, address(this), val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function applyFundsETH(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            universityFund != address(0),
            "University: attach fund first"
        );
        TransferHelper.safeTransferETH(universityFund, val);
    }

    /// @notice Get the ammount of ETH applied in Fund
    /// @return ammount of ETH applied in Fund
    function appliedFundsETH() public view returns (uint256) {
        require(
            universityFund != address(0),
            "University: attach fund first"
        );
        return universityFund.balance;
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function recoverFundsETH(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            universityFund != address(0),
            "University: attach fund first"
        );
        IUniversityFund(universityFund).withdraw(val);
    }

    //Funds setup

    /// @notice Grants role to account inside University Fund
    function grantRoleFund(bytes32 role, address account) public {
        require(
            universityFund != address(0),
            "University: attach fund first"
        );
        IUniversityFund(universityFund).grantRoleFund(role, account);
    }

    /// @notice Revoke role from account inside University Fund
    function revokeRoleFund(bytes32 role, address account) public {
        require(
            universityFund != address(0),
            "University: attach fund first"
        );
        IUniversityFund(universityFund).revokeRoleFund(role, account);
    }

    // Funds value quotas management

    /// @notice Allow managing how much Funds Manager can draw from funds to cover operational expenses. Must be called from the university admin
    /// @param val Value to increase
    function increaseOperationalBudget(uint256 val) public onlyOwner {
        require(
            endowmentLocked >= val,
            "University: not enough endowment"
        );
        operationalBudget = operationalBudget.add(val);
        endowmentLocked = endowmentLocked.sub(val);
    }

    /// @notice Allow managing how much Funds Manager can draw from funds to cover operational expenses. Must be called from the university admin
    /// @param val Value to decrease
    function decreaseOperationalBudget(uint256 val) public onlyOwner {
        require(
            operationalBudget >= val,
            "University: not enough budget to decrease"
        );
        operationalBudget = operationalBudget.sub(val);
        endowmentLocked = endowmentLocked.add(val);
    }

    /// @notice Allow a Funds Manager to send funds to Registered Suppliers, spending the operational budget set by the University owner
    /// @param to Address of the Registered Supplier
    /// @param val Value to be sent, in DAI decimals
    function spendBudget(address to, uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            hasRole(REGISTERED_SUPPLIER_ROLE, to),
            "University: receiver doesn't have REGISTERED_SUPPLIER_ROLE"
        );
        require(
            operationalBudget >= val,
            "University: not enough operational budget"
        );
        require(
            IERC20(daiToken).balanceOf(address(this)) >= val,
            "University: recover funds first"
        );
        TransferHelper.safeTransfer(address(daiToken), to, val);
        operationalBudget = operationalBudget.sub(val);
    }

    /// @notice Allow a Grants Manager to pay a Student's entry price for an application, if the appointed Grants Manager decide so
    /// @param studentApplication Address of the Student
    /// @param price Value of the application's entry price
    function giveGrant(address studentApplication, uint256 price) public override {
        require(
            hasRole(GRANTS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have GRANTS_MANAGER_ROLE"
        );
        require(
            availableFunds() >= price,
            "University: not enough available funds"
        );
        IStudentApplication(studentApplication).payEntryPrice();
    }

    /// @notice Allow a Funds Manager to redirect surplus funds from liquidated positions to the endowment locked value. Irreversible
    /// @param val Value to be sent, in DAI decimals
    function reinvestReturns(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            availableFunds() >= val,
            "University: not enough available funds"
        );
        accountReturns(val);
    }

    // Overseer actions

    /// @notice Allow an appointed Overseer to inspect all students that received grants by a specific Grants Manager
    /// @param grantsManager Address of the Grants Manager
    /// @return array of Students addresses
    function viewAllStudentsFromGrantManager(
            address grantsManager
        ) public returns (address[] memory) {
        require(
            hasRole(UNIVERSITY_OVERSEER_ROLE, _msgSender()),
            "University: caller doesn't have UNIVERSITY_OVERSEER_ROLE"
        );
        return IGrantsManager(grantsManager).viewAllStudents();
    }

    /// @notice Allow an appointed Overseer to inspect all grants issued by a specific Grants Manager to a specific Student
    /// @param student Address of the Student
    /// @param grantsManager Address of the Grants Manager
    /// @return array of grant values
    function viewAllStudentGrantsFromGrantManager(
            address student, 
            address grantsManager
        ) public returns (uint256[] memory) {
        require(
            hasRole(UNIVERSITY_OVERSEER_ROLE, _msgSender()),
            "University: caller doesn't have UNIVERSITY_OVERSEER_ROLE"
        );
        return IGrantsManager(grantsManager).viewAllGrantsForStudent(student);
    }

    // GSN implementation

    /// @notice GSN specific implementation
    function _msgSender()
    internal 
    view 
    override(Context, BaseRelayRecipient) 
    returns (address payable sender){
        return BaseRelayRecipient._msgSender();
    }

    /// @notice GSN specific implementation
    /// @dev The idea here is only to allow GSN interactions with one specific funcion
    function acceptRelayedCall(
        GSNTypes.RelayRequest calldata relayRequest,
        bytes calldata,
        uint256
    ) external pure returns (bytes memory context) {
        require(
            MyUtils.readBytes4(relayRequest.encodedFunction, 0) ==
                this.studentSelfRegisterGSN.selector,
            "University: GSN not enabled for this function"
        );
        return abi.encode(relayRequest.target, 0);
    }

    /// @notice Allow a Funds Manager to refill the GSN relayer using the University ETH funds
    /// @param val Value to be deposited in the relayer, in WEI
    function refillUniversityRelayer(uint256 val) public {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()) || _msgSender() == owner(),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        relayHub.depositFor{value:val}(address(this));
    }

    // Donations feature

    /// @notice Allow donating DAI to the University funds. Require allowing the University first
    /// @param donation amount of DAI to donate, in decimals
    function donateDAI(uint256 donation) public override {
        TransferHelper.safeTransferFrom(
            address(daiToken),
            _msgSender(),
            address(this),
            donation
        );
        accountDonation(_msgSender(), donation);
    }

    function accountDonation(address sender, uint256 donation) internal {
        donationsReceived = donationsReceived.add(donation);
        endowmentLocked = endowmentLocked.add(donation);
        donators[sender] = donators[sender].add(donation);
        LogDonation(_msgSender(), donation);
    }
    
    /// @notice Classroom call to account a revenue received from a completed course
    function accountRevenue(uint256 revenue) public override {
        require(
            hasRole(CLASSROOM_PROFESSOR_ROLE, _msgSender()),
            "University: caller doesn't have CLASSROOM_PROFESSOR_ROLE"
        );
        revenueReceived = revenueReceived.add(revenue);
        endowmentLocked = endowmentLocked.add(revenue);
        LogRevenue(_msgSender(), revenue);
    }

    function accountReturns(uint256 financialReturns) internal {
        returnsReceived = revenueReceived.add(financialReturns);
        endowmentLocked = endowmentLocked.add(financialReturns);
        LogReturn(_msgSender(), financialReturns);
    }
}
