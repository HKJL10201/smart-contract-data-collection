pragma solidity >=0.5.0 <0.6.0;
import "./final.sol";
import "./voter_account.sol";
contract system_process is  _final, VoterAccount {
    uint16[] private vote_set;
    uint16 _counter = 0;
    mapping (uint => launched_vote) launched_map;
    address private owner;
    constructor() public {
        owner = msg.sender;
    }
    struct voter_state{
        address id;
        string[] item;
        bool start_check;
        bool ballots_check;
        mapping(string => ballot) ballots;
    }
    struct launched_vote{
        string topic;
        string content;
        uint16 selection_id;
        address[] ValidList;
        mapping (string => candidate_2[]) itemTovoter;
        mapping (string => candidate[]) itemTocand;
        string[]    items; 
        mapping (address => voter_state) state_map;
        mapping (address => string[]) voterToitems;
        uint8 vote_available;
        address launcher_address;
        result vote_result;
    }
    modifier check_omg(){
        require(msg.sender == owner);
        _;
    }
    function get_topic(uint16 _selection_id) view public returns(string memory)
    {
        return launched_map[_selection_id].topic;
    }
    function get_available_launched(address _UserId) view public returns(uint[] memory)
    {
        uint _size = 0;
        for(uint i=0; i<vote_set.length; i++)
        {
            for(uint j=0; j<launched_map[vote_set[i]].ValidList.length; j++)
            {
                if(launched_map[vote_set[i]].ValidList[j] == _UserId)
                {
                    _size += 1;
                    break;
                }
            }
        }
        uint[] memory launched_list = new uint[](_size);
        uint counter = 0;
        for(uint i=0; i<vote_set.length; i++)
        {
            for(uint j=0; j<launched_map[vote_set[i]].ValidList.length; j++) 
            {
                if(launched_map[vote_set[i]].ValidList[j] == _UserId)
                {
                    launched_list[counter] = vote_set[i];
                    counter += 1;
                    break;

                }
            }
        }
        return (launched_list);
    }
    function find_available_item(uint16 _selection_id, address  _UserId) view public returns(uint16[] memory)
    {
        uint16 size = 0;
        
        launched_vote storage _launched = launched_map[_selection_id];
        for(uint i=0; i< _launched.items.length; i++)
        {
            for(uint j=0; j<_launched.itemTovoter[_launched.items[i]].length; j++)
            {
                if(_launched.itemTovoter[_launched.items[i]][j].name == _UserId)
                {
                    size += 1;
                    break;
                }
            }
        }
        uint16[] memory record = new uint16[](size);
        uint16 counter = 0;
        for(uint16 i=0; i< _launched.items.length; i++)
        {
            for(uint j=0; j<_launched.itemTovoter[_launched.items[i]].length; j++)
            {
                if(_launched.itemTovoter[_launched.items[i]][j].name == _UserId)
                {
                    record[counter] = i;
                    counter += 1;
                    break;
                }
            }
        }
        return record;

    }
    function launch_vote(address  _id,string memory topic) public {
        require(idToVoter[_id].launch == false);
        Voter storage _launcher = idToVoter[_id];
        _launcher.launch = true;
        uint16 id = _counter + 1;
        _counter += 1;
        _launcher.launched = id;
        launched_vote memory lv;
        lv.topic = topic;
        lv.selection_id = id;
        lv.vote_available = 0;
        lv.launcher_address = msg.sender;
        vote_set.push(id);
        launched_map[id] = lv;
    }
    // uint, string memory , uint, uint
    function delete_vote(uint16 _selection_id) public set_launch(_selection_id)
    {
        launched_vote storage _launched = launched_map[_selection_id];
        require(_launched.vote_available == 0);
        idToVoter[_launched.launcher_address].launched = 0;
        idToVoter[_launched.launcher_address].launch   = false;
        uint16_array_delete(vote_set, _selection_id);
    }
    function read_topic(address  _id) view public returns(uint16, string memory , uint, uint8)
    {
        
        Voter storage _launcher = idToVoter[_id];
        launched_vote storage _launched = launched_map[_launcher.launched];
        return (_launched.selection_id, _launched.topic, _launched.items.length, _launched.vote_available);
    }
    function read_item(uint16 selection_id, uint16 _index) view public returns(string memory)
    {
        launched_vote storage _launched = launched_map[selection_id];
        return _launched.items[_index];
    }
    function read_voter_candidate_num(uint16 _selection_id, string memory _item) view public returns(uint,uint)
    {
        launched_vote storage _launched = launched_map[_selection_id];
        uint vote_num = _launched.itemTovoter[_item].length;
        uint cand_num = _launched.itemTocand[_item].length;
        return (vote_num,cand_num);
    }
    function read_voter(uint16 _selection_id, string memory _item, uint _index) view public returns(address)
    {
        launched_vote storage _launched = launched_map[_selection_id];
        return _launched.itemTovoter[_item][_index].name;
    }
    function read_cand(uint16 _selection_id, string memory _item, uint _index) view public returns(string memory)
    {
        launched_vote storage _launched = launched_map[_selection_id];
        return _launched.itemTocand[_item][_index].name;
    }
    modifier set_launch(uint16 _selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        require((msg.sender == _launched.launcher_address)&&(_launched.vote_available == 0));
        _;
    }
    modifier check_launcher(uint16 _selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        require(msg.sender == _launched.launcher_address);
        _;
    }
    function SetVoter(uint16 _selection_id, string memory _item,address _ValidVoter) public set_launch(_selection_id){
        launched_vote storage _launched = launched_map[_selection_id];
        bool check = false;
        for(uint i=0; i< _launched.itemTovoter[_item].length; i++){
            if(_launched.itemTovoter[_item][i].name == _ValidVoter){
                check = true;
                break;
            }
        }
        if(!check){
             _launched.itemTovoter[_item].push(candidate_2(_ValidVoter,_item,0));
             _launched.ValidList.push(_ValidVoter);
        }   
    }
    function DelVoter(uint16 _selection_id, string memory _item,address  _ValidVoter) public set_launch(_selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        cand_2_array_delete(_launched.itemTovoter[_item],_ValidVoter);
        address_array_delete(_launched.ValidList,_ValidVoter);
    }
    function SetCandidate(uint16 _selection_id, string memory _item, string memory _cand)  public set_launch(_selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        bool check = false;
        for(uint i=0; i< _launched.itemTocand[_item].length; i++){
            if(string_compare(_launched.itemTocand[_item][i].name,_cand)&&(string_compare(_launched.itemTocand[_item][i].item,_item))) {
                check = true;
                break;
            }
        }
        if(!check){
            _launched.itemTocand[_item].push(candidate(_cand,_item,0));
        }
    }
    function DelCandidate(uint16 _selection_id, string memory _item,string memory _cand) public set_launch(_selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        cand_array_delete(_launched.itemTocand[_item],_cand);
    }
    function SetItem(uint16 _selection_id, string memory _item) public set_launch(_selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        bool check = false;
        for(uint i=0; i< _launched.items.length; i++){
            if(string_compare(_launched.items[i],_item)){
                check = true;
                break;
            }
        }
        if(!check){
            _launched.items.push(_item);
        }
    }
    function DelItem(uint16 _selection_id, string memory _item) public set_launch(_selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        string_array_delete(_launched.items,_item);
        bool[] memory record = new bool[](_launched.itemTovoter[_item].length);
        for(uint i=0; i<record.length; i++)
        {
            record[i] = false;
        }
        for(uint k=0; k<_launched.itemTovoter[_item].length; k++)
        {
            for(uint i=0; i<_launched.items.length; i++)
            {
                for(uint j=0; j<_launched.itemTovoter[_launched.items[i]].length; j++)
                {
                    if(_launched.itemTovoter[_launched.items[i]][j].name == _launched.itemTovoter[_item][k].name)
                    {
                        record[k] = true;
                    }
                }
            }
        }
        for(uint i=0; i<record.length; i++)
        {
            if(record[i] == false)
            {
                address_array_delete(_launched.ValidList,_launched.itemTovoter[_item][i].name);
            }
        }
        _launched.itemTovoter[_item].length = 0;
        _launched.itemTocand[_item].length = 0;
    }
    function SetVoterState(launched_vote storage _launched, address  _ValidVoter) internal {
        voter_state memory vs;
        vs.id = _ValidVoter;
        vs.item = _launched.voterToitems[_ValidVoter];
        vs.start_check= false;
        _launched.state_map[_ValidVoter] = vs;
    }
    function SetItemToFinal( launched_vote storage _launched,string memory _item) internal {
        initial_result_item(_launched.vote_result,_item);
    }
    function SetCandidateToFinal( launched_vote storage _launched, string memory _item,string memory _cand) internal {
        initial_result_cand(_launched.vote_result, _item,_cand);
    }

    function set_vote_end(uint16 _selection_id) public check_launcher(_selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        _launched.vote_available = 2;
        idToVoter[_launched.launcher_address].launch = false; 
    }
    function set_vote_start(uint16 _selection_id) public set_launch(_selection_id) {
        launched_vote storage _launched = launched_map[_selection_id];
        for(uint i=0; i< _launched.items.length; i++){
            SetItemToFinal(_launched,_launched.items[i]);
            for(uint j=0; j<_launched.itemTocand[_launched.items[i]].length; j++){
                SetCandidateToFinal(_launched,_launched.items[i],_launched.itemTocand[_launched.items[i]][j].name);
            }
            for(uint j=0; j<_launched.itemTovoter[_launched.items[i]].length; j++){
                _launched.voterToitems[_launched.itemTovoter[_launched.items[i]][j].name].push(_launched.items[i]);
            }
        }
        for(uint i=0; i< _launched.ValidList.length; i++){
            SetVoterState( _launched, _launched.ValidList[i]);
        }
        _launched.vote_available = 1;
        for(uint i=0; i<_launched.ValidList.length; i++)
        {
            require(launched_map[_selection_id].vote_available == 1);
            voter_state storage _state = find_voterstate(_launched, _launched.ValidList[i]);
            for(uint j=0; j< _state.item.length; j++){
                _state.ballots[_state.item[j]] = ballot(" ", _state.item[j],false);
            }
            _state.ballots_check = true;
        }
    }
    function find_state(uint16 _selection_id) view public returns(uint8)
    {
        return launched_map[_selection_id].vote_available;
    }
    function find_voterstate(launched_vote storage _launched, address  _UserId) view internal returns( voter_state storage _state) {
        return _launched.state_map[_UserId];
    }
    function CreateNewAccount(address _adrs) public { 
        _createNewVoter(_adrs);
    }

    function send_ballot(uint16 _selection_id,address _UserId, string memory _item, string memory _cand) public {
        launched_vote storage _launched = launched_map[_selection_id];
        voter_state storage _state = find_voterstate(_launched, _UserId);
        require(_state.ballots_check == true);
        require(_state.ballots[_item].sent == false);  
         _state.ballots[_item].candidate = _cand;
        update_result(_launched.vote_result,_state.ballots[_item]);
        _state.ballots[_item].sent = true;
    }
    function view_result(uint16 _selection_id, string memory _item,string memory _candidate) view public returns(uint) {
        launched_vote storage _launched = launched_map[_selection_id];
        for(uint i=0; i< _launched.vote_result.final_result[_item].length; i++){
            if(string_compare(_launched.vote_result.final_result[_item][i].name,_candidate)){
                return (_launched.vote_result.final_result[_item][i].num);
            }
        }
        return 0;
    }
}




