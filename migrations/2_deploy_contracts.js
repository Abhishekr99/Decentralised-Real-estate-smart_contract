const landToken = artifacts.require('landToken');

module.exports = function(deployer) {
  deployer.deploy(landToken,'Land','la');
};