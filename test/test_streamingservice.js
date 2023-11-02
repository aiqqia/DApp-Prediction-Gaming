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

    streamerInst.setAttendanceSystemContract(attendanceInst.address);
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
    streamerInst.setAttendanceSystemContract(attendanceInst.address);
    streamerInst.setPredictionSystemContract(predSysInst.address);
    streamerInst.setInteractionSystemContract(interactionInst.address);

    madeDonation = await interactionInst.makeDonation({from : accounts[5], value: 1000000000000000000});

    truffleAssert.eventEmitted(madeDonation, "DonorAdded")

    checkIsDonor = await interactionInst.isDonor(accounts[5]);
    assert.ok(checkIsDonor, "Donor is added");
  })

  it("Test subscribing", async() => {
    streamerInst.setAttendanceSystemContract(attendanceInst.address);
    streamerInst.setPredictionSystemContract(predSysInst.address);
    streamerInst.setInteractionSystemContract(interactionInst.address);

    subscribed = await interactionInst.subscribe({from : accounts[5], value: 1000000000000000000});

    truffleAssert.eventEmitted(subscribed, "SubscriberAdded");

    checkIsSubscriber = await interactionInst.isDonor(accounts[5]);
    assert.ok(checkIsSubscriber, "Donor is added");
  })


  it("Test it as a whole", async() => {
    streamerInst.setAttendanceSystemContract(attendanceInst.address);
    streamerInst.setPredictionSystemContract(predSysInst.address);
    streamerInst.setInteractionSystemContract(interactionInst.address);
    
    await attendanceInst.startNewAttendance(30);
    await predSysInst.createPrediction("TestPrediction", 3);

    await attendanceInst.markMyAttendance({from : accounts[5]})
    tokenAfterAttendance = await streamerInst.getViewerTokens(accounts[5]);

    // Make sure the token count increased
    assert.ok(tokenAfterAttendance.toNumber() > 0, "Token count increased after attendance marking");

    predictionAddr = await predSysInst.getCurrentPrediction();
    predInst = await Prediction.at(predictionAddr);
    // console.log(tokenAfterAttendance.toNumber())
    await predInst.betOnClosedOption(1, {from : accounts[5]});
    await predSysInst.unravelResults(1);
    tokenAfterPrediction = await streamerInst.getViewerTokens(accounts[5]);    
    
    assert.ok(tokenAfterPrediction.toNumber() > tokenAfterAttendance.toNumber(), "Token count increased afterPrediction");
    await interactionInst.addNewInteraction(10, "give a shouout to ur name");
    rqstInteraction = await interactionInst.requestInteraction(0, {from : accounts[5]});

    truffleAssert.eventEmitted(rqstInteraction, "InteractionRequested");
  })
});
