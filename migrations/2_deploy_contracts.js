var HRACrowdfund = artifacts.require("./HRACrowdfund.sol");
var HRAToken = artifacts.require("./HRAToken.sol");

module.exports = function(deployer) {
  deployer.deploy(HRACrowdfund).then(()=>{
    return deployer.deploy(HRAToken , HRACrowdfund.address , "0x52751f79c5D0c1558f03CbB57E7D872079f4ccd3");
  });
  
};
