pragma solidity >=0.4.22 <0.9.0;

pragma abicoder v2;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract Vehicle is ERC721 {
    struct VehicleInfo {
        string image;
        string manufacturer;
        string model;
        uint256 year;
        string color;
        string VIN;
        string vehicleType;
        string fuelType;
        string transmissionType;
        address firstOwner;
        address currentOwner;
    }

    address public owner;
    uint256 public tokenIdCounter;
    mapping(uint256 => VehicleInfo) private _vehicleInfoByTokenId;
    mapping(string => bool) private _existingVINs;
    mapping(string => uint256) private _tokenIdsByVIN;
    mapping(address => uint256[]) private _tokensByOwner;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        tokenIdCounter = 1;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    event VehicleInfoUpdated(uint256 indexed tokenId, VehicleInfo newVehicleInfo);

    function mintNFT(VehicleInfo memory _vehicleInfo) external onlyOwner {
        require(!_existingVINs[_vehicleInfo.VIN], "VIN already exists");
        _vehicleInfoByTokenId[tokenIdCounter] = _vehicleInfo;
        _existingVINs[_vehicleInfo.VIN] = true;
        _tokenIdsByVIN[_vehicleInfo.VIN] = tokenIdCounter;

        // Skip _beforeTokenTransfer call during minting
        _safeMint(_vehicleInfo.firstOwner, tokenIdCounter);

        tokenIdCounter++;
    }

    function editVehicleInfo(uint256 _tokenId, VehicleInfo memory _newVehicleInfo) external onlyOwner {
        require(_exists(_tokenId), "Token ID does not exist");
        VehicleInfo storage currentVehicleInfo = _vehicleInfoByTokenId[_tokenId];

        if (keccak256(bytes(currentVehicleInfo.VIN)) != keccak256(bytes(_newVehicleInfo.VIN))) {
            require(!_existingVINs[_newVehicleInfo.VIN], "New VIN already exists");
            _existingVINs[currentVehicleInfo.VIN] = false;
            _existingVINs[_newVehicleInfo.VIN] = true;
            _tokenIdsByVIN[_newVehicleInfo.VIN] = _tokenIdsByVIN[currentVehicleInfo.VIN];
            delete _tokenIdsByVIN[currentVehicleInfo.VIN];
        }

        currentVehicleInfo.image = _newVehicleInfo.image;
        currentVehicleInfo.manufacturer = _newVehicleInfo.manufacturer;
        currentVehicleInfo.model = _newVehicleInfo.model;
        currentVehicleInfo.year = _newVehicleInfo.year;
        currentVehicleInfo.color = _newVehicleInfo.color;
        currentVehicleInfo.VIN = _newVehicleInfo.VIN;
        currentVehicleInfo.vehicleType = _newVehicleInfo.vehicleType;
        currentVehicleInfo.fuelType = _newVehicleInfo.fuelType;
        currentVehicleInfo.transmissionType = _newVehicleInfo.transmissionType;
        

        emit VehicleInfoUpdated(_tokenId, currentVehicleInfo);
    }

    function getVehicleInfoByVIN(string memory _VIN) external view returns (VehicleInfo memory) {
        require(_tokenIdsByVIN[_VIN] != 0, "Token with this VIN does not exist");
        uint256 tokenId = _tokenIdsByVIN[_VIN];
        return _vehicleInfoByTokenId[tokenId];
    }

    function getVehicleInfoId(uint256 _tokenId) external view returns (VehicleInfo memory) {
        require(_exists(_tokenId), "Token ID does not exist");
        return _vehicleInfoByTokenId[_tokenId];
    }

    function getTokenOwnerById(uint256 _tokenId) external view returns (address) {
        require(_exists(_tokenId), "Token ID does not exist");
        return ownerOf(_tokenId);
    }

    function getTokenOwnerByVIN(string memory _VIN) external view returns (address) {
        require(_tokenIdsByVIN[_VIN] != 0, "Token with this VIN does not exist");
        uint256 tokenId = _tokenIdsByVIN[_VIN];
        return ownerOf(tokenId);
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

            // Update current owner in VehicleInfo
            _vehicleInfoByTokenId[tokenId].currentOwner = to;
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

    function getAllVehicleInfoByOwner(address _owner) external view returns (VehicleInfo[] memory) {
        uint256[] memory tokenIds = _tokensByOwner[_owner];
        uint256 count = tokenIds.length;
        VehicleInfo[] memory result = new VehicleInfo[](count);

        for (uint256 i = 0; i < count; i++) {
            result[i] = _vehicleInfoByTokenId[tokenIds[i]];
        }

        return result;
    }

    function getAllVehicles(uint256 _pageNumber, uint256 _pageSize) external view returns (VehicleInfo[] memory) {
        uint256 totalTokens = tokenIdCounter - 1;
        uint256 startIndex = (_pageNumber - 1) * _pageSize + 1;

        require(startIndex <= totalTokens, "Start index exceeds total tokens");

        uint256 endIndex = startIndex + _pageSize - 1;
        if (endIndex > totalTokens) {
            endIndex = totalTokens;
        }

        uint256 resultSize = endIndex - startIndex + 1;
        VehicleInfo[] memory allVehicles = new VehicleInfo[](resultSize);

        for (uint256 i = startIndex; i <= endIndex; i++) {
            allVehicles[i - startIndex] = _vehicleInfoByTokenId[i];
        }

        return allVehicles;
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
        return _vehicleInfoByTokenId[_tokenId].currentOwner;
    }

    function getCurrentOwnerByVIN(string memory _VIN) external view returns (address) {
        require(_tokenIdsByVIN[_VIN] != 0, "Token with this VIN does not exist");
        uint256 tokenId = _tokenIdsByVIN[_VIN];
        return _vehicleInfoByTokenId[tokenId].currentOwner;
    }
}