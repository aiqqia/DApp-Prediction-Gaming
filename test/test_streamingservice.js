const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
var assert = require("assert");

const StreamerChannel = artifacts.require("../contract/StreamerChannel");
const PredictionSystem = artifacts.require("../contract/PredictionSystem");
const Prediction = artifacts.require("../contract/Prediction");
const InteractionSystem = artifacts.require("../contract/InteractionSystem");
const AttendanceSystem = artifacts.require("../contract/AttendanceSystem");

contract("PredictionSystem", function (accounts) {
  before(async () => {
    streamerInst = await StreamerChannel.deploy();
    predSysInst = await PredictionSystem.deploy();
    predictionInst = await Prediction.deploy();
    interactionInst = await InteractionSystem.deploy();
    attendanceInst = await AttendanceSystem.deploy();
  });

  it("Test deployment", async () => {
    assert.ok(streamerInst.address);
    assert.ok(predSysInst.address);
    assert.ok(predictionInst.address);
    assert.ok(interactionInst.address);
    assert.ok(AttendanceInst.address);
  });
});
