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
    streamerInst = await StreamerChannel.deployed();
    predSysInst = await PredictionSystem.deployed();
    predictionInst = await Prediction.deployed();
    interactionInst = await InteractionSystem.deployed();
    attendanceInst = await AttendanceSystem.deployed();
  });

  it("Test deployment", async () => {
    assert.ok(streamerInst.address);
    assert.ok(predSysInst.address);
    assert.ok(predictionInst.address);
    assert.ok(interactionInst.address);
    assert.ok(attendanceInst.address);
  });

  it("Test reward on marking attendance", async() => {

    streamerInst.setAttendanceContract(attendanceInst.address);
    streamerInst.setPredictionSystemContract(predSysInst.address);
    streamerInst.setInteractionSystemContract(interactionInst.address);

    tokenBeforeAttendance = await streamerInst.getViewerTokens(accounts[1]);
    
    // Start attendance for 30 minutes;
    await attendanceInst.startNewAttendance(30);
    await attendanceInst.markMyAttendance({from : accounts[1]})
    tokenAfterAttendance = await streamerInst.getViewerTokens(accounts[1]);

    assert.ok(tokenAfterAttendance.toNumber() > tokenBeforeAttendance.toNumber(), "Token count increased after attendance marking");        
  })

  it("Test make Donation", async() => {
    streamerInst.setAttendanceContract(attendanceInst.address);
    streamerInst.setPredictionSystemContract(predSysInst.address);
    streamerInst.setInteractionSystemContract(interactionInst.address);

    madeDonation = await interactionInst.makeDonation({from : accounts[3], value: 1000000000000000000});

    truffleAssert.eventEmitted(madeDonation, "DonorAdded")
  })

  it("Test subscribing", async() => {
    streamerInst.setAttendanceContract(attendanceInst.address);
    streamerInst.setPredictionSystemContract(predSysInst.address);
    streamerInst.setInteractionSystemContract(interactionInst.address);

    subscribed = await interactionInst.subscribe({from : accounts[3], value: 1000000000000000000});

    truffleAssert.eventEmitted(subscribed, "SubscriberAdded")
  })


  it("Test it as a whole", async() => {
    streamerInst.setAttendanceContract(attendanceInst.address);
    streamerInst.setPredictionSystemContract(predSysInst.address);
    streamerInst.setInteractionSystemContract(interactionInst.address);
    
    await attendanceInst.startNewAttendance(30);
    await predSysInst.createPrediction(3);

    await attendanceInst.markMyAttendance({from : accounts[1]})
    tokenAfterAttendance = await streamerInst.getViewerTokens(accounts[1]);

    // Make sure the token count increased
    assert.ok(tokenAfterAttendance.toNumber() > 0, "Token count increased after attendance marking");

    predictionAddr = await predSysInst.getCurrentPrediction();
    predInst = await Prediction.at(predictionAddr);
    // console.log(tokenAfterAttendance.toNumber())
    await predInst.betOnClosedOption(1, {from : accounts[1]});
    await predSysInst.unravelResults(1);
    tokenAfterPrediction = await streamerInst.getViewerTokens(accounts[1]);    
    
    assert.ok(tokenAfterPrediction.toNumber() > tokenAfterAttendance.toNumber(), "Token count increased afterPrediction");
    
    rqstInteraction = await interactionInst.requestInteraction(10, {from : accounts[1]});

    truffleAssert.eventEmitted(rqstInteraction, "InteractionRequested");
  })
});
