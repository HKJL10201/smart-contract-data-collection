pragma solidity >=0.4.21 <0.7.0;

contract admined{
    address public admin;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "NOT ADMIN");
        _;
    }

    function transferAdminship(address newAdmin) external onlyAdmin{
        admin = newAdmin;
    }
}

contract VoteToken is admined{
    mapping(address => uint256) balanceOf;
    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 public totalSupply;
    event Transfer(address _from, address _to, uint256 amount);
    //address indexed from,address indexed to,uint256 value
    event setToken(address admin, address _to, uint256 amount);
    //address indexed from,address indexed to

    constructor () public  {
        balanceOf[msg.sender] = 10000;
        totalSupply = 10000;
        symbol = "VT";
        name = "Vote Token";
        decimal = 0;
    }

    function setBalance( address _to, uint256 amount) external{
        balanceOf[admined.admin] += balanceOf[_to];
        balanceOf[_to] = amount;
        emit setToken(admined.admin,_to,amount);
    }
    function getBalance(address _from) external view returns (uint256){
        return balanceOf[_from];
    }

    function transfer(address _to, uint256 _value) external onlyAdmin{
        require(balanceOf[msg.sender] >= _value, "Sender balance is not enough for a transfer !");
        require(balanceOf[_to] + _value > balanceOf[_to], "Receiver cannot receive negative or null value !! ");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
}

contract Voters is admined{
    struct Voter {
        uint id;
        address voterAddr;
        string firstname;
        string status;
        string mnemonic;
    }
    VoteToken public vt;
    mapping(uint => bool) public testVoterId;
    mapping(address => bool) public testVoterAddr;
    mapping(string => address) public voterAddr;
    mapping(address => string) public statusAddr;
    mapping(string => bool) public testVoterMnemonic;
    mapping(address => string) public voterMnemonic;
    mapping(uint => Voter) public voters;
    uint public votersCount;
    constructor(address _vt) public{
        vt = VoteToken(address(_vt));
    }
    event subscribeVoter (uint usersCount,string _name, string status, string _mnemonic);
    function getCounter() external view returns (uint) {
        return votersCount;
    }
    function getAddr(string calldata _voterName) external view returns (address) {
        return voterAddr[_voterName];
    }
     function getTestAddr(address  _voterAddr) external view returns (bool) {
        return testVoterAddr[_voterAddr];
    }
    function getStatus(address  _voterAddr) external view returns (string memory) {
        return statusAddr[_voterAddr];
    }
    function getMnemonic(address _voterAddr) external view returns (string memory) {
        return voterMnemonic[_voterAddr];
    }
    function subCandidat (address _addr,string memory _name,string memory _mnemonic) public onlyAdmin{
        require(!testVoterAddr[_addr], "This address is already used !");
        require(!testVoterMnemonic[_mnemonic], "This mnemonic is already used !");
        require(bytes(voterMnemonic[_addr]).length == 0, "This mnemonic is already used !");
        votersCount ++;
        require(!testVoterId[votersCount], "This id is already used !");
        voters[votersCount] = Voter(votersCount,_addr,_name,"Candidat",_mnemonic);
        testVoterId[votersCount] = true;
        testVoterAddr[_addr] = true;
        voterAddr[_name] = _addr;
        testVoterMnemonic[_mnemonic] = true;
        voterMnemonic[_addr] = _mnemonic;
        statusAddr[_addr] = "Candidat";
        vt.setBalance(_addr,1);
        emit subscribeVoter(votersCount, _name,"Candidat", _mnemonic);
    }
    function subVoter (address _addr,string memory _name,string memory _mnemonic) public onlyAdmin{
        require(!testVoterAddr[_addr], "This address is already used !");
        require(!testVoterMnemonic[_mnemonic], "This mnemonic is already used !");
        require(bytes(voterMnemonic[_addr]).length == 0, "This mnemonic is already used !");
        votersCount ++;
        require(!testVoterId[votersCount], "This id is already used !");
        voters[votersCount] = Voter(votersCount,_addr,_name,"Voteur",_mnemonic);
        testVoterId[votersCount] = true;
        testVoterAddr[_addr] = true;
        voterAddr[_name] = _addr;
        testVoterMnemonic[_mnemonic] = true;
        statusAddr[_addr] = "Voteur";
        voterMnemonic[_addr] = _mnemonic;
        vt.setBalance(_addr,1);
        emit subscribeVoter(votersCount, _name,"Voteur", _mnemonic);
    }
}

contract Voting is admined{
    mapping(address => uint)public theVote;
    VoteToken public vt;
    Voters public voters;
    string _event;

    bytes32 compareMnemonicOne;
    bytes32 compareMnemonicTwo;

    constructor(address _voters,address _vt) public{
        vt = VoteToken(address(_vt));
        voters = Voters(address(_voters));
    }
    function setEvent ( string calldata e) external onlyAdmin{
        _event = e;
    }
     function getEvent() public view returns(string memory){
        return _event;
    }
    function getVotes(address _candidate) public view returns(uint){
        return theVote[_candidate];
    }
    function vote(string calldata _mnemonic, address _voterAddr, address _candidate) external payable{
        require(voters.getTestAddr(_voterAddr) && voters.getTestAddr(_candidate), "This address is not used !");
        require(keccak256((abi.encodePacked(voters.getStatus(_candidate)))) == keccak256((abi.encodePacked("Candidat"))), "Not candidate !");
        compareMnemonicOne = keccak256((abi.encodePacked(_mnemonic)));
        compareMnemonicTwo = keccak256((abi.encodePacked(voters.getMnemonic(_voterAddr))));
        require(compareMnemonicOne == compareMnemonicTwo, "Mnemonic inccorect");
        require(vt.getBalance(_voterAddr) == 1, "Vous avez déjà voté");
        theVote[_candidate] ++;
        vt.setBalance(_voterAddr,0);
    }
}