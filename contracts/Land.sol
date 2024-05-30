pragma solidity >=0.4.22 <0.9.0;

pragma abicoder v2;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract Land is ERC721 {
    struct LandInfo {
        string image;
        string latitude;
        string longitude;
        uint256 area;
        string title;
        string zoning;
        string[] features;
        address firstOwner;
        address currentOwner;
    }

    address public owner;
    uint256 public tokenIdCounter;
    mapping(uint256 => LandInfo) private _landInfoByTokenId;
    mapping(address => uint256[]) private _tokensByOwner;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        tokenIdCounter = 1;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    event LandInfoUpdated(uint256 indexed tokenId, LandInfo newLandInfo);

    function mintNFT(LandInfo memory _landInfo) external onlyOwner {
        _landInfoByTokenId[tokenIdCounter] = _landInfo;

        _safeMint(_landInfo.firstOwner, tokenIdCounter);

        tokenIdCounter++;
    }

    function editLandInfo(uint256 _tokenId, LandInfo memory _newLandInfo) external onlyOwner {
        require(_exists(_tokenId), "Token ID does not exist");
        
        LandInfo storage currentLandInfo = _landInfoByTokenId[_tokenId];
        currentLandInfo.image = _newLandInfo.image;
        currentLandInfo.latitude = _newLandInfo.latitude;
        currentLandInfo.longitude = _newLandInfo.longitude;
        currentLandInfo.area = _newLandInfo.area;
        currentLandInfo.title = _newLandInfo.title;
        currentLandInfo.zoning = _newLandInfo.zoning;

        delete currentLandInfo.features;
        for (uint256 i = 0; i < _newLandInfo.features.length; i++) {
            currentLandInfo.features.push(_newLandInfo.features[i]);
        }

        emit LandInfoUpdated(_tokenId, currentLandInfo);
    }



    function getLandInfoById(uint256 _tokenId) external view returns (LandInfo memory) {
        require(_exists(_tokenId), "Token ID does not exist");
        return _landInfoByTokenId[_tokenId];
    }

    function getTokenOwnerById(uint256 _tokenId) external view returns (address) {
        require(_exists(_tokenId), "Token ID does not exist");
        return ownerOf(_tokenId);
    }

    function forceRetrieveToken(uint256 _tokenId) external onlyOwner {
        require(_exists(_tokenId), "Token ID does not exist");
        address currentOwner = ownerOf(_tokenId);
        _transfer(currentOwner, owner, _tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (from != address(0) && to != address(0)) {
            super._beforeTokenTransfer(from, to, tokenId);
        }

        if (from == address(0)) {
            // Minting scenario
            _tokensByOwner[to].push(tokenId);
        } else if (to == address(0)) {
            // Burning scenario
            _removeTokenFromOwner(from, tokenId);
        } else {
            // Regular transfer scenario
            _removeTokenFromOwner(from, tokenId);
            _tokensByOwner[to].push(tokenId);

            // Update current owner in LandInfo
            _landInfoByTokenId[tokenId].currentOwner = to;
        }
    }

    function _removeTokenFromOwner(address ownerAddress, uint256 tokenId) internal {
        uint256 length = _tokensByOwner[ownerAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (_tokensByOwner[ownerAddress][i] == tokenId) {
                _tokensByOwner[ownerAddress][i] = _tokensByOwner[ownerAddress][length - 1];
                _tokensByOwner[ownerAddress].pop();
                break;
            }
        }
    }

    function getAllLandInfoByOwner(address _owner) external view returns (LandInfo[] memory) {
        uint256[] memory tokenIds = _tokensByOwner[_owner];
        uint256 count = tokenIds.length;
        LandInfo[] memory result = new LandInfo[](count);

        for (uint256 i = 0; i < count; i++) {
            result[i] = _landInfoByTokenId[tokenIds[i]];
        }

        return result;
    }

    function getAllLands(uint256 _pageNumber, uint256 _pageSize) external view returns (LandInfo[] memory) {
        uint256 totalTokens = tokenIdCounter - 1;
        uint256 startIndex = (_pageNumber - 1) * _pageSize + 1;

        require(startIndex <= totalTokens, "Start index exceeds total tokens");

        uint256 endIndex = startIndex + _pageSize - 1;
        if (endIndex > totalTokens) {
            endIndex = totalTokens;
        }

        uint256 resultSize = endIndex - startIndex + 1;
        LandInfo[] memory allLands = new LandInfo[](resultSize);

        for (uint256 i = startIndex; i <= endIndex; i++) {
            allLands[i - startIndex] = _landInfoByTokenId[i];
        }

        return allLands;
    }

    function getAvailablePageCount(uint256 _pageSize) external view returns (uint256) {
        require(_pageSize > 0, "Page size must be greater than zero");
        uint256 totalTokens = tokenIdCounter - 1;

        if (totalTokens == 0) {
            return 0; // No tokens available, so no pages
        }

        uint256 pageCount = totalTokens / _pageSize;
        if (totalTokens % _pageSize != 0) {
            pageCount++; // Add one page for the remaining tokens
        }

        return pageCount;
    }

    function getCurrentOwnerByTokenId(uint256 _tokenId) external view returns (address) {
        require(_exists(_tokenId), "Token ID does not exist");
        return _landInfoByTokenId[_tokenId].currentOwner;
    }

}
