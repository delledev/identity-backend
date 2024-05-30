const LandHelper = artifacts.require("LandHelper");
const VehicleHelper = artifacts.require('VehicleHelper')


module.exports = function (deployer) {
  deployer.deploy(VehicleHelper, "VINS", "VNSD");
  deployer.deploy(LandHelper, "LAND", "LNSD");
};