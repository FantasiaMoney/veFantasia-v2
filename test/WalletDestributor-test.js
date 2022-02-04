import { BN, fromWei, toWei } from 'web3-utils'
import ether from './helpers/ether'
import EVMRevert from './helpers/EVMRevert'
import { duration } from './helpers/duration'

const BigNumber = BN
const timeMachine = require('ganache-time-traveler')

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()


// real contracts
const VTOKEN = artifacts.require('./VToken.sol')
const WalletDistributor = artifacts.require('./WalletDistributor.sol')
const periodTime = duration.days(31)

let vToken, walletDistributor


contract('WalletDestributor-test', function([userOne, userTwo, userThree]) {

  async function deployContracts(){
    // depoy vToken
    vToken = await VTOKEN.new("vDAO", "vDAO")
    walletDistributor = await WalletDistributor.new(vToken.address)

    await walletDistributor.sendTransaction({
      value: toWei(String(1)),
      from:userOne
    })
  }

  beforeEach(async function() {
    await deployContracts()
  })

  describe('Claim', function() {
    it('user can not claim without vtoken', async function() {
      await walletDistributor.claim().should.be.rejectedWith(EVMRevert)
    })

    it('user can claim with vtoken and wallet send all eth', async function() {
      await assert.equal(
        await web3.eth.getBalance(await walletDistributor.address),
        toWei("1")
      )

      await vToken.mint(userOne, toWei("1"))
      await walletDistributor.claim()

      await assert.equal(
        await web3.eth.getBalance(await walletDistributor.address),
        0
      )
    })

    it('user can not claim twice without wait', async function() {
      await vToken.mint(userOne, toWei("1"))
      await vToken.mint(userTwo, toWei("1"))
      await walletDistributor.claim()
      await walletDistributor.claim().should.be.rejectedWith(EVMRevert)
    })

    it('should be equal destribution according to user shares', async function() {
      await vToken.mint(userOne, toWei("0.2"))
      await vToken.mint(userTwo, toWei("0.3"))
      await vToken.mint(userThree, toWei("0.5"))

      await walletDistributor.claim()
      await assert.equal(
        await web3.eth.getBalance(await walletDistributor.address),
        toWei("0.8")
      )

      await walletDistributor.claim({ from:userTwo })
      await assert.equal(
        await web3.eth.getBalance(await walletDistributor.address),
        toWei("0.5")
      )

      await walletDistributor.claim({ from:userThree })
      await assert.equal(
        await web3.eth.getBalance(await walletDistributor.address),
        0
      )
    })

    it('Can be claimed for few periods', async function() {
      await vToken.mint(userOne, toWei("1"))
      await vToken.mint(userTwo, toWei("100"))

      for(let i = 0; i<10; i++){
        await timeMachine.advanceTimeAndBlock(periodTime + periodTime)
        await walletDistributor.claim()
      }
    })
  })
  //END
})
