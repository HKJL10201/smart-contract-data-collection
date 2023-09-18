pragma solidity ^0.4.0;


/*
 * The BaseContentManagementContract is the parent contract of all the
 * ContentManagementContracts that has been deployed. It has a constructor that
 * allows to initialize all the fields of an item, that is:
 * - cntViews:
 *          an integer that keeps count of all the views
 *          (that is of all the consume content)
 * - balance:
 *          an integer that keeps count of the finances of the content;
 * - viewList:
 *          a list of all the viewers;
 * - struct Content that contains:
 *   - name:        the name of the item;
 *   - nameAuthor:  the name of the author;
 *   - genre:       the genre of the item;
 *   - cost:        the cost of the item;
 *   - time:        the time in block height at the moment of the
 *                  contract creation in the blockchain
 *
 * Many of the functions in the contract are getter of all the item's fields.
 * Only the grantAccess, the consumeContent, the feesDistributed and
 * the addContent are the exception.
 */
contract BaseContentManagementContract {

    uint256 private cntViews = 0;
    
    address private owner;
    
    uint256 private balance = 0;
    
    mapping(address => bool) private viewList;

    struct Content{
        bytes32 name;
        bytes32 nameAuthor;
        bytes32 genre;
        uint256 cost;
        uint256 time;
    }
    
    Content c;
    
    constructor(bytes32 na, bytes32 nameAuthor, bytes32 genre, uint256 time)
        public payable
            {
                c = Content(na, nameAuthor, genre, msg.value, time);
                owner = msg.sender;
                balance = msg.value;
            }
    /* Getter of the item's name */
    function getName() public view returns(bytes32) { return c.name; }
    /* Getter of the item's genre */
    function getGenre() public view returns(bytes32) { return c.genre; }
    /* Getter of the name of the author of the item */
    function getAuthor() public view returns(bytes32) { return c.nameAuthor; }
    /* Getter of the item's cost */
    function getCost() public view returns(uint256) { return c.cost; }
    /* Getter of the number of the statistic */
    function getStatistic() public view returns(uint256) { return cntViews; }
    /* Getter of the time (block number) of the item */
    function getTime() public view returns(uint256) { return c.time; }
    /* Getter of the address of the author */
    function getOwner() public view returns(address) { return owner; }
    /* Setter of the sender's viewer to true, for granting the access to the user */
    function grantAccess(address sndr) external { viewList[sndr] = true; }
    /* This function increments the views' number only whether the sender
     * has already obtained the access */
    function consumeContent(address sndr) external
        { require(viewList[sndr]); cntViews += 1; }
    /* This function calls the addContent() of the
     * interface exposed by catalogContract */
    function addContent(address catalog) public payable
        {
            require(owner == msg.sender, "Only the owner of the contract can add the content.");
            catalogContract(catalog).addContent();
        }
    
    function getBalance() public view returns(uint256) { return address(this).balance; }

}

/* The following contracts are inherited by the previous one and differs
 * only for the values given to the constructor. */

contract ContentManagementContract1 is BaseContentManagementContract
    ("Viva", "ZenCircus", "Indie", block.number) { }

contract ContentManagementContract2 is BaseContentManagementContract
    ("Ilenia", "ZenCircus", "Indie", block.number) { }

contract ContentManagementContract3 is BaseContentManagementContract
    ("Strategie", "Afterhours", "Indie", block.number) { }

contract ContentManagementContract4 is BaseContentManagementContract
    ("Brexit", "Canova", "Indie", block.number)
        { }

contract ContentManagementContract5 is BaseContentManagementContract
    ("1984", "Salmo", "HipHop", block.number)
        { }


/* This is the main contract. The descriptions of all the functions and
 * data structures used into it, are given below. */
contract catalogContract {
    
    /* the struct of the Customer is composed by:
     * registered:
     *      a boolean flag needed for distinguish between the new customers and
     *      the already registered ones;
     * operations:
     *      the number of operations carried out by the customer
     *      with the premium account;
     * premium:
     *      a boolean flag for distinguish between the premium customers and
     *      the standard ones;
     * contents:
     *      an array of all the contents buyed by the current customer;
     * contentsLength:
     *      an integer that identifies the length of the contents;
     * gifts:
     *      an array of all the gifts received by other customers;
     * giftsLength:
     *      an integer that identifies the length of the gifts of the customer.
     * 
     */
    struct Customer{
        bool registered;
        uint256 blockNum;
        bool premium;
        mapping(uint256 => BaseContentManagementContract) contents;
        uint256 contentsLength;
        mapping(uint256 => BaseContentManagementContract) gifts;
        uint256 giftsLength;
    }
    
    /* This struct is useful for knowing both
     * author's address and item's name and cost */
    struct ContentsInside {
        bytes32 name;
        address who;
        uint256 cost;
    }
    
    /* the struct of the Author is composed by:
     * contents:
     *      a map between an integer identifier and the struct ContentsInside, 
     *      useful for knowing author's address and item's name;
     * contentsLength:
     *      an integer that identifies the number of the contents
     *      published by the author;
     * mostPopItem:
     *      the name of most popular item that belong to the current Author;
     * max_occ:
     *      the maximum occurrence of the most popular item of the current Author;
     * occs:
     *      a mapping for representing the total occurrences of each content
     *      published by the current Author (so it'll never be zeroed);
     * occs4Payment:
     *      a mapping for representing the current occurrences of each content
     *      published by the current Author (it'll zeroed after v visits);
     * payment:
     *      an integer for taking into account the payment that the current
     *      smart contract must make to the current Author;
     * authAddress:
     *      the address of the current author.
     */
    struct Author{
        mapping(uint256 => ContentsInside) contents;
        uint256 contentsLength;
        bytes32 mostPopItem;
        uint256 max_occ;
        mapping(bytes32 => uint256) occs;
        mapping(bytes32 => uint256) occs4Payment;
        uint256 payment;
        address authAddress;
    }
    
    /* the struct of the Genre is composed by:
     * mostPopItem:
     *      the item that is the most popular of that genre;
     * max_occ:
     *      the number of views of the most popular item of that genre;
     * occs:
     *      a mapping between the genres of the items and their number of views
     */
    struct PossibleGenres{
        bytes32 mostPopItem;
        uint256 max_occ;
        mapping(bytes32 => uint256) occs;
    }
    
    /* The following data structures are useful for knowing for each content,
     * the item's name and author's address:
     * contents:
     *          a map between an integer identifier and the ContentsInside struct;
     * contentsName:
     *          a map between the item's name and the ContentsInside struct;
     * contentsLength:
     *          an integer for keeping track of the contents length.
     */
    mapping(uint256 => ContentsInside) contents;
    mapping(bytes32 => ContentsInside) contentsName;
    uint256 internal contentsLength = 0;
    

    /* The following variables are related to the author:
     * authors:
     *      it's a map from nameAuthors to Author structure;
     * nameAuthors:
     *      it's an array without repetitions of all the authors that interact
     *      with the service;
     * noAuthors:
     *      it's a counter of all the different authors that interact with
     *      the service;
     * latestAuths:
     *      it's a map from the author to the latest content
     *      published by the author.
     */
    mapping(bytes32 => Author) authors;
    //mapping(address => Author) authorsAddresses;
    mapping(uint256 => bytes32) nameAuthors;
    uint256 noAuthors = 0;
    mapping(bytes32 => bytes32) latestAuths;
    
    /* The following data structure is related to the customers that
     * interact with the smart contract:
     * customer:
     *      it's a map from the address of the customer
     *      to the Customer data structure;
     * addressCustomers:
     *      it's a map from an index and the address of the customer;
     * noCustomers:
     *      it's an integer useful for keeping track of the number of customers.
     */
    mapping(address => Customer) customers;
    mapping(uint256 => address) addressCustomers;
    uint256 noCustomers = 0;

    /* The following data structures are related to the possible genres of the
     * contents that the authors may publish. These data structures are useful
     * for speeding up some of the tasks provided by the catalogContract:
     * gens:
     *      it's a map from the possible genre to the genres data structure,
     *      useful for providing the most popular item of that genre;
     * latestGens:
     *      it's a map from the possible genre to the last published
     *      item of that genre.
     */
    mapping(bytes32 => PossibleGenres) gens;
    mapping(uint256 => bytes32) gensIdx;
    uint256 noGenres = 0;
    mapping(bytes32 => bytes32) latestGens;
    
    /* This is the address of the creator of the catalogContract smart contract */
    address owner;

    /* The following events are triggered in different situations.
     * The watchers in javascript will be notified every time that one of
     * the following occurs:
     * - contentAdded:          it is added a content;
     * - giftContentSent:       it is gifted to the user destination an item;
     * - giftPremiumSent:       it is gifted to the user destination
     *                              the premium account;
     * - grantContentAccess:    it is granted the access to a certain content;
     * - boughtPremium:         it is buyed the premium account;
     * - distributeTotalFeeds:  the fees collected over time are distributed over
     *                              all the authors proportionally distributed
     *                              over the number of views of each author
     */
    event contentAdded(address publisher, bytes32 item);
    event giftContentSent(address sender, bytes32 gift, address destination);
    event giftPremiumSent(address sender, address destination);
    event grantContentAccess(address consumer, bytes32 item);
    event boughtPremium(address consumer);
    event distributeTotalFeeds();
    event payed(address rcpt, uint256 amount);
    
    /* The following variables stands for:
     * premiumCost:
     *              the cost of a premium account;
     * premiumTime:
     *              the time of a premium account (in which it is active);
     * occurrenceLimit:
     *              the number of occurrences which when reached, trigger
     *              the fees' distribution;
     * currentOccurrence:
     *              the counter of the occurrences that has not to exceed
     *              the occurrence limit;
     * totalGathered:
     *              the balance that has to be divided among all the authors.
     */
    uint256 internal premium_Cost = 0.002 ether;
    uint256 internal premiumTime = 3;
    
    uint256 internal occurrenceLimit = 2;
    uint256 internal currentOccurrence = 0;

    uint256 internal totalGathered = 0;

    /* The following modifiers are useful for doing a pruning of all the access
     * that can be done by the users.
     * checkIfNotYetRegisteredCust:
     *          it checks whether the current user has not already been registered
     *          as customer;
     * checkIfAlreadyRegisteredCust:
     *          it checks whether the current user has already been registered 
     *          as customer;
     * onlyForStandard:
     *          it checks whether the user has not the premium account;
     * buyingPremium:
     *          it checks whether the msg.value is the one needed for
     *          buying the premium account;
     * onylForPremium:
     *          it checks whether the current user has the premium account.
     */
    modifier checkIfNotYetRegisteredCust
        {require(!customers[msg.sender].registered, "Not registered customer required"); _;}
    modifier checkIfAlreadyRegisteredCust
        {require(customers[msg.sender].registered, "Registered customer required"); _;}
    modifier onlyForStandard
        {require(!customers[msg.sender].premium, "You are premium!"); _;}
    modifier buyingPremium
        {require(msg.value == premium_Cost, "Message value must be equal to the premium cost: 2000000000000000 wei"); _;}
    modifier onlyForPremium
        {require(customers[msg.sender].premium, "Premium account expired"); _;}

    /* The only operation done by the costructor is identifying the sender of
     * the contract, that is the owner. */
    constructor() public payable { owner = msg.sender; }
    
    /* This function registers the user as customer. No control has been done

* for checking whether the user is also an author, because this situation
     * is actually possible. */
    function registerAsCustomer()
        public
        checkIfNotYetRegisteredCust() {
            address snd = msg.sender;
            customers[snd].registered = true;
            customers[snd].blockNum = 0;
            customers[snd].premium = false;
            customers[snd].contentsLength = 0;
            addressCustomers[noCustomers] = msg.sender;
            noCustomers += 1;
        }
    
    /* This function returns the list of contents name. */
    function getContentList()
        view
        public
        returns(bytes32[] toret)
            {
                toret = new bytes32[](contentsLength);
                for(uint i = 0; i < contentsLength; i++)
                    toret[i] = contents[i].name;
                return toret;
            }

    /* This function returns the list of x newest contents. It checks whether
     * the x parameter given in input is smaller of equal of the number of contents. */
    function getNewcontentsList(uint x)
        view
        public
        returns(bytes32[] toret)
            {
                require(x <= contentsLength);
                toret = new bytes32[](x);
                uint j = 0;
                uint i = contentsLength - 1;
                while(j < x && i >= 0){
                    toret[j] = contents[i].name;
                    i -= 1;
                    j += 1;
                }
                return toret;
            }

    function getAuthorList()
        view
        public
        returns(bytes32[] toret)
            {
                toret = new bytes32[](noAuthors);
                for(uint i = 0; i < noAuthors; i++)
                    toret[i] = nameAuthors[i];
                return toret;
            }

    function getCustomerList()
        view
        public
        checkIfAlreadyRegisteredCust()
        returns(address[] toret)
            {
                toret = new address[](noCustomers);
                for(uint i = 0; i < noCustomers; i++)
                    toret[i] = addressCustomers[i];
                return toret; 
            }

    function getGenreList()
        view
        public
        returns(bytes32[] toret)
            {
                toret = new bytes32[](noGenres);
                for(uint i = 0; i < noGenres; i++)
                    toret[i] = gensIdx[i];
                return toret; 
            }


    /* This function returns the latest item of the genre given in input. */
    function getLatestByGenre(bytes32 x)
        public
        view
        returns(bytes32)
            { return latestGens[x]; }

    /* This function returns the most popular item of the genre given in input.
     * Most popular here, means the content that has received the maximal number
     * of views; a view is performed when the consumeContent of that content
     * has been called. */
    function getMostPopularByGenre(bytes32 x)
        public
        view
        returns(bytes32)
            { return gens[x].mostPopItem; }


    /* This function returns the latest item published by the author given in input. */
    function getLatestByAuthor(bytes32 x)
        public
        view
        returns(bytes32)
            { return latestAuths[x]; }

    /* This function returns the most popular item published by the author given
     * in input. Most popular here, means the content that has received the maximal
     * number of views; a view is performed when the consumeContent of that content
     * has been called. */
    function getMostPopularByAuthor(bytes32 x)
        public
        view
        returns(bytes32)
            { return authors[x].mostPopItem; }
    
    /* This function returns a boolean representing the presence or absence of
     * a premium account of the address given in input; here, the address identifies
     * a customer. */
    function isPremium(address x)
        public
        view
        checkIfAlreadyRegisteredCust()
        returns(bool)
            { return customers[x].premium; }

    /* This function returns the cost of the premium service. */
    function premiumCost()
        view
        public
        returns(uint256)
            { return premium_Cost; }
    
    /* This function is the one that can be called by the contract interface.
     * It has to be declared as public, since its signature is on the contract
     * interface, but for publishing, an user must have sent a
     * BaseContentManagementContract, so this is an implicit check of the
     * address of the sender, so a customer can not call this addContent. */
    function addContent()
        public
        payable
            {
                BaseContentManagementContract b = BaseContentManagementContract(msg.sender);
                
                ContentsInside memory ci = ContentsInside(b.getName(), address(b), b.getCost());
                contents[contentsLength] = ci;
                contentsName[ci.name] = ci;
                contentsLength += 1;
                
                bytes32 currentAuthor = b.getAuthor();
                
                latestGens[b.getGenre()] = ci.name;
                latestAuths[currentAuthor] = ci.name;

                uint256 ctsLen = authors[currentAuthor].contentsLength;
                
                if(ctsLen > 0){
                    authors[currentAuthor].contents[ctsLen] = ci;
                    authors[currentAuthor].contentsLength += 1;
                }
                else {
                    nameAuthors[noAuthors] = currentAuthor;
                    Author memory a = Author(1, ci.name, 0, 0, b.getOwner());
                    authors[currentAuthor] = a;
                    authors[currentAuthor].contents[0] = ci;
                    authors[currentAuthor].occs[ci.name] = 0;
                    authors[currentAuthor].occs4Payment[ci.name] = 0;
                    authors[currentAuthor].payment = 0;
                    
                    noAuthors += 1;
                }
                emit contentAdded(msg.sender, ci.name);
            }

    /* This function updates the maximum views for the author data structure. */
    function updateMaxViewsForAuthor(bytes32 nmAuth, bytes32 nmItem)
        private
            {
                authors[nmAuth].occs[nmItem] += 1;
                authors[nmAuth].occs4Payment[nmItem] += 1;
                authors[nmAuth].contents[authors[nmAuth].contentsLength].name = nmItem;
                if(authors[nmAuth].mostPopItem != nmItem){
                    if(authors[nmAuth].max_occ < authors[nmAuth].occs[nmItem]){
                        authors[nmAuth].mostPopItem = nmItem;
                        authors[nmAuth].max_occ = authors[nmAuth].occs[nmItem];
                    }
                } else
                    authors[nmAuth].max_occ += 1;
            }
    
    /* This function is used for searching the genre of an item. */
    function searchGenre(bytes32 nameGenre)
        private
        view
        returns(uint256)
            {
                for(uint i = 0; i < noGenres; i++)
                    if(nameGenre == gensIdx[i])
                        return i;
                return noGenres+1;
            }
    
    /* This function updates the maximum views for the genre data structure. */
    function updateMaxViewsForGenre(bytes32 nameGenre, bytes32 nmItem)
        private
            {
                if(searchGenre(nameGenre) > noGenres){
                    gensIdx[noGenres] = nameGenre;
                    noGenres += 1;
                }
                gens[nameGenre].occs[nmItem] += 1;
                if(gens[nameGenre].mostPopItem != nmItem){
                    if(gens[nameGenre].max_occ < gens[nameGenre].occs[nmItem]){
                        gens[nameGenre].mostPopItem = nmItem;
                        gens[nameGenre].max_occ = gens[nameGenre].occs[nmItem];
                    }
                } else
                    gens[nameGenre].max_occ += 1;
            }
    
    function getBalance()
        public
        view
        returns(uint256)
            { return address(this).balance; }
    
    /* This function distributes the feeds to all the authors proportionally to
     * the nuber of views of the contents that they have published. It is
     * triggered by the getContent function every occurrenceLimit views. */
    function redistribution()
        private
            {
                uint256 fee4View = totalGathered / currentOccurrence;
                for(uint i = 0; i < noAuthors; i++){
                    for(uint j = 0; j < authors[nameAuthors[i]].contentsLength; j++){
                        bytes32 th = nameAuthors[i];
                        bytes32 itemName = authors[th].contents[j].name;
                        uint256 pmnt = authors[th].occs4Payment[itemName] * fee4View;
                        authors[th].payment += pmnt;
                        authors[th].occs4Payment[itemName] = 0;
                    }
                }
                currentOccurrence = 0;
                emit distributeTotalFeeds();
            }
    
    /* This function calles the redistribution function either when the
     * getContent or when the closeContract calls it after having checked which
     * is the caller one. */
    function distributeFeeds(bool closing)
        internal
            {
                uint i;
                if(currentOccurrence != 0){
                    if(closing){
                        redistribution();
                        for(i = 0; i < noAuthors; i++){
                            bytes32 th = nameAuthors[i];
                            uint256 pm = authors[th].payment;
                            require(owner.balance >= pm, "owner.balance < author.payment");
                            require(pm > 0, "author.payment == 0");
                            if(!authors[th].authAddress.send(pm))
                                revert();
                            emit payed(authors[th].authAddress, pm);
                        }
                    }
                    else
                        if(currentOccurrence >= occurrenceLimit){
                            redistribution();
                            for(i = 0; i < noAuthors; i++){
                                bytes32 tho = nameAuthors[i];
                                uint256 pmt = authors[th].payment;
                                require(owner.balance >= pmt, "owner.balance < author.payment");
                                require(pmt > 0, "author.payment == 0");
                                if(!authors[tho].authAddress.send(pmt))
                                    revert();
                                emit payed(authors[tho].authAddress, pmt);
                            }
                        }
                }
            }
    

    /* This function searches the content on the base of the content's name
     * given in input. */
    function searchContent(bytes32 x)
        private
        view
        returns(address)
            {
                for(uint i = 0; i < contentsLength; i++)
                    if(contents[i].name == x)
                        return contents[i].who;
            }
    
    /* This function is called by the customer when he want to obtain the access
     * to the content on the base of the content's name given in input. */
    function getContent(bytes32 x)
        public
        payable
        checkIfAlreadyRegisteredCust()
        onlyForStandard()
        returns(address)
            {
                BaseContentManagementContract b = BaseContentManagementContract(searchContent(x));
                bytes32 nm = b.getName();
                address snd = msg.sender;
                require(b.getCost() == msg.value);
                totalGathered += msg.value;
                updateMaxViewsForAuthor(b.getAuthor(), nm);
                updateMaxViewsForGenre(b.getGenre(), nm);
                customers[snd].contents[customers[snd].contentsLength] = b;
                customers[snd].contentsLength += 1;
                emit grantContentAccess(snd, nm);
                b.grantAccess(snd);
                return b;
            }

    /* This function allows the customer to buy a premium account that will
     * expire after premiumTime operations. */
    function buyPremium()
        public
        payable 
        checkIfAlreadyRegisteredCust()
        onlyForStandard()
        buyingPremium()
            {
                address snd = msg.sender;
                customers[snd].premium = true;
                customers[snd].blockNum = block.number;
                emit boughtPremium(snd);
                totalGathered += premium_Cost;
            }

    /* This function can be called only by the premium customers that want to
     * get a content, so without paying for the access. */
    function getContentPremium(bytes32 x)
        public
        checkIfAlreadyRegisteredCust()
        onlyForPremium()
        returns(address)
            {
                address snd = msg.sender;
                if(customers[snd].blockNum + premiumTime <= block.number)
                    customers[snd].premium = false;
                BaseContentManagementContract b = BaseContentManagementContract(searchContent(x));
                bytes32 nm = b.getName();
                customers[snd].contents[customers[snd].contentsLength] = b;
                customers[snd].contentsLength += 1;
                emit grantContentAccess(snd, nm);
                b.grantAccess(snd);
                updateMaxViewsForAuthor(b.getAuthor(), nm);
                updateMaxViewsForGenre(b.getGenre(), nm);
                return b;
            }
    
    /* This function permits to make a present to another user which consist of
     * the content, whose name is provided in input. */
    function giftContent(bytes32 x, address u)
        public
        payable
        checkIfAlreadyRegisteredCust()
            {
                require(customers[u].registered, "Recipient not registered");
                BaseContentManagementContract b = BaseContentManagementContract(searchContent(x));
                require(msg.value == b.getCost(), "The value does not correspond to the cost of the item");
                totalGathered += msg.value;
                emit giftContentSent(msg.sender, b.getName(), u);

                customers[u].gifts[customers[u].giftsLength] = b;
                customers[u].giftsLength += 1;
                b.grantAccess(u);
            }

    /* This function permits to obtain the access to the content received as
     * present by another customer. It deletes the gifted element from the
     * gift list and add the same element on the contents list. */
    function getFromAGift()
        public
        checkIfAlreadyRegisteredCust()
        returns(bytes32)
            {
                address snd = msg.sender;
                uint last_idx = customers[snd].giftsLength - 1;
                BaseContentManagementContract b = customers[snd].gifts[last_idx];
                bytes32 nm = b.getName();
                require(last_idx >= 0, "Empty list");
                customers[snd].contents[customers[snd].contentsLength] = b;
                customers[snd].contentsLength += 1;
                delete customers[snd].gifts[last_idx];
                customers[snd].giftsLength -= 1;
                emit grantContentAccess(snd, nm);
                updateMaxViewsForAuthor(b.getAuthor(), nm);
                updateMaxViewsForGenre(b.getGenre(), nm);
                return nm;
            }

    /* This function allows to make a present to another customer which consist of
     * a premium account for that customer. */
    function giftPremium(address u)
        public
        payable
        checkIfAlreadyRegisteredCust()
        buyingPremium()
            {
                require(customers[u].registered);
                require(!customers[u].premium);
                emit giftPremiumSent(msg.sender, u);
                customers[u].premium = true;
                customers[u].blockNum = block.number;
                totalGathered += msg.value;
            }
    
    /* This function permits to consume the content, whose content is
     * identified by an integer. */
    function consumeContent(uint256 idx)
        public
        payable
        checkIfAlreadyRegisteredCust()
            { currentOccurrence += 1; distributeFeeds(false); customers[msg.sender].contents[idx].consumeContent(msg.sender); }

    /* This function returns the length of contents of the current customer. */
    function getCustomerContentList()
        public
        view
        checkIfAlreadyRegisteredCust()
        returns(bytes32[] toret)
            {
                address snd = msg.sender;
                toret = new bytes32[](customers[snd].contentsLength);
                for(uint i = 0; i < customers[snd].contentsLength; i++)
                    toret[i] = customers[snd].contents[i].getName();
                return toret;
            }

    /* This function gets the cost of a content given in input. */
    function getCostOfContent(bytes32 c)
        view
        public
        returns(uint256 cost)
            { return contentsName[c].cost; }

    /* This function returns the length of gifts received by the current customer. */
    function getCustomerGiftList()
        public
        view
        checkIfAlreadyRegisteredCust()
        returns(bytes32[] toret)
            {
                address snd = msg.sender;
                toret = new bytes32[](customers[snd].giftsLength);
                for(uint i = 0; i < customers[snd].giftsLength; i++)
                    toret[i] = customers[snd].gifts[i].getName();
                return toret;
            }
            
    /* This function closes the contract and payes the authors 
     * proportionally on the number of views. */
    function closeContract()
        public
        payable
            {
                require(owner == msg.sender,
                    "Only the deployer of the catalogContract can perform this");
                distributeFeeds(true);
                selfdestruct(owner);
            }
}