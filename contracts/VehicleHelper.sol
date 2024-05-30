pragma solidity >=0.4.22 <0.9.0;

pragma abicoder v2;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./Vehicle.sol";

contract VehicleHelper is ERC721 {
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
        address to;
        bool isMintable;
        bool isDeclined;
        bool isMinted;
    }

    address public owner;
    Vehicle public vehicleContract;
    uint256 public tokenIdCounter;
    mapping(uint256 => VehicleInfo) private _vehicleInfoByTokenId;
   

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        tokenIdCounter = 1;
        owner = msg.sender;
        vehicleContract = new Vehicle(_name, _symbol);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function getOwner() public returns (address){
        return owner;
    }

    function createVehicleNFTApplication(
        string memory image,
        string memory manufacturer,
        string memory model,
        uint256 year,
        string memory color,
        string memory VIN,
        string memory vehicleType,
        string memory fuelType,
        string memory transmissionType) public {

        VehicleInfo memory newVehicleInfo = VehicleInfo({
            image: image,
            manufacturer: manufacturer,
            model: model,
            year: year,
            color: color,
            VIN: VIN,
            vehicleType: vehicleType,
            fuelType: fuelType,
            transmissionType: transmissionType,
            firstOwner: msg.sender,
            currentOwner: msg.sender,
            to: msg.sender,
            isMintable: false,
            isDeclined: false,
            isMinted: false
        });

        _vehicleInfoByTokenId[tokenIdCounter] = newVehicleInfo;
        tokenIdCounter++;
    }

    

    function setMintable(uint256 tokenId) external onlyOwner {
        require(msg.sender == owner, "Only the contract owner can set mintable status.");
        require(tokenId < tokenIdCounter, "Token ID does not exist.");
        require(_vehicleInfoByTokenId[tokenId].isDeclined == false, 'This application is already declined. Please create a new one.');

        _vehicleInfoByTokenId[tokenId].isMintable = true;
    }

    function setDeclined(uint256 tokenId) external onlyOwner {
        require(msg.sender == owner, "Only the contract owner can set mintable status.");
        require(tokenId < tokenIdCounter, "Token ID does not exist.");

        _vehicleInfoByTokenId[tokenId].isDeclined = true;
    }

    function mintcustomNFT(uint256 tokenId) public  payable {
        require(_vehicleInfoByTokenId[tokenId].isMintable == true, 'Must be mintable.');
        require(_vehicleInfoByTokenId[tokenId].isMinted == false, 'You already minted this NFT.');
        require(_vehicleInfoByTokenId[tokenId].to == msg.sender, 'You must be the owner of this application.');
        _vehicleInfoByTokenId[tokenId].isMinted = true;

        Vehicle.VehicleInfo storage currentVehicleInfo;

        currentVehicleInfo.image = _vehicleInfoByTokenId[tokenId].image;
        currentVehicleInfo.manufacturer = _vehicleInfoByTokenId[tokenId].manufacturer;
        currentVehicleInfo.model = _vehicleInfoByTokenId[tokenId].model;
        currentVehicleInfo.year = _vehicleInfoByTokenId[tokenId].year;
        currentVehicleInfo.color = _vehicleInfoByTokenId[tokenId].color;
        currentVehicleInfo.VIN = _vehicleInfoByTokenId[tokenId].VIN;
        currentVehicleInfo.vehicleType = _vehicleInfoByTokenId[tokenId].vehicleType;
        currentVehicleInfo.fuelType = _vehicleInfoByTokenId[tokenId].fuelType;
        currentVehicleInfo.transmissionType = _vehicleInfoByTokenId[tokenId].transmissionType;
        currentVehicleInfo.firstOwner = _vehicleInfoByTokenId[tokenId].firstOwner;
        currentVehicleInfo.currentOwner = _vehicleInfoByTokenId[tokenId].currentOwner;
        
        vehicleContract.mintNFT(currentVehicleInfo);

    }
    
    function getVehicleInfo(uint256 tokenId) public view returns (VehicleInfo memory) {
        require(tokenId < tokenIdCounter, "Token ID does not exist.");
        return _vehicleInfoByTokenId[tokenId];
    }

    function getNonMintableVehicles() public view returns (uint256[] memory, VehicleInfo[] memory) {
        uint256 nonMintableCount = 0;

        // First, count the number of non-mintable vehicles
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            if (!_vehicleInfoByTokenId[i].isMintable && !_vehicleInfoByTokenId[i].isDeclined && !_vehicleInfoByTokenId[i].isMinted) {
                nonMintableCount++;
            }
        }

        // Create arrays to hold the token IDs and non-mintable vehicles starting from index 1
        uint256[] memory tokenIds = new uint256[](nonMintableCount + 1);
        VehicleInfo[] memory nonMintableVehicles = new VehicleInfo[](nonMintableCount + 1);
        uint256 index = 1;

        // Collect the token IDs and non-mintable vehicles starting from index 1
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            if (!_vehicleInfoByTokenId[i].isMintable && !_vehicleInfoByTokenId[i].isDeclined && !_vehicleInfoByTokenId[i].isMinted) {
                tokenIds[index] = i;
                nonMintableVehicles[index] = _vehicleInfoByTokenId[i];
                index++;
            }
        }

        return (tokenIds, nonMintableVehicles);
    }

    function getChildAddress() public view returns (address) {
        return address(vehicleContract);
    }

    function getApplicationsByAddress(address addr) public view returns (uint256[] memory, VehicleInfo[] memory) {
        uint256 applicationCount = 0;

        // Count the number of applications associated with the given address
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            if (_vehicleInfoByTokenId[i].to == addr) {
                applicationCount++;
            }
        }

        // Create arrays to hold the application IDs and application information
        uint256[] memory applicationIds = new uint256[](applicationCount + 1);
        VehicleInfo[] memory applications = new VehicleInfo[](applicationCount + 1);
        uint256 index = 1;

        // Collect the application IDs and application information
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            if (_vehicleInfoByTokenId[i].to == addr) {
                applicationIds[index] = i;
                applications[index] = _vehicleInfoByTokenId[i];
                index++;
            }
        }

        return (applicationIds, applications);
    }
}