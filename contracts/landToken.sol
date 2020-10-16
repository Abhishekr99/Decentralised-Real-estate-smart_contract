pragma solidity 0.6.12;

contract landToken {
	
	uint _totalSupply;
	uint tokenId;
	string private _name;
	string private _symbol;
	bool private destructed = false;
	
	modifier alive {
	    require(!destructed,"Contract destroyed");
        _;
	}

	mapping (address => uint[]) private ownerTokens;
	mapping (uint => uint) public tokenCost;
	mapping (uint => string) public tokenLocation;
	mapping (address => mapping (uint => uint)) private ownerTokenIndex; //check
	mapping (uint => address payable) private tokenOwner; //check
	mapping (uint => address payable) private tokenApproval; //check
	mapping (address => mapping (address => bool)) private operatorApproval;
	mapping (address => uint) public visit;

	event Transfer (address indexed _from, address indexed _to, uint  indexed _tokenId);
	event Approval (address indexed _owner, address indexed _approved, uint indexed _tokenId);
	event ApprovalForAll (address indexed _owner, address indexed _operator, bool _approved);
	event AddLand (address indexed _owner, uint _cost, string _location, uint _tokenId);
	event VisitLand (address indexed _owner, uint _tokenId, address indexed _visiter);
	
	mapping (uint => bool) private isAvailable;
	//uint[] private tokenIds;

	function getLandcount() public view returns(uint){
	    return tokenId;
	}
	function getAvailability(uint _tokenId) public view  returns(bool) {
        return isAvailable[_tokenId];
    }
    
    function setAvailability(uint _tokenId, uint _cost) public {
        require(msg.sender == tokenOwner[_tokenId], "Your not the owner of land" );
        isAvailable[_tokenId]=true;
        tokenCost[_tokenId]=_cost;
    }

	constructor (string memory name, string memory symbol) public {
		_name = name;
		_symbol = symbol;
		_totalSupply = 0;
		tokenId = 0;
	}

	function name() alive public view  returns (string memory) {
        return _name;
    }

    function symbol() alive public view  returns (string memory) {
        return _symbol;
    }

	function totalSupply() alive public view returns (uint) {
		return _totalSupply;
	}

	function visited(uint _tokenId) alive public {
		require (msg.sender != tokenOwner[_tokenId], "Sender is the Owner of the land");
		visit[msg.sender] = _tokenId;
		emit VisitLand (tokenOwner[_tokenId], _tokenId, msg.sender);
	}
	
	function addLand (string memory location, uint cost) alive public {
		tokenId++;
	    tokenCost[tokenId] = cost;
	    tokenLocation[tokenId] = location;
	    tokenOwner[tokenId] = msg.sender;
        ownerTokens[msg.sender].push(tokenId);
        
        //tokenIds.push(tokenId);
        isAvailable[tokenId]=true;
        
        uint indexNew = ownerTokens[msg.sender].length;
        ownerTokenIndex[msg.sender][tokenId] = indexNew;
        //tokenId++;
        _totalSupply++;
        emit AddLand (msg.sender, cost, location, tokenId);
	}
	
	function buyLand (uint _tokenId) alive public payable {
	    
	    require(isAvailable[_tokenId]==true, "Land not available for sale");
	    
		require(visit[msg.sender] == _tokenId, "Please visit the Land before buying it");
	    require(msg.value >= tokenCost[_tokenId]*(10**18), "Didn't send enough money to but the land");
	    TransferFrom(tokenOwner[_tokenId], msg.sender, _tokenId, msg.value);
	    
	    isAvailable[_tokenId]=false;
	}
	
	function TransferFrom (address payable _from, address payable _to, uint _tokenId, uint _amount) alive public payable{
	    require(tokenOwner[_tokenId] == _from, "The seller doesn't own this token");
        require(_to != address(0), "Buyer non existant");
        
        _from.transfer(_amount);
        
        uint index = ownerTokenIndex[_from][_tokenId];
        if(ownerTokens[_from].length>1){
            uint lastToken = ownerTokens[_from][ownerTokens[_from].length-1];   
            ownerTokens[_from][index] = lastToken;
            ownerTokenIndex[_from][lastToken] = index;
        }
        
        ownerTokens[_from].pop();
        delete ownerTokenIndex[_from][_tokenId];
        delete tokenOwner[_tokenId];
        
        tokenOwner[_tokenId] = _to;
        ownerTokens[_to].push(_tokenId);
        uint indexNew = ownerTokens[_to].length-1;
        ownerTokenIndex[_to][_tokenId] = indexNew;
        
        emit Transfer(_from, _to, _tokenId);
	}

	function balanceOf (address _owner) alive external view returns (uint) {
		require(_owner != address(0), "Owner non existant");
		return ownerTokens[_owner].length;
	}

	function ownerOf (uint _tokenId) alive external view returns (address) {
		return tokenOwner[_tokenId];
	}

	function tokenOfOwnerByIndex (address _owner, uint index) alive public view returns (uint) {
	    require(_owner != address(0), "Owner non existant");
		return ownerTokenIndex[_owner][index];
	}

	function safeTransferFrom (address payable _from, address payable _to, uint _tokenId) alive public payable{
	    require(tokenOwner[_tokenId] == _from, "The seller doesn't own this token");
        require(msg.sender == _from || isApprovedForAll(_from, msg.sender), "Have to be the owner or approver of the land to perform this");
        require(_to != address(0), "Buyer non existant");
        
        uint index = ownerTokenIndex[_from][_tokenId];
        if(ownerTokens[_from].length>1){
            uint lastToken = ownerTokens[_from][ownerTokens[_from].length-1];   
            ownerTokens[_from][index] = lastToken;
            ownerTokenIndex[_from][lastToken] = index;
        }
        
        ownerTokens[_from].pop();
        delete ownerTokenIndex[_from][_tokenId];
        delete tokenOwner[_tokenId];
        
        tokenOwner[_tokenId] = _to;
        ownerTokens[_to].push(_tokenId);
        uint indexNew = ownerTokens[_to].length-1;
        ownerTokenIndex[_to][_tokenId] = indexNew;
        
        emit Transfer(_from, _to, _tokenId);
	}
	
	function isApprovedForAll(address _owner, address _operator) alive public view returns(bool) {
	    return operatorApproval[_owner][_operator];
	}
	
	function approve (address payable _approved, uint _tokenId) alive external payable {
	    require(_approved != tokenOwner[_tokenId], "Approval to current owner");
	    require(msg.sender == tokenOwner[_tokenId] || isApprovedForAll(tokenOwner[_tokenId], msg.sender), "Cannot be called by this address");
	    
	    tokenApproval[_tokenId] = _approved;
	    emit Approval (tokenOwner[_tokenId], _approved, _tokenId);
	}
	
	function getApproved (uint _tokenId) alive external view returns (address) {
	    return tokenApproval[_tokenId];
	}

    function setApprovalForAll (address _operator, bool _approved) alive external {
        require(_operator != msg.sender, "Caller cannot be approved");
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function implode() alive  public {
        destructed = true;
    }
	
}