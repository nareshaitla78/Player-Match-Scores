const express = require('express')
const path = require('path')
const {open} = require('sqlite')
const sqlite3 = require('sqlite3')

const app = express()
app.use(express.json())
const dbPath = path.join(__dirname, 'cricketMatchDetails.db')
let db = null
const initialzeDbAndServer = async () => {
  try {
    db = await open({
      filename: dbPath,
      driver: sqlite3.Database,
    })
    app.listen(3000, () => {
      console.log('Server is Running http://localhost:3000/')
    })
  } catch (e) {
    console.log(`error ${e.message}`)
    process.exit(1)
  }
}
initialzeDbAndServer()

const playerdetailsResponse = obdata => {
  return {
    playerId: obdata.player_id,
    playerName: obdata.player_name,
  }
}

const matchdetailsResponse = obdat => {
  return {
    matchId: obdat.match_id,
    match: obdat.match,
    year: obdat.year,
  }
}

//API 1
app.get('/players/', async (request, response) => {
  const getPlayerQuery = `
  SELECT
  player_id AS playerId,
  player_name AS playerName
  FROM
  player_details;`
  const playerARRAY = await db.all(getPlayerQuery)
  response.send(playerARRAY)
})

//API 2
app.get('/players/:playerId/', async (request, response) => {
  const {playerId} = request.params
  const playeridQuery = `
    SELECT 
    *
    FROM
    player_details
    WHERE player_id=${playerId};`
  const playeridArray = await db.get(playeridQuery)
  response.send(playerdetailsResponse(playeridArray))
})

//API 3
app.put('/players/:playerId/', async (request, response) => {
  const {playerId} = request.params
  const {playerName} = request.body
  const updatedquery = `
    UPDATE player_details
    SET player_name='${playerName}';`
  const dataRes = await db.run(updatedquery)
  const playerI = dataRes.lastId
  response.send('Player Details Updated')
})

//API 4
app.get('/matches/:matchId/', async (request, response) => {
  const {matchId} = request.params
  const matchQuery = `
    SELECT
    *
    FROM
    match_details
    WHERE match_id=${matchId};`
  const matchArray = await db.get(matchQuery)
  response.send(matchdetailsResponse(matchArray))
})

//API 5
app.get('/players/:playerId/matches', async (request, response) => {
  const {playerId} = request.params
  const queryofPlyer = `
  SELECT
  match_id AS matchId,
  match,
  year
  FROM
  player_match_score NATURAL JOIN match_details
  WHERE
  player_id=${playerId}`
  const daArray = await db.all(queryofPlyer)
  response.send(daArray)
})

//API 6
app.get('/matches/:matchId/players', async (request, response) => {
  const {matchId} = request.params

  const getMatchPlayersQuery = `
	    SELECT
	      player_details.player_id AS playerId,
	      player_details.player_name AS playerName
	    FROM player_match_score NATURAL JOIN player_details
        WHERE match_id=${matchId};`
  const macthPlayers = await db.all(getMatchPlayersQuery)
  response.send(macthPlayers)
})

//API 7
app.get('/players/:playerId/playerScores', async (request, response) => {
  const {playerId} = request.params
  const getPlayerScored = `
    SELECT
    player_details.player_id AS playerId,
    player_details.player_name AS playerName,
    SUM(player_match_score.score) AS totalScore,
    SUM(fours) AS totalFours,
    SUM(sixes) AS totalSixes FROM 
    player_details INNER JOIN player_match_score ON
    player_details.player_id = player_match_score.player_id
    WHERE player_details.player_id = ${playerId};`
  const playerScores = await db.get(getPlayerScored)
  response.send(playerScores)
})

module.exports = app
