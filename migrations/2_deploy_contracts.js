const StreamerChannel = artifacts.require('StreamerChannel')
const PredictionSystem = artifacts.require('PredictionSystem')
const Prediction = artifacts.require('Prediction')
const InteractionSystem = artifacts.require('InteractionSystem')
const AttendanceSystem = artifacts.require('AttendanceSystem')

module.exports = (deployer, network, accounts) => {
  deployer
    .deploy(StreamerChannel)
    .then(() => deployer.deploy(PredictionSystem, StreamerChannel.address, 30))
    .then(() => deployer.deploy(Prediction, 5, StreamerChannel.address))
    .then(() => deployer.deploy(InteractionSystem, StreamerChannel.address))
    .then(function () {
      return deployer.deploy(
        AttendanceSystem,
        StreamerChannel.address,
      );
    });
};
