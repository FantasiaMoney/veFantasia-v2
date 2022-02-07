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
  }

  beforeEach(async function() {
    await deployContracts()
  })

  describe('Vote', function() {
    it('user can not vote with 0 balance', async function() {
      await daoVote.vote(0,1).should.be.rejectedWith(EVMRevert)
    })

    it('user can vote with not 0 balance, and vote power should be same as balance', async function() {
      const toMint = 777
      await vToken.mint(userOne, toMint)
      await daoVote.vote(0,1)
      assert.equal(Number(await daoVote.topics(0,1)), toMint)
    })

    it('user can not vote twice', async function() {
      const toMint = 777
      await vToken.mint(userOne, toMint)
      await daoVote.vote(0,1)
      await daoVote.vote(0,1).should.be.rejectedWith(EVMRevert)
    })

    it('total results should be calculated correct', async function() {
      const userOneToMint = 500
      const userTwoToMint = 1500

      await vToken.mint(userOne, userOneToMint)
      await vToken.mint(userTwo, userTwoToMint)

      await daoVote.vote(0,1)
      await daoVote.vote(0,1, { from:userTwo })

      assert.equal(
        Number(await daoVote.topics(0,1)),
        Number(userOneToMint + userTwoToMint)
      )
    })
  })
  //END
})
