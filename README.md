# DApp for Streamer Predictions


## Testing

In order to locally run tests, make sure you have Ganache running on port 7545.

- Clone this repository
- Run: `npm install truffle-assertions`
- Run: `truffle compile && truffle migrate`
- Run: `truffle test`

**NOTE**: If tests were working fine, and then you ran them again and got any kind of error which doesn't make sense. Try to change the `acccounts[3]` to different index.

### Tool versions

- Truffle v5.1.64
- Node v21.1.0
- Ganache v2.7.1