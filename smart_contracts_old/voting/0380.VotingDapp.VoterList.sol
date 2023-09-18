contract VoterList is IUC{
    userlist[] ListOfVoters;
    address newIUC = IUC.new(_name, _age, _gender, userAddress, eciMember);

    function GetAllVoters() returns UserAddress {
        for (var i = 0; i < ListOfVoters.length; i++)  {
            printf(address.ListOfVoters[i]);
        }
    }
    function GetContractAddress(UserAddress) {
        return newIUC(userAddress);
    }
    function GetUserDetails(ContractAddress) {
        return _myData;
    }
    function IsRegistred(address _user)ownerOnly public {
        voters[_user].IsRegistred = true;
    }
}
