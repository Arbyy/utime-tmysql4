-- Written by Team Ulysses, http://ulyssesmod.net/
module( "Utime", package.seeall )
if not SERVER then return end

require("tmysql4")

include("utime_mysql.lua")

local dbconn, err = tmysql.Connect(UTimeDB.Hostname, UTimeDB.Username, UTimeDB.Password, UTimeDB.DBName, UTimeDB.Port, nil, CLIENT_MULTI_STATEMENTS)

if err then error(err) end

utime_welcome = CreateConVar( "utime_welcome", "1", FCVAR_ARCHIVE )

dbconn:Query("CREATE TABLE IF NOT EXISTS utime (steamid BIGINT(20) NOT NULL PRIMARY KEY, totaltime INTEGER NOT NULL, lastvisit INTEGER NOT NULL)")

function onJoin( ply )
	local uid = ply:SteamID64()
	local row = dbconn:Query( "SELECT totaltime, lastvisit FROM utime WHERE steamid = " .. uid .. " LIMIT 1;", function(result)
		PrintTable(result)
		local time = 0
		if table.Count(result[1].data) > 0 then
			if utime_welcome:GetBool() then
				ULib.tsay( ply, "[UTime]Welcome back " .. ply:Nick() .. ", you last played on this server " .. os.date( "%c", result[1].data[1].lastvisit ) )
			end
			dbconn:Query("UPDATE utime SET lastvisit = "..os.time().." WHERE steamid="..uid..";")
			time = result[1].data[1].totaltime
		else
			if utime_welcome:GetBool() then
				ULib.tsay( ply, "[UTime]Welcome to our server " .. ply:Nick() .. "!" )
			end
			dbconn:Query("INSERT INTO utime (steamid, totaltime, lastvisit) VALUES ("..uid..", 0, "..os.time()..");")
		end
		ply:SetUTime(time)
		ply:SetUTimeStart(CurTime())
	end)
end
hook.Add( "PlayerInitialSpawn", "UTimeInitialSpawn", onJoin )

function updatePlayer( ply )
	dbconn:Query( "UPDATE utime SET totaltime = " .. math.floor( ply:GetUTimeTotalTime() ) .. " WHERE steamid = " .. ply:SteamID64() .. ";" )
end
hook.Add( "PlayerDisconnected", "UTimeDisconnect", updatePlayer )

function updateAll()
	local players = player.GetAll()

	for _, ply in ipairs( players ) do
		if ply and ply:IsConnected() then
			updatePlayer( ply )
		end
	end
end
timer.Create( "UTimeTimer", 67, 0, updateAll )
