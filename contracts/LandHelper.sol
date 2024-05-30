pragma solidity >=0.4.22 <0.9.0;

pragma abicoder v2;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./Land.sol";

contract LandHelper is ERC721 {
    struct LandInfo {
        string image;
        address currentOwner;
        address firstOwner;
        string latitude;
        string longitude;
        uint256 area;
        string title;
        string zoning;
        string[] features;
        address to;
        bool isMintable;
        bool isDeclined;
        bool isMinted;
    }

    address public owner;
    Land public landContract;
    uint public tokenIdCounter;
    mapping(uint256 => LandInfo) private _landInfoByTokenId;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        tokenIdCounter = 1;
        owner = msg.sender;
        landContract = new Land(_name, _symbol);
    }

     function getOwner() public returns (address){
        return owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function createLandApplication(
        string memory image,
        string memory latitude,
        string memory longitude,
        uint256  area,
        string memory title,
        string memory zoning,
        string[] memory features) public {

        LandInfo memory newLandInfo = LandInfo({
            image: image,
            latitude: latitude,
            longitude: longitude,
            area: area,
            title: title,
            zoning: zoning,
            features: features,
            firstOwner: msg.sender,
            currentOwner: msg.sender,
            to: msg.sender,
            isMintable: false,
            isDeclined: false,
            isMinted: false
        });

        _landInfoByTokenId[tokenIdCounter] = newLandInfo;
        tokenIdCounter++;
    }

    function setMintable(uint256 tokenId) external onlyOwner {
        require(msg.sender == owner, "Only the contract owner can set mintable status.");
        require(tokenId < tokenIdCounter, "Token ID does not exist.");
        require(_landInfoByTokenId[tokenId].isDeclined == false, 'This application is already declined. Please create a new one.');

        _landInfoByTokenId[tokenId].isMintable = true;
    }

    function setDeclined(uint256 tokenId) external onlyOwner {
        require(msg.sender == owner, "Only the contract owner can set mintable status.");
        require(tokenId < tokenIdCounter, "Token ID does not exist.");

        _landInfoByTokenId[tokenId].isDeclined = true;
    }

    function mintcustomNFT(uint256 tokenId) public {
        require(_landInfoByTokenId[tokenId].isMintable == true, 'Must be mintable.');
        require(_landInfoByTokenId[tokenId].isMinted == false, 'You already minted this NFT.');
        require(_landInfoByTokenId[tokenId].to == msg.sender, 'You must be the owner of this application.');
        _landInfoByTokenId[tokenId].isMinted == true;
        
        Land.LandInfo storage currentLandInfo;

        currentLandInfo.image = _landInfoByTokenId[tokenId].image;
        currentLandInfo.latitude = _landInfoByTokenId[tokenId].latitude;
        currentLandInfo.longitude = _landInfoByTokenId[tokenId].longitude;
        currentLandInfo.area = _landInfoByTokenId[tokenId].area;
        currentLandInfo.title = _landInfoByTokenId[tokenId].title;
        currentLandInfo.zoning = _landInfoByTokenId[tokenId].zoning;
        currentLandInfo.features = _landInfoByTokenId[tokenId].features;
        currentLandInfo.firstOwner = _landInfoByTokenId[tokenId].firstOwner;
        currentLandInfo.currentOwner = _landInfoByTokenId[tokenId].currentOwner;
        
        landContract.mintNFT(currentLandInfo);
    }

    function getLandInfo(uint256 tokenId) public view returns (LandInfo memory) {
        require(tokenId < tokenIdCounter, "Token ID does not exist.");
        return _landInfoByTokenId[tokenId];
    }

    function getNonMintableLands() public view returns (uint256[] memory, LandInfo[] memory) {
        uint256 nonMintableCount = 0;

        // First, count the number of non-mintable lands
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            if (!_landInfoByTokenId[i].isMintable && !_landInfoByTokenId[i].isDeclined) {
                nonMintableCount++;
            }
        }

        // Create arrays to hold the token IDs and non-mintable lands starting from index 1
        uint256[] memory tokenIds = new uint256[](nonMintableCount + 1);
        LandInfo[] memory nonMintableLands = new LandInfo[](nonMintableCount + 1);
        uint256 index = 1;

        // Collect the token IDs and non-mintable lands starting from index 1
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            if (!_landInfoByTokenId[i].isMintable && !_landInfoByTokenId[i].isDeclined) {
                tokenIds[index] = i;
                nonMintableLands[index] = _landInfoByTokenId[i];
                index++;
            }
        }

        return (tokenIds, nonMintableLands);
    }

    function getChildAddress() public view returns (address) {
        return address(landContract);
    }

    function getApplicationsByAddress(address addr) public view returns (uint256[] memory, LandInfo[] memory) {
        uint256 applicationCount = 0;

        // Count the number of applications associated with the given address
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            if (_landInfoByTokenId[i].to == addr) {
                applicationCount++;
            }
        }

        // Create arrays to hold the application IDs and application information
        uint256[] memory applicationIds = new uint256[](applicationCount + 1);
        LandInfo[] memory applications = new LandInfo[](applicationCount + 1);
        uint256 index = 1;

        // Collect the application IDs and application information
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            if (_landInfoByTokenId[i].to == addr) {
                applicationIds[index] = i;
                applications[index] = _landInfoByTokenId[i];
                index++;
            }
        }

        return (applicationIds, applications);
    }
}