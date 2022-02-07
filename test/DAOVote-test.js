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
const DAOVote = artifacts.require('./DAOVote.sol')

let vToken, daoVote


contract('WalletDestributor-test', function([userOne, userTwo, userThree]) {

  async function deployContracts(){
    // depoy vToken
    vToken = await VTOKEN.new("vDAO", "vDAO")
    daoVote = await DAOVote.new(vToken.address)

    await daoVote.create(true, 3, false, 0)
  }

  beforeEach(async function() {
    await deployContracts()
  })

  describe('Vote', function() {
    it('user can not vote with 0 balance', async function() {
      await daoVote.vote(1,1).should.be.rejectedWith(EVMRevert)
    })

    it('user can vote with not 0 balance, and vote power should be same as balance', async function() {
      const toMint = 777
      await vToken.mint(userOne, toMint)
      await daoVote.vote(1,1)
      assert.equal(Number(await daoVote.topicResults(1,1)), toMint)
    })

    it('user can not vote twice', async function() {
      const toMint = 777
      await vToken.mint(userOne, toMint)
      await daoVote.vote(1,1)
      await daoVote.vote(1,1).should.be.rejectedWith(EVMRevert)
    })

    it('user can not vote after deadline', async function() {
      const toMint = 777
      await vToken.mint(userOne, toMint)
      await daoVote.create(true, 3, true, duration.days(2))
      await timeMachine.advanceTimeAndBlock(duration.days(2))
      await daoVote.vote(2,1).should.be.rejectedWith(EVMRevert)
    })

    it('user can not vote for not existing candidate', async function() {
      const toMint = 777
      const topicData = await daoVote.topicsData(1)
      await vToken.mint(userOne, toMint)
      await daoVote.vote(1, Number(topicData[1]) + 1)
      .should.be.rejectedWith(EVMRevert)
    })

    it('total results should be calculated correct', async function() {
      const userOneToMint = 500
      const userTwoToMint = 1500

      await vToken.mint(userOne, userOneToMint)
      await vToken.mint(userTwo, userTwoToMint)

      await daoVote.vote(1,1)
      await daoVote.vote(1,1, { from:userTwo })

      assert.equal(
        Number(await daoVote.topicResults(1,1)),
        Number(userOneToMint + userTwoToMint)
      )
    })
  })

  describe('Unvote', function() {
    it('user can not unvote without vote', async function() {
      await daoVote.unvote(1,1).should.be.rejectedWith(EVMRevert)
    })

    it('user can not unvote if unvote disabled', async function() {
      const toMint = 777
      await vToken.mint(userOne, toMint)
      await daoVote.create(false, 3, false, duration.days(2))
      await daoVote.vote(2,1)
      await daoVote.unvote(2,1).should.be.rejectedWith(EVMRevert)
    })

    it('user can not unvote after deadline', async function() {
      const toMint = 777
      await vToken.mint(userOne, toMint)
      await daoVote.create(true, 3, true, duration.days(2))
      await daoVote.vote(2,1)
      await timeMachine.advanceTimeAndBlock(duration.days(2))
      await daoVote.unvote(2,1).should.be.rejectedWith(EVMRevert)
    })

    it('user can unvote and unvote reduce total votes', async function() {
      const toMint = 777
      await vToken.mint(userOne, toMint)
      await daoVote.vote(1,1)
      assert.equal(Number(await daoVote.topicResults(1,1)), toMint)

      await daoVote.unvote(1,1)
      assert.equal(Number(await daoVote.topicResults(1,1)), 0)
    })
  })
  //END
})
