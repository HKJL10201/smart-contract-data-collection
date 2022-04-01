pragma solidity >=0.5.0 <0.6.0;

contract utility {
    struct candidate {
        string name;
        string item;
        uint num;
    }
    struct candidate_2 {
        address name;
        string item;
        uint num;
    }
    function string_array_delete(string[] storage _arr, string memory _item) internal {
       bool check = false;
        uint index = 0;
        for(uint i=0; i<_arr.length; i++){
            if(string_compare( _arr[i], _item)){
                check = true;
                index = i;
            }
        }
        if(check){
            uint _deleted_index = index;
            _arr[_deleted_index] = _arr[_arr.length-1];
            delete _arr[_arr.length - 1];
            _arr.length --;
        }
    }
    function address_array_delete(address[] storage _arr, address  _item) internal {
       bool check = false;
        uint index = 0;
        for(uint i=0; i<_arr.length; i++){
            if(_arr[i] ==  _item){
                check = true;
                index = i;
            }
        }
        if(check){
            uint _deleted_index = index;
            _arr[_deleted_index] = _arr[_arr.length-1];
            delete _arr[_arr.length - 1];
            _arr.length --;
        }
    }
   function uint16_array_delete(uint16[] storage _arr, uint16 _moved) internal {
        bool check = false;
        uint index = 0;
        for(uint i=0; i<_arr.length; i++){
            if(_arr[i] == _moved){
                check = true;
                index = i;
            }
        }
        if(check){
            uint _deleted_index = index;
            _arr[_deleted_index] = _arr[_arr.length-1];
            delete _arr[_arr.length - 1];
            _arr.length --;
        }
    }
    function cand_array_delete(candidate[] storage _arr, string memory _cand) internal {
        bool check = false;
        uint index = 0;
        for(uint i=0; i<_arr.length; i++){
            if(string_compare( _arr[i].name, _cand)){
                check = true;
                index = i;
            }
        }
        if(check){
            uint _deleted_index = index;
            _arr[_deleted_index] = _arr[_arr.length-1];
            delete _arr[_arr.length - 1];
            _arr.length --;   
        }
    }
    function cand_2_array_delete(candidate_2[] storage _arr, address _cand) internal {
        bool check = false;
        uint index = 0;
        for(uint i=0; i<_arr.length; i++){
            if(_arr[i].name == _cand){
                check = true;
                index = i;
            }
        }
        if(check){
            uint _deleted_index = index;
            _arr[_deleted_index] = _arr[_arr.length-1];
            delete _arr[_arr.length - 1];
            _arr.length --;   
        }
    }
    function string_compare(string memory _s1, string memory _s2) pure internal returns(bool) {
        if(uint256(keccak256(abi.encodePacked(_s1))) == uint256(keccak256(abi.encodePacked(_s2)))){
           return true;
        }
        else{
            return false;
        }
    }
}