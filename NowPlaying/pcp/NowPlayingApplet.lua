---- Dark Flat (Grid) Skin version (AF) ----
----   based on piCorePlayer 9.2.0 / Joggler Skin   ----

local _assert, pairs, ipairs, tostring, type, setmetatable, tonumber = _assert, pairs, ipairs, tostring, type, setmetatable, tonumber

local math             = require("math")
local table            = require("jive.utils.table")
local string	       = require("jive.utils.string")

local oo               = require("loop.simple")
local os			   = require("os")

local Applet           = require("jive.Applet")
local Font             = require("jive.ui.Font")
local Event            = require("jive.ui.Event")
local Framework        = require("jive.ui.Framework")
local System           = require("jive.System")
local Icon             = require("jive.ui.Icon")
local Button           = require("jive.ui.Button")
local Choice           = require("jive.ui.Choice")
local Label            = require("jive.ui.Label")
local Textarea         = require("jive.ui.Textarea")
local Group            = require("jive.ui.Group")
local Slider	       = require("jive.ui.Slider")
local Checkbox         = require("jive.ui.Checkbox")
local RadioButton      = require("jive.ui.RadioButton")
local RadioGroup       = require("jive.ui.RadioGroup")
local SimpleMenu       = require("jive.ui.SimpleMenu")
local Surface          = require("jive.ui.Surface")
local Window           = require("jive.ui.Window")
local Widget           = require("jive.ui.Widget")
local SnapshotWindow   = require("jive.ui.SnapshotWindow")
local Tile             = require("jive.ui.Tile")
local Timer            = require("jive.ui.Timer")
local Player           = require("jive.slim.Player")

local VUMeter          = require("jive.vis.VUMeter")
local SpectrumMeter    = require("jive.vis.SpectrumMeter")

local debug            = require("jive.utils.debug")
local datetime         = require("jive.utils.datetime")

local Keyboard         = require("jive.ui.Keyboard")
local Textinput        = require("jive.ui.Textinput")

local appletManager = appletManager

local jiveMain = jiveMain
local jnt = jnt

module(..., Framework.constants)
oo.class(_M, Applet)

local showProgressBar = true
local modeTokens = {
	off = "SCREENSAVER_OFF",
	play = "SCREENSAVER_NOWPLAYING",
	pause = "SCREENSAVER_PAUSED",
	stop = "SCREENSAVER_STOPPED"
}

local repeatModes = {
	mode0 = 'repeatOff',
	mode1 = 'repeatSong',
	mode2 = 'repeatPlaylist',
}

local shuffleModes = {
	mode0 = 'shuffleOff',
	mode1 = 'shuffleSong',
	mode2 = 'shuffleAlbum',
}

local SCROLL_TIMEOUT = 750

local RLenabled = 0
local APCenabled = 0

----------------------------------------------------------------------------------------
-- Helper Functions
--

-- defines a new style that inherits from an existing style
local function _uses(parent, value)
		local style = {}
		setmetatable(style, { __index = parent })

		for k,v in pairs(value or {}) do
			if type(v) == "table" and type(parent[k]) == "table" then
				-- recursively inherit from parent style
				style[k] = _uses(parent[k], v)
			else
				style[k] = v
			end
		end

		return style
end

local function _secondsToString(seconds)
	local hrs = math.floor(seconds / 3600)
	local min = math.floor((seconds / 60) - (hrs*60))
	local sec = math.floor( seconds - (hrs*3600) - (min*60) )

	if hrs > 0 then
		return string.format("%d:%02d:%02d", hrs, min, sec)
	else
		return string.format("%d:%02d", min, sec)
	end
end

local function _getIcon(self, item, icon, remote)
	local server = self.player:getSlimServer()

	local ARTWORK_SIZE = self:getSelectedStyleParam('artworkSize')

	local iconId
	if item then
		iconId = item["icon-id"] or item["icon"]
	end

	if iconId then
		log:debug(":_getIcon ",iconId,",", icon,",", ARTWORK_SIZE )
		-- Fetch an image from SlimServer
		server:fetchArtwork(iconId, icon, ARTWORK_SIZE)
	elseif item and item["params"] and item["params"]["track_id"] then
		-- this is for placeholder artwork, either for local tracks or radio streams with no art
		server:fetchArtwork(item["params"]["track_id"], icon, ARTWORK_SIZE, 'png')
	elseif icon then
		icon:setValue(nil)
	end
end

local function dump(thisTable)
	if type(thisTable) == 'table' then
		local s = '{ '
		for k,v in pairs(thisTable) do
			 if (type(k) ~= 'number' and k ~= "icon" and k ~= "text") then
			 	if k == "lyrics" then v = string.sub(tostring(v), 1, 15) end
			 	k = '"'..k..'"'
			 end
			 s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(thisTable)
	end
end

function _padString(number)
	if tonumber(number) < 10 then
		return "0" .. tostring(number)
	else
		return tostring(number)
	end
end

function _getTime(self)
	local time = os.date("*t")
	local hours = datetime:getHours() -- get time format
	local theMinute = _padString(time.min)
	local theHour = time.hour
	if hours and tostring(hours) == "12" then
		theHour = theHour % 12
		if theHour == 0 then
			theHour = 12
		end
	end
	theHour = _padString(theHour)
	local timeString = tostring(theHour..':'..theMinute)
	self.theclock:setValue(timeString)
end

function _getRLstatus(self)
	local server = self.player:getSlimServer()
	local cmd = {'can', 'ratingslight', 'setratingpercent', '?'}
	if server then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					RLenabled = tonumber(chunk.data["_can"])
					log:debug("RL enabled = "..dump(RLenabled))
				end
			end,
			self.player:getId(),
			cmd
		)
	end
end

function _getAPCstatus(self)
	local server = self.player:getSlimServer()
	local cmd = {'can', 'alternativeplaycount', 'skipwithoutcount', '?'}
	if server then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					APCenabled = tonumber(chunk.data["_can"])
					log:debug("APC enabled = "..tostring(APCenabled))
				end
			end,
			self.player:getId(),
			cmd
		)
	end
end

function _setRating(self, rating, incremental)
	if RLenabled > 0 then
		log:debug('RL is enabled. We can set ratings.')
		local server = self.player:getSlimServer()
		local playerStatus = self.player:getPlayerStatus()

		if playerStatus.item_loop[1] then
			log:debug("-----------playerStatus.item_loop[1]----------\n"..dump(playerStatus.item_loop[1]).."\n-----------\n\n")
		end

		local thisTrackID = playerStatus.item_loop[1].params.track_id
		log:debug('thisTrackID = '..dump(thisTrackID))

		if (not thisTrackID or tonumber(thisTrackID) < 0) then
			log:info('No valid LMS library track id for setting rating.')
		else
			local cmd = {'ratingslight', 'setratingpercent', thisTrackID, rating}
			if incremental then
				cmd = {'ratingslight', 'setratingpercent', thisTrackID, rating, 'incremental:'..incremental}
			end
			if server then
				server:userRequest(function(chunk,err)
						if err then
							log:warn(err)
						else
							if incremental then
								log:info("changing rating of track ID "..thisTrackID.." by "..rating)
							else
								log:info("setting rating of track ID "..thisTrackID.." to "..rating)
							end
						end
					end,
					self.player:getId(),
					cmd
				)
			end
		end
	else
		log:info('RL not enabled/installed. Cannot set ratings.')
	end
end

function _getXtraMetaData(self)
	local playerStatus = self.player:getPlayerStatus()
	local server = self.player:getSlimServer()
	local enabledSkinName = jiveMain:getSelectedSkin()

	if playerStatus.item_loop[1] then
		log:debug("-----------playerStatus.item_loop[1]----------\n"..dump(playerStatus.item_loop[1]).."\n-----------\n\n")
	end

	local thisTrackID = playerStatus.item_loop[1].params.track_id
	log:debug('thisTrackID = '..tostring(thisTrackID))

	if (server and (enabledSkinName == 'DarkFlatSkin' or enabledSkinName == 'DarkFlatGridSkin')) then
		if (not thisTrackID or tonumber(thisTrackID) < 0) then
			log:info('No valid LMS library track id. Use status query.')
			self.getServerData(self, server)
		else
			log:info('Has valid LMS library track id. Use songinfo query.')
			self.getServerData(self, server, thisTrackID)
		end
	end
end

function getServerData(self, server, thisTrackID)
	log:debug('entering getSonginfoData')
	local cmd, loopLossless, loopRating, loopComment, loopLyrics, loopBitrate, loopContentType, loopSampleRate, loopSampleSize, loopYear, loopURL, loopGenre, loopMultipleGenres, loopReplayGain

	if thisTrackID then
		cmd = {'songinfo', 0 , 100, 'track_id:'..thisTrackID, 'tags:IgGkoQrRTuyYw'}
	else
		cmd = {'status', '-' , 1, 'tags:IgGkoQrRTuyYw'}
	end

	server:userRequest(function(chunk,err)
			if err then
				log:warn(err)
			else
				if thisTrackID then
					local songinfoLoopData = chunk.data.songinfo_loop
					log:debug("----------- songinfo_loop ----------\n"..dump(chunk.data.songinfo_loop).."\n-----------\n\n")
					if (songinfoLoopData and type(songinfoLoopData) == 'table') then
						for k,v in pairs(songinfoLoopData) do
							if type(k) == 'number' then
								if songinfoLoopData[k].lossless then loopLossless = songinfoLoopData[k].lossless end
								if songinfoLoopData[k].rating then loopRating = songinfoLoopData[k].rating end
								if songinfoLoopData[k].comment then loopComment = songinfoLoopData[k].comment end
								if songinfoLoopData[k].lyrics then loopLyrics = songinfoLoopData[k].lyrics end
								if songinfoLoopData[k].type then loopContentType = songinfoLoopData[k].type end
								if songinfoLoopData[k].bitrate then loopBitrate = songinfoLoopData[k].bitrate end
								if songinfoLoopData[k].samplerate then loopSampleRate = songinfoLoopData[k].samplerate end
								if songinfoLoopData[k].samplesize then loopSampleSize = songinfoLoopData[k].samplesize end
								if songinfoLoopData[k].url then loopURL = songinfoLoopData[k].url end
								if songinfoLoopData[k].year then loopYear = songinfoLoopData[k].year end
								if songinfoLoopData[k].genre then loopGenre = songinfoLoopData[k].genre end
								if songinfoLoopData[k].genres then loopMultipleGenres = songinfoLoopData[k].genres end
								if songinfoLoopData[k].replay_gain then loopReplayGain = songinfoLoopData[k].replay_gain end
							end
						end
					end
				else
					log:debug("----------- playlist_loop[1]----------\n"..dump(chunk.data.playlist_loop[1]).."\n-----------\n\n")
					local statusLoopData = chunk.data.playlist_loop[1]
					if statusLoopData then
						loopLossless = statusLoopData.lossless
						loopRating = statusLoopData.rating
						loopComment = statusLoopData.comment
						loopLyrics = statusLoopData.lyrics
						loopContentType = statusLoopData.type
						loopBitrate = statusLoopData.bitrate
						loopSampleRate = statusLoopData.samplerate
						loopSampleSize = statusLoopData.samplesize
						loopURL = statusLoopData.url
						loopYear = statusLoopData.year
						loopGenre = statusLoopData.genre
						loopMultipleGenres = statusLoopData.genres
						loopReplayGain = statusLoopData.replay_gain
					end
				end
				self.setStyles(self, loopLossless, loopRating, loopComment, loopLyrics, loopBitrate, loopContentType, loopSampleRate, loopSampleSize, loopURL, loopYear, loopGenre, loopMultipleGenres, loopReplayGain)
			end
		end,
		self.player:getId(),
		cmd
	)
end

function setStyles(self, loopLossless, loopRating, loopComment, loopLyrics, loopBitrate, loopContentType, loopSampleRate, loopSampleSize, loopURL, loopYear, loopGenre, loopMultipleGenres, loopReplayGain)
	log:debug('entering setStyles')

	local settings = self:getSettings()
	local coloredTrackTitleKeyword = settings["coloredTrackTitleKeyword"]
	local playerStatus = self.player:getPlayerStatus()

	local rating,isremote,haslyrics,hascsst,islossless,hasvalidtrackid = 0,0,0,0,0,0
	local bitrate,contentType,sampleRate,sampleSize,streamingService,trackYear, genres, replayGain

	local contentTypeTable = { ['mp3'] = 'MP3', ['mp2'] = 'MP3', ['flc'] = 'FLAC', ['alc'] = 'ALAC', ['alcx'] = 'ALAC', ['aac'] = 'AAC', ['mp4'] = 'AAC', ['sls'] = 'AAC', ['ogg'] = 'Ogg', ['ogf'] = 'OggFLAC', ['ops'] = 'OggOpus', ['wav'] = 'Wav', ['wvp'] = 'Wav', ['wvpx'] = 'Wav', ['aif'] = 'AIFF', ['wma'] = 'WMA', ['wmap'] = 'WMA', ['wmal'] = 'WMA', ['mpc'] = 'Muse', ['ape'] = 'APE', ['dff'] = 'DFF', ['dsf'] = 'DSF' }
	local contentTypeHQTable = { ['flc'] = true, ['flac'] = true, ['alc'] = true, ['alcx'] = true, ['alac'] = true, ['ogf'] = true, ['oggflac'] = true, ['wav'] = true, ['wvp'] = true, ['wvpx'] = true, ['wavpack'] = true, ['aif'] = true, ['aiff'] = true, ['wmal'] = true, ['ape'] = true, ['dff'] = true, ['dsf'] = true }

	-- remote + valid track id?
	if (playerStatus.remote and playerStatus.remote == 1) then isremote = 1 end

	local thisTrackID = playerStatus.item_loop[1].params.track_id
	log:debug('thisTrackID = '..tostring(thisTrackID))
	if (thisTrackID and tonumber(thisTrackID) > 0) then
		hasvalidtrackid = 1
	end
	log:debug('hasvalidtrackid = '..tostring(hasvalidtrackid))

	---- process server data ----
	if loopLossless then
		islossless = tonumber(loopLossless)
		log:debug("lossless (Q) = "..islossless)
	end

	if loopRating then
		local currentRatingInfo = loopRating
		rating = tonumber(currentRatingInfo)
		log:debug("rating (R) = "..rating)
		rating = math.floor((rating + 5)/10) * 10
	end

	if (loopComment and loopComment ~= "") then
		local currentCommentInfo = tostring(loopComment)
		log:debug("comment (k) = "..currentCommentInfo)

		-- colored track title
		if (coloredTrackTitleKeyword ~= nil and coloredTrackTitleKeyword ~= "" and currentCommentInfo:find(coloredTrackTitleKeyword)) then
			self.trackTitle:setStyle("nptrack_colored")
		end

		-- custom start/stop time
		if (currentCommentInfo:find('STARTTIME:') or currentCommentInfo:find('STOPTIME:')) then
			log:debug('Track has custom start/stop time.')
			hascsst = 1
		end
	end

	if (loopLyrics and loopLyrics ~= "") then
		local currentLyrics = tostring(loopLyrics)
		log:debug("has lyrics (w)")
		self.mylyrics:setValue(currentLyrics)
		haslyrics = 1
	end

	if (loopBitrate and loopBitrate ~= "") then
		local rawbitrate = tostring(loopBitrate)
		bitrate = string.match(rawbitrate,'(%d+)[kbps|kb%/s|k].*')
		log:debug("matched bitrate = "..tostring(bitrate))
		if bitrate then bitrate = bitrate ..'kBit/s' end
		if (not bitrate or bitrate == "") then bitrate = rawbitrate end
		log:debug("bitrate (r) = "..bitrate)
	end

	if (loopContentType and loopContentType ~= "") then
		local rawContentType = tostring(loopContentType)
		if contentTypeTable[rawContentType] then
			contentType = tostring(contentTypeTable[rawContentType])
		else
			contentType = rawContentType
		end
		log:debug("contentType (o) = "..tostring(contentType))
	end

	if (loopSampleRate and tonumber(loopSampleRate) > 0) then
		sampleRate = tonumber(loopSampleRate)/1000
		thisInteger, thisDecimal = math.modf(sampleRate)
		if thisDecimal == 0 then
			sampleRate = thisInteger
		end
		sampleRate = tostring(sampleRate).."kHz"
		log:debug("sampleRate (T) = "..sampleRate)
	end

	if (loopSampleSize and tonumber(loopSampleSize) > 0) then
		sampleSize = tostring(tonumber(loopSampleSize).."bit")
		log:debug("samplesize (I) = "..sampleSize)
	end

	if loopURL then
		local thisURL = tostring(loopURL)
		if (thisURL:find("spotify:") or thisURL:find("spotify.com")) then
			streamingService = "spotify"
		elseif (thisURL:find("deezer:") or thisURL:find("deezer.com")) then
			streamingService = "deezer"
		elseif (thisURL:find("wimp:") or thisURL:find("tidal.com")) then
			streamingService = "tidal"
		elseif (thisURL:find("qobuz:") or thisURL:find("qobuz.com")) then
			streamingService = "qobuz"
		end
		log:debug("url (u) = "..thisURL)
		log:debug("streamingService = "..tostring(streamingService))
	end

	if (loopYear and tonumber(loopYear) > 0) then
		trackYear = loopYear
		log:debug("loopYear = "..tostring(loopYear))
	end

	local genreString = self:string('NOW_PLAYING_NO_GENRE')
	if (loopMultipleGenres and loopMultipleGenres ~= '') then
		genreString = tostring(loopMultipleGenres)
		log:debug('genreString (multi) = '..genreString)
	elseif (loopGenre and loopGenre ~= '') then
		genreString = tostring(genreString)
		log:debug('genreString (single) = '..genreString)
	end

	if loopReplayGain then
		replayGain = tostring(tonumber(loopReplayGain).."dB")
		log:debug("replay gain (Y) = "..loopReplayGain)
	end

	---- setting styles ----
	if (isremote == 1 and hasvalidtrackid ~= 1) then
		log:debug('Non-library remote track: not displaying ratings')
		self.myrating:setStyle('')
	else
		log:debug('settings displayRating = '..dump(settings["displayRating"]))
		if settings["displayRating"] then
			log:debug("rating = "..tonumber(rating))
			self.myrating:setStyle('ratingLevel'..rating)
		end
	end

	log:debug('settings displayGenre = '..dump(settings["displayGenre"]))
	if settings["displayGenre"] then
		self.mytrackgenre:setValue(genreString)
	end

	log:debug('settings displayStatusIcons = '..dump(settings["displayStatusIcons"]))
	if settings["displayStatusIcons"] then
		if haslyrics >= 0 then
			log:debug("haslyrics = "..tonumber(haslyrics))
			self.statuslyrics:setStyle('haslyrics_'..haslyrics)
		end
		if hascsst >= 0 then
			log:debug("hascsst = "..tonumber(hascsst))
			self.statuscsst:setStyle('hascsst_'..hascsst)
		end
		if islossless >= 0 then
			if (islossless == 0 and contentType and contentTypeHQTable[string.lower(contentType)]) then islossless = 1 end
			log:debug("islossless = "..tonumber(islossless))
			self.statuslossless:setStyle('islossless_'..islossless)
		end
		if isremote >= 0 then
			log:debug("isremote = "..tonumber(isremote))
			if (isremote == 1 and streamingService) then
				self.statusremote:setStyle('is'..streamingService)
			else
				self.statusremote:setStyle('isremote_'..isremote)
			end
		end
	end

	log:debug('settings displayAudioMetaData = '..dump(settings["displayAudioMetaData"]))
	local audioMetaData = ''
	if (settings["displayYear"] and trackYear) then
		audioMetaData = tostring(trackYear)
		if (settings["displayAudioMetaData"] and contentType) then
			audioMetaData = audioMetaData .. " • "
		end
	end
	if (settings["displayAudioMetaData"] and contentType) then
		audioMetaData = audioMetaData .. tostring(contentType)
		if bitrate then
			audioMetaData = audioMetaData .. " • " .. bitrate
		end
		if sampleRate then
			audioMetaData = audioMetaData .. " • " .. sampleRate
		end
		if sampleSize then
			audioMetaData = audioMetaData .. " • " .. sampleSize
		end
		if (self.selectedStyle == 'nowplaying' or self.selectedStyle == 'nowplaying_text_only') and replayGain then
			audioMetaData = audioMetaData .. " • " .. replayGain
		end
	end
	log:debug("audioMetaData = " ..audioMetaData)
	if ((settings["displayYear"] and trackYear) or (settings["displayAudioMetaData"] and contentType)) then
		self.mytrackaudiometa:setValue(audioMetaData)
	end
	if (self:getSettings()["displayClock"] or self:getSettings()["displayClock"]) then
		self._getTime(self)
	end
end

function _fwdNoSkipCount(self)
	if APCenabled > 0 then
		log:debug('APC is enabled. We can use this.')
		local server = self.player:getSlimServer()
		local playerStatus = self.player:getPlayerStatus()

		if playerStatus.item_loop[1] then
			log:debug("-----------playerStatus.item_loop[1]----------\n"..dump(playerStatus.item_loop[1]).."\n-----------\n\n")
		end

		local thisTrackID = playerStatus.item_loop[1].params.track_id
		log:debug('thisTrackID = '..dump(thisTrackID))

		if (not thisTrackID or tonumber(thisTrackID) < 0) then
			log:info('No valid LMS library track id for command.')
		else
			local cmd = {'alternativeplaycount', 'skipwithoutcount', thisTrackID}
			if server then
				server:userRequest(function(chunk,err)
						if err then
							log:warn(err)
						else
							log:info("Skipping track with ID "..tostring(thisTrackID).." without increasing its skip count")
						end
					end,
					self.player:getId(),
					cmd
				)
			end
		end
	else
		log:info('APC not enabled/installed. Cannot use this function.')
	end
end

function init(self)
	jnt:subscribe(self)

	self.player = false
	self.lastVolumeSliderAdjustT = 0
	self.cumulativeScrollTicks = 0

	local settings = self:getSettings()
	local defaults = self:getDefaultSettings()
	self.scrollText = settings["scrollText"]
	self.scrollTextOnce = settings["scrollTextOnce"]

	if not settings["analogVUmeter"] then self:_setVUmeter() end

	local settingschanged = 0
	for _,v in ipairs(settings) do
		if settings[v] == nil and defaults[v] then
			settings[v] = defaults[v]
			settingschanged = 1
		end
	end
	if settingschanged > 0 then self:storeSettings() end
end

-- style names are grabbed from the skin
-- this list is compared against the settings.views table (if any), and certain views are disabled as specified
-- further, if the player is not local and the view is local only, don't allow that in the returned table
function getNPStyles(self)
	local npSkinStyles = jiveMain:getSkinParam("nowPlayingScreenStyles")

	-- visualizers are only available for connected local players, so only include them in that case
	local auditedNPStyles = {}
	if not self.player then
		-- don't give any options if not connected to a player

	else
		local settings = self:getSettings()
		local playerId = self.player:getId()

		-- restore selected style from settings
		if not self.selectedStyle and settings.selectedStyle then
			self.selectedStyle = settings.selectedStyle or 'nowplaying'
		end

		for i, v in pairs(npSkinStyles) do
			if settings and settings.views and settings.views[v.style] == false then
				v.enabled = false
			else
				v.enabled = true
			end
			if not self.player:isLocal() and v.localPlayerOnly then
				log:debug('the style ', v.style , ' is not for non-local players. Removing...')
				-- if we purge this style, by definition it cannot be selected
				if v.style == self.selectedStyle then
					self.selectedStyle = nil
				end
			else
				log:debug('style ', v.style, ' okay for this player')
				table.insert(auditedNPStyles, v)
				if not self.selectedStyle and v.enabled then
					self.selectedStyle = v.style
				elseif self.selectedStyle == v.style and not v.enabled then
					self.selectedStyle = false
				end
			end
		end

		-- verify whether the selected style is available at all
		if self.selectedStyle then
			local selectedStyleAvailable = false

			for i, v in pairs (auditedNPStyles) do
				if (v.enabled and v.style == self.selectedStyle) then
					selectedStyleAvailable = true
					break
				end
			end

			if not selectedStyleAvailable then
				self.selectedStyle = false
			end
		end

		-- corner case: auditedNPStyles is an empty set or nothing in it is enabled.
		-- That may happen if the only configured styles are visualizers and this player is non local
		-- or it may happen if the skin has changed and the list of styles is non-overlapping to the configured settings from the old skin
		-- In this case, go through again and enable everything possible
		local oneEnabledStyle = false
		for i, v in pairs(auditedNPStyles) do
			if v.enabled then
				oneEnabledStyle = true
				break
			end
		end
		if not oneEnabledStyle then
			log:warn('No enabled view styles found, enabling all possible styles ')
			auditedNPStyles = {}
			for i, v in pairs(npSkinStyles) do
				v.enabled = true
				if not self.player:isLocal() and v.localPlayerOnly then
					-- never enable localPlayerOnly styles for non local players (e.g., visualizers)
					log:debug('np view ', v.style, ' left out of available views because this player is not local')
				else
					table.insert(auditedNPStyles, v)
				end
			end
		end

		-- use the first style if nothing is already selected
		if not self.selectedStyle then
			self.selectedStyle = auditedNPStyles[1] and auditedNPStyles[1].style
		end

		-- only update settings if they have changed
		if settings.selectedStyle ~= self.selectedStyle then
			settings.selectedStyle = self.selectedStyle
			self:storeSettings()
		end
	end

	if self.window and self.window:getStyle() then
		if self.window:getStyle() ~= self.selectedStyle then
			-- remove self.window if the style of the window does not match with self.selectedStyle
			self.window = nil
		end
	end

	if log:isDebug() then
		debug.dump(auditedNPStyles)
	end

	return auditedNPStyles
end

function coloredTrackTitleCommentsKeywordSettingsShow(self)
	local window = Window("text_list", self:string('NOW_PLAYING_COLOREDTRACKTITLE_KEYWORD') )

	local settings = self:getSettings()
	local coloredTrackTitleKeyword = settings["coloredTrackTitleKeyword"]
	log:debug('coloredTrackTitleKeyword = ', tostring(settings["coloredTrackTitleKeyword"]))
	if not coloredTrackTitleKeyword then coloredTrackTitleKeyword = "" end

	local input = Textinput("textinput", coloredTrackTitleKeyword,
				function(_, value)
					value = string.gsub(value, "[^%w_\*\!\.,=]", "")
					if value and tonumber(string.len(tostring(value))) > 20 then
						value = string.sub(value,1,20)
					end
					settings["coloredTrackTitleKeyword"] = value
					self:storeSettings()

					window:playSound("WINDOWSHOW")
					window:hide(Window.transitionPushRight)
					return true
				end
	)

	local keyboard = Keyboard("keyboard", "qwerty", input)
	local backspace = Keyboard.backspace()
	local group = Group('keyboard_textinput', { textinput = input, backspace = backspace } )
	local help = Textarea("help_text", self:string('NOW_PLAYING_COLOREDTRACKTITLE_KEYWORD_HELP'))

	window:addWidget(help)
	window:addWidget(group)
	window:addWidget(keyboard)
	window:focusWidget(group)

	self:tieAndShowWindow(window)
	return window
end

function displayMoreTrackInfoSettingsShow(self)
	local window = Window("text_list", self:string('NOW_PLAYING_DISPLAY_MORE_TRACKINFO') )
	local menu = SimpleMenu("menu")
	local settings = self:getSettings()
	local npMoreTrackInfoItems = {"displayAudioMetaData", "displayStatusIcons", "displayRating", "displayYear", "displayGenre", "displayClock"}

	for _,v in ipairs(npMoreTrackInfoItems) do
		menu:addItem( {
			text = self:string("NOW_PLAYING_TRACKINFO_" .. string.upper(v)),
			style = 'item_choice',
			check = Checkbox("checkbox",
				function(object, isSelected)
					log:debug(tostring(v)..' = '..tostring(isSelected))
					settings[v] = isSelected
					self:storeSettings()
					jiveMain:reloadSkin()
				end,
			settings[v]),
		} )
	end

	window:addWidget(menu)
	window:show()
end

function NPscreenRatingSettingsShow(self)
	local window = Window("text_list", self:string('NOW_PLAYING_NPSCREEN_RATING') )
	local menu = SimpleMenu("menu")
	local settings = self:getSettings()

	menu:addItem( {
		text = self:string("NOW_PLAYING_NPSCREEN_RATING"),
		style = 'item_choice',
		check = Checkbox("checkbox",
				function(object, isSelected)
					log:debug('NPscreenRating = '..tostring(isSelected))
					settings['NPscreenRating'] = isSelected
					self:storeSettings()
					jiveMain:reloadSkin()
				end,
		settings['NPscreenRating']),
	})

	window:addWidget(menu)
	window:show()
end

function _setVUmeter(self, vumeter)
	log:debug('setVUmeter: vumeter received = '..tostring(vumeter))
	if not vumeter then
		log:debug('setVUmeter: falling back to default VU meter (Blue Glow)')
		vumeter = 'Blue_Glow'
	end
	local settings = self:getSettings()
	local darkFlatSkinPath = string.match(System:findFile("applets/DarkFlatSkin/DarkFlatSkinApplet.lua"), "(.*)DarkFlatSkinApplet.lua")
	local vuimagefolder = darkFlatSkinPath..'images/UNOFFICIAL/VUMeter/'
	log:debug('setVUmeter: vuimagefolder = '..tostring(vuimagefolder))

	-- store in settings
	log:debug('setVUmeter: selected VU meter = '..tostring(vumeter))
	settings["analogVUmeter"] = vumeter
	self:storeSettings()

	-- create symlink
	log:debug('setVUmeter: creating symlink')
	os.execute('/bin/ln -sf '..vuimagefolder..'vu_analog_25seq-'..tostring(vumeter)..'.png '..vuimagefolder..'vu_analog_25seq_w.png')
	log:debug('setVUmeter: symlink created')
end

function npVUMeterSelectionShow(self)
	log:debug('entering npVUMeterSelectionShow')
	local window = Window("text_list", self:string('NOW_PLAYING_SELECT_VUMETER') )
	local group = RadioGroup()
	local menu = SimpleMenu("menu")
	local settings = self:getSettings()
	local current = settings["analogVUmeter"]
	log:debug('npVUMeterSelectionShow: current VU meter setting = '..tostring(current))

	local npAnalogVUmeters = {'Blue_Glow', 'Jstraw_Dark', 'Jstraw_Dark_Peak', 'Jstraw_Vintage', 'Kolossos_Oval', 'Colored_Circles', 'Tube', 'Orange'}

	for _,vumeter in ipairs(npAnalogVUmeters) do
		menu:addItem( {
			text = string.gsub(vumeter, "_", " "),
			style = 'item_choice',
			check = RadioButton("radio", group, function()
					log:debug('npVUMeterSelectionShow: selected vumeter = '..tostring(vumeter))
					self:_setVUmeter(vumeter)
				end,
			current == vumeter),
		})
	end
	local help = Textarea("help_text", self:string('NOW_PLAYING_SELECT_VUMETER_HELP'))

	window:addWidget(help)
	window:addWidget(menu)
	self:tieAndShowWindow(window)
	return window
end

function npviewsSettingsShow(self)
	local window = Window("text_list", self:string('NOW_PLAYING_VIEWS') )
	local group = RadioGroup()

	local menu = SimpleMenu("menu")

	-- go through each NP screen view and add an item for each
	local npscreenViews = self:getNPStyles()

	-- if settings[playerId] isn't present, go ahead and create and save the settings for this player
	-- this gets around dealing with logical insanity with initial conditions and the checkbox menu callbacks
	local settings = self:getSettings()
	local playerId = self.player:getId()
	local savedSettings = true

	if not settings.views then
		settings.views = {}
	end

	local settingsViews = 0
	for k, v in pairs(settings.views) do
		settingsViews = settingsViews + 1
	end
	if settingsViews == 0 then
		for i, v in ipairs(npscreenViews) do
			settings.views[v.style] = true
			npscreenViews[i].enabled = true
		end
		self:storeSettings()
	end

	-- if we've switched to a local player and there are localPlayerOnly styles, they may not be saved in settings.views
	-- add them here
	for i, v in pairs(npscreenViews) do
		if settings.views[v.style] or settings.views[v.style] == false then
			-- style is stored in table, even if value is false
		else
			log:warn('add v.style')
			settings.views[v.style] = true
		end
	end

	for i, v in ipairs(npscreenViews) do
		local selected = true
		if v.enabled == false then
			selected = false
		end

		menu:addItem( {
			text = v.text,
			style = 'item_choice',
			check = Checkbox("checkbox",
				function(object, isSelected)
					local settings = self:getSettings()
					local playerId = self.player:getId()

					if isSelected then
						-- turn it on
						settings.views[v.style] = true
					else
						-- turn it off
						-- there needs to be at least one style turned on
						local enabledViews = 0
						for k, v in pairs(settings.views) do
							if v then
								enabledViews = enabledViews + 1
							end
						end
						if enabledViews > 1 or not savedSettings then
							-- if we're turning off the selected style,
							-- dump self.window as well so it gets redrawn
							if self.selectedStyle == v.style then
								self.selectedStyle = nil
								self.window = nil
							end
							settings.views[v.style] = false
						else
							log:warn('A minimum of one selected NP view per player is required')
							-- we need at least one enabled Now Playing view. Don't allow this.
							Framework:playSound("BUMP")
							window:bumpLeft()
							object:setSelected(true)
						end
					end
					self:storeSettings()
				end,
			selected),
		} )
	end

	--XXX: not sure whether the text is necessary or even helpful here
	--menu:setHeaderWidget(Textarea("help_text", self:string("NOW_PLAYING_VIEWS_HELP")))

	window:addWidget(menu)
	window:show()
end

function scrollSettingsShow(self)
	local window = Window("text_list", self:string('SCREENSAVER_SCROLLMODE') )
	local group = RadioGroup()

	local menu = SimpleMenu("menu", {
		{
			text = self:string("SCREENSAVER_SCROLLMODE_DEFAULT"),
			style = 'item_choice',
			check = RadioButton("radio",
				group,
				function(event)
					self:setScrollBehavior("always")
				end,
				self.scrollText and not self.scrollTextOnce
			)
		},
		{
			text = self:string("SCREENSAVER_SCROLLMODE_SCROLLONCE"),
			style = 'item_choice',
			check = RadioButton("radio",
				group,
				function(event)
					self:setScrollBehavior("once")
				end,
				self.scrollText and self.scrollTextOnce
			)
		},
		{
			text = self:string("SCREENSAVER_SCROLLMODE_NOSCROLL"),
			style = 'item_choice',
			check = RadioButton("radio",
				group,
				function(event)
					self:setScrollBehavior("never")
				end,
				not self.scrollText
			)
		},
	})

	window:addWidget(menu)
	window:show()
end

function setScrollBehavior(self, setting)
	if setting == 'once' then
		self.scrollText = true
		self.scrollTextOnce = true
		self:_addScrollSwitchTimer()
	elseif setting == 'never' then
		self.scrollText = false
		self.scrollTextOnce = false
		self.scrollSwitchTimer = nil
	else
		self.scrollText = true
		self.scrollTextOnce = false
		self:_addScrollSwitchTimer()
	end

	local settings = self:getSettings()

	settings["scrollText"] = self.scrollText
	settings["scrollTextOnce"] = self.scrollTextOnce
	self:storeSettings()
end

function notify_playerShuffleModeChange(self, player, shuffleMode)
	if player ~= self.player then
		return
	end
	log:debug("notify_playerShuffleModeChange(): ", shuffleMode)
	self:_updateShuffle(shuffleMode)
end

function notify_playerDigitalVolumeControl(self, player, digitalVolumeControl)
	if player ~= self.player then
		return
	end
	log:info('notify_playerDigitalVolumeControl: ', digitalVolumeControl)
	self:_setVolumeSliderStyle()
end

function notify_playerRepeatModeChange(self, player, repeatMode)
	if player ~= self.player then
		return
	end
	log:debug("notify_playerRepeatModeChange(): ", repeatMode)
	self:_updateRepeat(repeatMode)
end

function _setVolumeSliderStyle(self)
	if self.volSlider then
		if self.player:getDigitalVolumeControl() == 0 then
			log:info('disable volume UI in NP')
			self.volSlider:setStyle('npvolumeB_disabled')
			self.volSlider:setEnabled(false)
			self.volSlider:setValue(100)
			self.fixedVolumeSet = true
		else
			log:info('enable volume UI in NP')
			self.volSlider:setStyle('npvolumeB')
			self.volSlider:setEnabled(true)
			self.fixedVolumeSet = false
		end
	end
end

function _setTitleStatus(self, text, duration)
	log:debug("_setTitleStatus", text)

	self.trackTitle:setStyle("nptrack")
	self.myrating:setStyle("")
	self.mytrackaudiometa:setStyle("npaudiometa")
	self.theclock:setStyle("npclock")
	self.mytrackgenre:setStyle("npgenre")
	self.statusremote:setStyle("")
	self.statuscsst:setStyle("")
	self.statuslyrics:setStyle("")
	self.statuslossless:setStyle("")
	self.mylyrics:setStyle("nplyrics")
	self._getXtraMetaData(self)

	local nowPlayingTrackInfoLines = jiveMain:getSkinParam("NOWPLAYING_TRACKINFO_LINES")
	local msgs = string.split("\n", text)
	if nowPlayingTrackInfoLines == 2 and self.artistalbumTitle then
		if #msgs > 1 then
			-- artistalbumTitle and trackTitle widgets are used as messaging widget
			-- two line message means use artistAlbumTitle for line 1, trackTitle for line 2
			-- Bug 17937: leave the title alone if a zero-length title is provided
			self.artistalbumTitle:setValue(msgs[1], duration)
			if string.len(msgs[2]) > 0 then self.trackTitle:setValue(msgs[2], duration) end
		else
			-- one line message means use trackTitle for line 1 and keep what is already on screen for artistalbumTitle
			-- keeping existing artistalbumTitle text is important for multiple-showBriefly cases e.g., rebuffering messages
			-- awy: This may no longer be true.
			self.trackTitle:setValue(msgs[1], duration)
			self.artistalbumTitle:setValue(self.artistalbumTitle:getValue(), duration) --keep any temporary text up for same duration to avoid flickering
		end
	elseif nowPlayingTrackInfoLines == 3 and self.titleGroup then --might not exist yet if NP window hasn't yet been created
		-- use title widget and track title as lines 1 and 2 of messaging
		-- remove albumTitle and artistTitle until temp message is done
		if #msgs == 1 then
			log:debug('one line message')
			self.titleGroup:setWidgetValue("text", msgs[1], duration)
			self.trackTitle:setValue(self.trackTitle:getValue(), duration)
			self.albumTitle:setValue('', duration)
			self.artistTitle:setValue('', duration)

		elseif #msgs == 2 then
			log:debug('two line message')
			self.titleGroup:setWidgetValue("text", msgs[1], duration)
			self.trackTitle:setValue(msgs[2], duration)
			self.artistTitle:setValue('', duration)
			self.albumTitle:setValue('', duration)

		end
	end
end

function notify_playerTitleStatus(self, player, text, duration)
	if player ~= self.player then
		return
	end
	log:debug("notify_playerTitleStatus(): ", text)
	self:_setTitleStatus(text, duration)
end

function notify_playerPower(self, player, power)
	if player ~= self.player then
		return
	end
	log:debug("notify_playerPower(): ", power)

	local mode = self.player:getPlayMode()

	-- hide this window if the player is turned off
	if not power then
		if self.titleGroup then
			self:changeTitleText(self:_titleText('off'))
		end
	else
		if self.titleGroup then
			local titleText = self:_titleText(mode)
			self:changeTitleText(titleText)
		end
	end
end

function changeTitleText(self, titleText)
	self.titleGroup:setWidgetValue("text", titleText)
end

function notify_playerTrackChange(self, player, nowPlaying)
	if player ~= self.player then
		return
	end
	log:debug("notify_playerTrackChange(): ", nowPlaying)

	local thisPlayer = _isThisPlayer(self, player)
	if not thisPlayer then return end

	self.player = player
	local playerStatus = player:getPlayerStatus()

	if player:getPlaylistSize() == 0 and Window:getTopNonTransientWindow() == self.window then
		--switch to "empty playlist", if currently on NP when all tracks removed
		appletManager:callService("showPlaylist")
		return
	end

	if not self.window then
		--no np window yet exists so don't need to create the window yet until user goes to np.
		return
	end

	self._getXtraMetaData(self)

	if not self.snapshot then
		self.snapshot = SnapshotWindow()
	else
		self.snapshot:refresh()
	end
	--temporarily swap in snapshot window of previous track window to allow for fade transition in to new track
	self.snapshot:replace(self.window)
	self.window:replace(self.snapshot, _nowPlayingTrackTransition)

	if playerStatus and playerStatus.item_loop
		and self.nowPlaying ~= nowPlaying
	then
		-- for remote streams, nowPlaying = text
		-- for local music, nowPlaying = track_id
		self.nowPlaying = nowPlaying
	end

	self:replaceNPWindow()
end

function notify_playerPlaylistChange(self, player)
	if player ~= self.player then
		return
	end
	log:debug("notify_playerPlaylistChange()")
	self:_updateAll()
end

function _nowPlayingTrackTransition(oldWindow, newWindow)
	_assert(oo.instanceof(oldWindow, Widget))
	_assert(oo.instanceof(newWindow, Widget))

	--single frame fade
	local frames = 2
	local scale = 255/frames
	local animationCount = 0

	local sw, sh = Framework:getScreenSize()
	local srf = Surface:newRGB(sw, sh)

	oldWindow:draw(srf, LAYER_ALL)

	return function(widget, surface)
		local x = tonumber(math.floor(((frames - 1 ) * scale) + .5))

		newWindow:draw(surface, LAYER_ALL)
		srf:blitAlpha(surface, 0, 0, x)

		frames = frames - 1
		if frames == 0 then
			Framework:_killTransition()
		end
	end
end

function notify_playerModeChange(self, player, mode)

	if not self.player then
		return
	end

	log:debug("notify_playerModeChange(): Player mode has been changed to: ", mode)
	self:_updateMode(mode)
end

-- players gone, close now playing
function notify_playerDelete(self, player)
	if player ~= self.player then
		return
	end
	log:debug("notify_playerDelete():", player)

	self:freeAndClear()
end

-- players changed, add playing menu
function notify_playerCurrent(self, player)

	if self.player ~= player then
		self:freeAndClear()
	end
	log:debug("notify_playerCurrent(): ", player)

	self.player = player
	self:_setVolumeSliderStyle()

	if not self.player then
		return
	end

	if jiveMain:getSkinParam("NOWPLAYING_MENU") then
		self:addNowPlayingItem()
	else
		self:removeNowPlayingItem()
	end
end

function getSelectedStyleParam(self, param)
	for i, v in pairs(self.nowPlayingScreenStyles) do
		if v.style == self.selectedStyle then
			return v[param]
		end
	end
end

function removeNowPlayingItem(self)
	jiveMain:removeItemById('appletNowPlaying')
	self.nowPlayingItem = false
end

function addNowPlayingItem(self)
	jiveMain:addItem({
		id = 'appletNowPlaying',
		iconStyle = 'hm_appletNowPlaying',
		node = 'home',
		text = self:string('SCREENSAVER_NOWPLAYING'),
		sound = 'WINDOWSHOW',
		weight = 1,
		callback = function(event, menuItem)
			self:goNowPlaying(Window.transitionPushLeft)
			end
	})
end

function notify_skinSelected(self)
	log:debug("notify_skinSelected")
	-- update menu
	notify_playerCurrent(self, self.player)
	-- update NP style info.
	self.nowPlayingScreenStyles = self:getNPStyles()
	if self.window and self.player then
		-- redisplay with no extra transition
		self:replaceNPWindow(true)
	end
end

function _titleText(self, token)
	local y = self.player and self.player:getPlaylistSize()
	if token == 'play' and y > 1 then
		local x = self.player:getPlaylistCurrentIndex()
		if x >= 1 and y > 1 and not self:getSelectedStyleParam('suppressXofY') then
			local xofy = tostring(self:string('SCREENSAVER_NOWPLAYING_OF', x, y))

			if self:getSelectedStyleParam('titleXofYonly') then
				title = xofy
			else
				title = tostring(self:string(modeTokens[token])) .. ' • ' .. xofy
			end
		else
			title = tostring(self:string(modeTokens[token]))
		end
	else
		title = self:string(modeTokens[token])
	end
	self.mainTitle = tostring(title)
	return self.mainTitle
end

function _isThisPlayer(self, player)

	if not self.player or not self.player:getId() then -- note happened(revealed 'and' bug) when server was down and restarted
		self.player = appletManager:callService("getCurrentPlayer")
	end

	if player:getId() ~= self.player:getId() then
		log:debug("notification was not for this player")
		log:debug("notification: ", player:getId(), "your player: ", self.player:getId())
		return false
	else
		return true
	end
end

function _updateAll(self)
	local playerStatus = self.player:getPlayerStatus()

	if playerStatus.item_loop then
		local trackInfo = self:_extractTrackInfo(playerStatus.item_loop[1])
		local showProgressBar = true
		-- XXX: current_title of null is a function value??
		if playerStatus.remote == 1 and type(playerStatus.current_title) == 'string' and type(trackInfo) == 'string' then
			trackInfo = trackInfo .. "\n" .. playerStatus.current_title
		end
		if playerStatus.time == 0 then
			showProgressBar = false
		end

		local item = playerStatus.item_loop[1]

		if self.window then
			_getIcon(self, item, self.artwork, playerStatus.remote)

			self:_updateTrack(trackInfo)
			self:_updateProgress(playerStatus)
			self:_updateButtons(playerStatus)
			self:_refreshRightButton()
			self:_updatePlaylist()
			self:_updateMode(playerStatus.mode)
			self._getXtraMetaData(self)

			-- preload artwork for next track
			if playerStatus.item_loop[2] then
				_getIcon(self, playerStatus.item_loop[2], Icon("artwork"), playerStatus.remote)
			end
		end
	else
		if self.window then
			_getIcon(self, nil, self.artwork, nil)
			self:_updateTrack("\n\n")
			self:_updatePlaylist()
		end
	end
	self:_updateVolume()
end

function _updateButtons(self, playerStatus)
	log:debug('_updateButtons')
	-- no sense updating the transport buttons unless
	-- we are connected to a player and have buttons initialized
	if not self.player and self.controlsGroup then
		return
	end

	local remoteMeta = playerStatus.remoteMeta

	local buttons = remoteMeta and remoteMeta.buttons
	-- if we have buttons data, the remoteMeta is remapping some buttons
	if buttons then
		log:debug('remap buttons to whatever remoteMeta needs')
		-- disable rew or fw as needed
		if buttons.rew and tonumber(buttons.rew) == 0 then
			self:_remapButton('rew', 'rewDisabled', nil)
		else
			self.controlsGroup:setWidget('rew', self.rewButton)
		end

		if buttons.fwd and tonumber(buttons.fwd) == 0 then
			-- Bug 15336: in order for a skip limit showBriefly to be generated, we still need to
			-- allow the jump_fwd action to be sent for the disabled button
			-- this could have implications for services that expect a disabled button to not send the action
			self:_remapButton('fwd', 'fwdDisabled', nil)
		else
			self.controlsGroup:setWidget('fwd', self.fwdButton)
		end

		if buttons['fwdNoSkipCount'] and tonumber(buttons['fwdNoSkipCount']) == 0 then
			-- Bug 15336: in order for a skip limit showBriefly to be generated, we still need to
			-- allow the jump_fwd action to be sent for the disabled button
			-- this could have implications for services that expect a disabled button to not send the action
			self:_remapButton('fwdNoSkipCount', 'fwdDisabledNoSkipCount', nil)
		else
			self.controlsGroup:setWidget('fwdNoSkipCount', self.fwdNoSkipCountButton)
		end

		if buttons.shuffle then
			local callback = function()
				local id = self.player:getId()
				local server = self.player:getSlimServer()
				local command = buttons.shuffle.command or function() return EVENT_CONSUME end
				server:userRequest(nil, id, command)
			end
			self:_remapButton('shuffleMode', buttons.shuffle.jiveStyle, callback)
		end

		if buttons['repeat'] then
			local callback = function()
				local id = self.player:getId()
				local server = self.player:getSlimServer()
				local command = buttons['repeat'].command or function() return EVENT_CONSUME end
				server:userRequest(nil, id, command)
			end
			self:_remapButton('repeatMode', buttons['repeat'].jiveStyle, callback)
		end

	-- if we don't have remoteMeta and button remapping, go back to defaults
	else
		local playlistSize = self.player and self.player:getPlaylistSize()
		-- bug 15085, gray out buttons under certain circumstances
		-- bug 15164, don't remove rew and fwd for remote tracks, because a single track playlist
		-- is not an indication that fwd and rwd are invalid actions
		if playlistSize == 1 and not self.player:isRemote() then
			log:debug('set buttons for single track playlist')
			-- single track playlist. if this track has no duration, disable rew button
			local elapsed, duration = self.player:getTrackElapsed()
			if duration then
				self.controlsGroup:setWidget('rew', self.rewButton)
			else
				self:_remapButton('rew', 'rewDisabled', function() return EVENT_CONSUME end)
			end
			self:_remapButton('fwd', 'fwdDisabled', function() return EVENT_CONSUME end)
			self:_remapButton('fwdNoSkipCount', 'fwdDisabledNoSkipCount', function() return EVENT_CONSUME end)
			self:_remapButton('shuffleMode', 'shuffleDisabled', function() return EVENT_CONSUME end)
			self.controlsGroup:setWidget('repeatMode', self.repeatButton)

			-- fwd and shuffle have little-to-no utility in single track playlists, disable them
		else
			log:debug('reset buttons to defaults')
			self.controlsGroup:setWidget('rew', self.rewButton)
			self.controlsGroup:setWidget('fwd', self.fwdButton)
			self.controlsGroup:setWidget('fwdNoSkipCount', self.fwdNoSkipCountButton)
			self.controlsGroup:setWidget('shuffleMode', self.shuffleButton)
			self.controlsGroup:setWidget('repeatMode', self.repeatButton)
			-- bug 15618: explicitly set style of rew and fwd here, since setWidget doesn't appear to be doing the job
			self.controlsGroup:getWidget('rew'):setStyle('rew')
			self.controlsGroup:getWidget('fwd'):setStyle('fwd')
			self.controlsGroup:getWidget('fwdNoSkipCount'):setStyle('fwdNoSkipCount')
		end
	end
end

function _refreshRightButton(self)
	local playlistSize = self.player and self.player:getPlaylistSize()
	if not playlistSize then
		return
	end
	if playlistSize == 1 and self.rbutton == 'playlist' then
		if not self.suppressTitlebar then
			log:debug('changing rbutton to + button')
			self.titleGroup:getWidget('rbutton'):setStyle('button_more')
		end
		self.rbutton = 'more'
	elseif self.rbutton == 'more' and playlistSize > 1 then
		if not self.suppressTitlebar then
			log:debug('changing rbutton to playlist button')
			self.titleGroup:getWidget('rbutton'):setStyle('button_playlist')
		end
		self.rbutton = 'playlist'
	end
end

function _remapButton(self, key, newStyle, newCallback)
	if not self.controlsGroup then
		return
	end
	-- set callback
	if newCallback then
		local newWidget = Button(Icon(key), newCallback)
		self.controlsGroup:setWidget(key, newWidget)
	end
	-- set style
	local widget = self.controlsGroup:getWidget(key)
	if newStyle then
		widget:setStyle(newStyle)
	end
end

function _updatePlaylist(self)

	local x = self.player:getPlaylistCurrentIndex()
	local y = self.player:getPlaylistSize()
	local xofy = ''
	if x and y and tonumber(x) > 0 and tonumber(y) >= tonumber(x) then
		xofy = tostring(x) .. '/' .. tostring(y)
	end

	local xofyLen = string.len(xofy)
	local xofyStyle = self.XofY:getStyle()

	-- if xofy exceeds 5 total chars change style to xofySmall to fit
	if xofyLen > 5 and xofyStyle ~= 'xofySmall' then
		self.XofY:setStyle('xofySmall')
	elseif xofyLen <= 5 and xofyStyle ~= 'xofy' then
		self.XofY:setStyle('xofy')
	end
	self.XofY:setValue(xofy)
	self.XofY:animate(true)
end

function _updateTrack(self, trackinfo, pos, length)
	if self.trackTitle then
		local trackTable
		-- SC is sending separate track/album/artist blocks
		if type(trackinfo) == 'table' then
			trackTable = trackinfo
		-- legacy SC support for all data coming in string 'text'
		else
			trackTable = string.split("\n", trackinfo)
		end

		local track = trackTable[1]
		local artist = trackTable[2]
		local album = trackTable[3]

		local artistalbum = ''
		if artist ~= '' and album ~= '' then
			artistalbum = artist .. ' • ' .. album
		elseif artist ~= '' then
			artistalbum = artist
		elseif album ~= '' then
			artistalbum = album
		end

		if self.scrollSwitchTimer and self.scrollSwitchTimer:isRunning() then
			self.scrollSwitchTimer:stop()
		end

		self.trackTitle:setValue(track)
		self.albumTitle:setValue(album)
		self.artistTitle:setValue(artist)
		self.artistalbumTitle:setValue(artistalbum)
		if self.scrollText then
			self.trackTitle:animate(true)
		else
			self.trackTitle:animate(false)
		end
		self.artistTitle:animate(false)
		self.albumTitle:animate(false)
		self.artistalbumTitle:animate(false)
		self.mytrackgenre:animate(false)
	end
end

function _updateProgress(self, data)
	if not self.player then
		return
	end

	local elapsed, duration = self.player:getTrackElapsed()

	if duration and tonumber(duration) > 0 then
		self.progressSlider:setRange(0, tonumber(duration), tonumber(elapsed))
	else
	-- If 0 just set it to 100
		self.progressSlider:setRange(0, 100, 0)
	end

	-- http streams show duration of 0 before starting, so update to a progress bar on the fly
	if duration and not showProgressBar then

		-- swap out progressBar
		self.window:removeWidget(self.progressNBGroup)
		self.window:addWidget(self.progressBarGroup)

		self.progressGroup = self.progressBarGroup
		showProgressBar = true
	end
	if not duration and showProgressBar then

		-- swap out progressBar
		self.window:removeWidget(self.progressBarGroup)
		self.window:addWidget(self.progressNBGroup)

		self.progressGroup = self.progressNBGroup
		showProgressBar = false
	end

	-- if we're shoing a progress bar, make sure the state of the slider reflects the ability to seek
	-- and is disabled when canSeek is false
	if showProgressBar then
		local canSeek = self.player:isTrackSeekable()
		log:debug('canSeek: ', canSeek)

		if canSeek then
			-- allow events to the slider
			self.progressSlider:setEnabled(true)
			self.progressSlider:setStyle('npprogressB')
		else
			-- consume all touches to this slider
			self.progressSlider:setEnabled(false)
			self.progressSlider:setStyle('npprogressB_disabled')
		end
	end
	_updatePosition(self)
end

function _updatePosition(self)
	if not self.player then
		return
	end

	local strElapsed = ""
	local strRemain = ""
	local pos = 0

	-- Bug 15814: do not update position if track isn't actually playing
	if self.player:isWaitingToPlay() then
		log:debug('track is waiting to play, do not update progress bar')
		return
	end
	local elapsed, duration = self.player:getTrackElapsed()

	if elapsed then
		if duration and duration > 0 and elapsed > duration then
			strElapsed = _secondsToString(duration)
		else
			strElapsed = _secondsToString(elapsed)
		end
	end

	if elapsed and elapsed >= 0 and duration and duration > 0 then
		if elapsed > duration then
			strRemain = "-" .. _secondsToString(0)
		else
			strRemain = "-" .. _secondsToString(duration - elapsed)
		end
	end

	if self.progressGroup then
		local elapsedWidget = self.progressGroup:getWidget('elapsed')
		local elapsedLen = string.len(strElapsed)
		local elapsedStyle = elapsedWidget:getStyle()
		--[[
		if elapsedLen > 5 and elapsedStyle ~= 'elapsedSmall' then
			elapsedWidget:setStyle('elapsedSmall')
		elseif elapsedLen <= 5 and elapsedStyle ~= 'elapsed' then
			elapsedWidget:setStyle('elapsed')
		end
		--]]
		elapsedWidget:setStyle('elapsed')

		self.progressGroup:setWidgetValue("elapsed", strElapsed)

		if showProgressBar then
			local remainWidget = self.progressGroup:getWidget('remain')
			local remainLen = string.len(strRemain)
			local remainStyle = remainWidget:getStyle()
			--[[
			if remainLen > 5 and remainStyle ~= 'remainSmall' then
				remainWidget:setStyle('remainSmall')
			elseif remainLen <= 5 and remainStyle ~= 'remain' then
				remainWidget:setStyle('remain')
			end
			--]]
			remainWidget:setStyle('remain')

			self.progressGroup:setWidgetValue("remain", strRemain)
			self.progressSlider:setValue(elapsed)
		end
	end
end

function _updateVolume(self)
	if not self.player then
		return
	end

	local volume = tonumber(self.player:getVolume())
	if self.volSlider and not self.fixedVolumeSet then
		local sliderVolume = self.volSlider:getValue()
		if sliderVolume ~= volume then
			log:debug("new volume from player: ", volume)
			self.volumeOld = volume
			self.volSlider:setValue(volume)
		end
	end
end

function _updateShuffle(self, mode)
	log:debug("_updateShuffle(): ", mode)
	-- don't update this if SC/SN has remapped shuffle button
	if self.player then
		local playerStatus = self.player:getPlayerStatus()
		if playerStatus and
			playerStatus.remoteMeta and
			playerStatus.remoteMeta.buttons and
			playerStatus.remoteMeta.shuffle then
			return
		end
	end
	local token = 'mode' .. mode
	if not shuffleModes[token] then
		log:error('not a valid shuffle mode: ', token)
		return
	end
	if self.controlsGroup then
		log:debug("shuffle button style changed to: ", shuffleModes[token])
		self.shuffleButton:setStyle(shuffleModes[token])
	end
end

function _updateRepeat(self, mode)
	log:debug("_updateRepeat(): ", mode)
	-- don't update this if SC/SN has remapped repeat button
	if self.player then
		local playerStatus = self.player:getPlayerStatus()
		if playerStatus and
			playerStatus.remoteMeta and
			playerStatus.remoteMeta.buttons and
			playerStatus.remoteMeta['repeat'] then
			return
		end
	end
	local token = 'mode' .. mode
	if not repeatModes[token] then
		log:error('not a valid repeat mode: ', token)
		return
	end
	if self.controlsGroup then
		log:debug("repeat button style changed to: ", repeatModes[token])
		self.repeatButton:setStyle(repeatModes[token])
	end
end

function _updateMode(self, mode)
	local token = mode
	-- sometimes there is a race condition here between updating player mode and power,
	-- so only set the title to 'off' if the mode is also not 'play'
	if token ~= 'play' and not self.player:isPowerOn() then
		token = 'off'
	end
	if self.titleGroup then
		local titleChange = self:_titleText(token)
		self:changeTitleText(titleChange)
	end
	if self.controlsGroup then
		local playIcon = self.controlsGroup:getWidget('play')
		if token == 'play' then
			playIcon:setStyle('pause')
		else
			playIcon:setStyle('play')
		end
	end
end

-----------------------------------------------------------------------------------------
-- Settings
--

function _goHomeAction(self)
	appletManager:callService("goHome")
	return EVENT_CONSUME
end

function _installListeners(self, window)
	window:addListener(EVENT_WINDOW_ACTIVE,
		function(event)
			self:_updateAll()
			return EVENT_UNUSED
		end
	)

	local showPlaylistAction = function (self)
		window:playSound("WINDOWSHOW")

		local playlistSize = self.player and self.player:getPlaylistSize()
		if playlistSize == 1 then
			-- use special showTrackOne method from SlimBrowser
			appletManager:callService("showTrackOne")
		else
			-- show playlist
			appletManager:callService("showPlaylist")
		end

		return EVENT_CONSUME
	end

	-- FIXME: hack to deal with removing actions from left/right - fix this in more generic way?
	window:addListener(EVENT_KEY_PRESS,
		function(event)
			local keycode = event:getKeycode()
			if keycode == KEY_LEFT then
				Framework:pushAction("back")
				return EVENT_CONSUME
			end
			if keycode == KEY_RIGHT then
				Framework:pushAction("go")
				return EVENT_CONSUME
			end
			return EVENT_UNUSED
		end
	)

	window:addActionListener("go", self, showPlaylistAction)
	window:addActionListener("go_home", self, _goHomeAction)
	window:addActionListener("go_now_playing", self, toggleNPScreenStyle)
	window:addActionListener("go_now_playing_or_playlist", self, showPlaylistAction)

	--also, no longer listening for hold in this situation, Ben and I felt that was a bug

	-- half a spin of the wheel on baby or controller takes you to the next NP style as well
	-- this is the function to do that
	window:addListener(EVENT_SCROLL,
		function(event)
			local scroll = event:getScroll()
			local dir
			if scroll > 0 then
				dir = 1
			else
				dir = -1
			end
			local now = Framework:getTicks()
			-- direction changed?
			if self.lastScrollDirection ~= dir then
				self.lastScrollDirection = dir
				self.lastScrollTime = now
				self.cumulativeScrollTicks = scroll
				return EVENT_CONSUME
			end

			-- timeout reached?
			if self.lastScrollTime + SCROLL_TIMEOUT < now then
				-- reset cumulativeScrollTicks
				self.cumulativeScrollTicks = 0
			end

			self.cumulativeScrollTicks = self.cumulativeScrollTicks + math.abs(scroll)

			-- threshhold reached?
			if self.cumulativeScrollTicks >= 8 then
				Framework:pushAction('go_now_playing')
				self.cumulativeScrollTicks = 0
				self.lastScrollDirection = nil
				self.lastScrollTime = nil
			else
				self.lastScrollTime = now
				self.lastScrollDirection = dir
			end

			return EVENT_CONSUME

		end
		)
end

function _setPlayerVolume(self, value)
	self.lastVolumeSliderAdjustT = Framework:getTicks()
	if value ~= self.volumeOld then
		self.player:volume(value, true)
		self.volumeOld = value
	end
end

function adjustVolume(self, value, useRateLimit)
	--volumeRateLimitTimer catches stops in fast slides, so that the "stopped on" value is not missed
	if not self.volumeRateLimitTimer then
		self.volumeRateLimitTimer = Timer(100,
						function()
							if not self.player then
								return
							end
							if self.volumeAfterRateLimit then
								self:_setPlayerVolume(self.volumeAfterRateLimit)
							end

						end, true)
	end
	if self.player then
		--rate limiting since these are serial networks calls
		local now = Framework:getTicks()
		if not useRateLimit or now > 350 + self.lastVolumeSliderAdjustT then
			self.volumeRateLimitTimer:restart()
			self:_setPlayerVolume(value)
			self.volumeAfterRateLimit = nil
		else
			--save value
			self.volumeAfterRateLimit = value

		end
	end
end

function _createTitleGroup(self, window, buttonStyle)
	local titleGroup = Group('title', {
		lbutton = window:createDefaultLeftButton(),

		text = Button(Label("text", self.mainTitle),
			function()
				Framework:pushAction('go_current_track_info')
				return EVENT_CONSUME
			end
		),

		rbutton = Button(
				Group(buttonStyle, { Icon("icon") }),
				function()
					Framework:pushAction("go") -- go action must work (as ir right and controller go must work also)
					return EVENT_CONSUME
				end,
				function()
					Framework:pushAction("title_right_hold")
					return EVENT_CONSUME
				end,
				function()
					Framework:pushAction("soft_reset")
					return EVENT_CONSUME
				end

		),
	})
	return titleGroup
end

function toggleNPScreenStyle(self)
	log:debug('change window style')
	local enabledNPScreenStyles = {}
	for i, v in ipairs(self.nowPlayingScreenStyles) do
		if v.enabled then
			table.insert(enabledNPScreenStyles, v)
		end
	end

	for i, v in ipairs(enabledNPScreenStyles) do
		if self.selectedStyle == v.style and v.enabled then
			if i == #enabledNPScreenStyles then
				self.selectedStyle = enabledNPScreenStyles[1].style
				break
			else
				self.selectedStyle = enabledNPScreenStyles[i+1].style
				break
			end
		end
	end

	log:debug('setting NP window style to: ', self.selectedStyle)

	if self.window and self.window:getStyle() == self.selectedStyle then
		-- no need to replace this window with the same style
		log:debug('the style of self.window matches self.selectedStyle. No need to do anything')
	else
		local settings = self:getSettings()
		settings.selectedStyle = self.selectedStyle
		self:storeSettings()
		self._getXtraMetaData(self)

		self:replaceNPWindow()
	end
end

function replaceNPWindow(self,noTrans)
	log:debug("REPLACING NP WINDOW")
	local oldWindow = self.window

	self.window = _createUI(self)
	if self.player and self.player:getPlayerStatus() then
		self:_updateButtons(self.player:getPlayerStatus())
		self:_updateRepeat(self.player:getPlayerStatus()['playlist repeat'])
		self:_updateShuffle(self.player:getPlayerStatus()['playlist shuffle'])
	end
	self:_refreshRightButton()
	self.window:replace(oldWindow, noTrans and Window.transitionNone or Window.transitionFadeIn)
end

----------------------------------------------------------------------------------------
-- Screen Saver Display
--

function _createUI(self)
	--local window = Window("text_list")
	self.windowStyle = self.selectedStyle
	if not self.windowStyle then
		self.windowStyle = 'nowplaying'
	end
	local window = Window(self.windowStyle)

	local playerStatus = self.player:getPlayerStatus()
	if playerStatus then
		if not playerStatus.duration then
			showProgressBar = false
		else
			showProgressBar = true
		end
	end

	self.mainTitle = self:_titleText('play')

	self.titleGroup = self:_createTitleGroup(window, 'button_playlist')

	self.rbutton = 'playlist'

	self.trackTitle = Label('nptrack', "")
	self.XofY = Label('xofy', "")
	self.albumTitle = Label('npalbum', "")
	self.artistTitle = Label('npartist', "")
	self.artistalbumTitle = Label('npartistalbum', "")
	self.myrating = Icon("")
	self.ratingaction0 = Icon("")
	self.ratingaction1 = Icon("")
	self.ratingaction2 = Icon("")
	self.ratingaction3 = Icon("")
	self.ratingaction4 = Icon("")
	self.ratingaction5 = Icon("")
	self.ratingaction6 = Icon("")
	self.statusremote = Icon("")
	self.statuscsst = Icon("")
	self.statuslyrics = Icon("")
	self.statuslossless = Icon("")
	self.mylyrics = Textarea('nplyrics', "No lyrics")
	self.mytrackaudiometa = Label('npaudiometa', "")
	self.mytrackgenre = Label('npgenre', "")
	self.theclock = Label('npclock', "")

	local launchContextMenu =
		function()
			Framework:pushAction('go_now_playing')
			return EVENT_CONSUME
		end

	self.trackTitleButton = Button(self.trackTitle, launchContextMenu)
	self.albumTitleButton = Button(self.albumTitle, launchContextMenu)
	self.artistTitleButton = Button(self.artistTitle, launchContextMenu)
	self.mytrackaudiometaButton = Button(self.mytrackaudiometa, launchContextMenu)
	self.mytrackgenreButton = Button(self.mytrackgenre, launchContextMenu)

	self.nptrackGroup = Group('nptitle', {
		nptrack = self.trackTitleButton,
		xofy = self.XofY,
	})
	self.npaudiometaGroup = Group('npaudiometagroup', {
		npaudiometa = self.mytrackaudiometaButton,
	})
	self.npclockGroup = Group('npclockgroup', {
		npclock = self.theclock,
	})
	self.npgenreGroup = Group('npgenregroup', {
		npgenre = self.mytrackgenreButton,
	})
	self.npartistGroup = Group('npartistgroup', {
		npartist = self.artistTitleButton,
	})
	self.npalbumGroup = Group('npalbumgroup', {
		npalbum = self.albumTitleButton,
	})
	self.npratingGroup = Group('npratinggroup', {
		nprating = self.myrating,
	})
	self.npstatusiconGroup = Group('npstatusicongroup', {
		npstatusremote = self.statusremote,
		npstatuscsst = self.statuscsst,
		npstatuslyrics = self.statuslyrics,
		npstatuslossless = self.statuslossless,
	})
	self.nplyricsGroup = Group('nplyricsgroup', {
		nplyrics = self.mylyrics,
	})

	if not self.scrollSwitchTimer and self.scrollText then
		self:_addScrollSwitchTimer()
		self.scrollSwitchTimer = Timer(3000,
					function()
						self.trackTitle:animate(true)
						self.artistalbumTitle:animate(false)
						self.artistTitle:animate(false)
						self.albumTitle:animate(false)
						self.mytrackgenre:animate(false)
					end, true)

	end

	self.trackTitle.textStopCallback =
		function(label)
			if self.scrollSwitchTimer and not self.scrollSwitchTimer:isRunning() then
				log:debug('trackTitle animation done, animate artistalbum/artistTitle/genre')
				self.artistalbumTitle:animate(true)
				self.artistTitle:animate(true)
				self.mytrackgenre:animate(false)
				self.trackTitle:animate(false)
			end
		end

	local hasArtistAlbum = jiveMain:getSkinParam("NOWPLAYING_TRACKINFO_LINES") == 2

	if hasArtistAlbum then
		self.artistalbumTitle.textStopCallback =
			function(label)
				self.artistalbumTitle:animate(false)
				self.trackTitle:animate(false)
				self.mytrackgenre:animate(false)
				if self.scrollSwitchTimer and not self.scrollSwitchTimer:isRunning() and
					not self.scrollTextOnce then
						log:debug('artistAlbum animation done, restarting timer')
						self.scrollSwitchTimer:restart()
				end
			end

	else
		self.artistTitle.textStopCallback =
			function(label)
				if self.scrollSwitchTimer and not self.scrollSwitchTimer:isRunning() then
					log:debug('artist animation done, animate album text')
					self.trackTitle:animate(false)
					self.artistTitle:animate(false)
					self.mytrackgenre:animate(false)
					self.albumTitle:animate(true)
				end
			end

		self.albumTitle.textStopCallback =
			function(label)
				if self.scrollSwitchTimer and not self.scrollSwitchTimer:isRunning() then
					log:debug('in albumTitle textStop callback')
					self.artistTitle:animate(false)
					self.albumTitle:animate(false)
					self.trackTitle:animate(false)
					if (self:getSettings()["displayGenre"]) then
						self.mytrackgenre:animate(true)
					else
						if self.scrollSwitchTimer and not self.scrollSwitchTimer:isRunning() and not self.scrollTextOnce then
							log:debug('album animation done, restarting timer')
							self.scrollSwitchTimer:restart()
						end
					end
				end
			end

		if (self:getSettings()["displayGenre"]) then
			self.mytrackgenre.textStopCallback =
				function(label)
					log:debug('in genre textStop callback')
					self.artistTitle:animate(false)
					self.albumTitle:animate(false)
					self.trackTitle:animate(false)
					self.mytrackgenre:animate(false)
					if self.scrollSwitchTimer and not self.scrollSwitchTimer:isRunning() and not self.scrollTextOnce then
							log:debug('genre animation done, restarting timer')
							self.scrollSwitchTimer:restart()
					end
				end
		end
	end

	if not self.gotoTimer then
		self.gotoTimer = Timer(400,
			function()
				if self.gotoElapsed then
					self.player:gototime(self.gotoElapsed)
					self.gotoElapsed = nil
				end
			end,
			true)
	end

	self.progressSlider = Slider('npprogressB', 0, 100, 0,
		function(slider, value, done)
			self.player:setWaitingToPlay(1)
			self.gotoElapsed = value
			self.gotoTimer:restart()
		end)
	self.progressBarGroup = Group('npprogress', {
						elapsed = Label("elapsed", ""),
						slider = self.progressSlider,
						remain = Label("remain", "")
	})

	self.progressNBGroup = Group('npprogressNB', {
						elapsed = Label("elapsed", "")
	})

	window:addTimer(1000, function() self:_updatePosition() end)

	if (self:getSettings()["displayClock"] or self:getSettings()["displayClock"]) then
		window:addTimer(1000, function() self:_getTime() end)
	end

	if showProgressBar then
		self.progressGroup = self.progressBarGroup
	else
		self.progressGroup = self.progressNBGroup
	end

	self.artwork = Icon("artwork")

	self.artworkGroup = Button(
		Group('npartwork', {
			artwork = self.artwork,
		}),
		function()
			Framework:pushAction("go_now_playing")
			return EVENT_CONSUME
		end
	)

	self.nplyricsgroup = Button(
		Group('nplyrics', {
			nplyrics = self.nplyrics,
		}),
		function()
			Framework:pushAction("go_now_playing")
			return EVENT_CONSUME
		end
	)

	self.npratingactionGroupUnrate1 = Button(
		Group('npratingactiongroupunrate1', {
			npratingactiongroupunrate1 = self.ratingaction0,
		}),
		function()
			self._setRating(self, 0)
			return EVENT_CONSUME
		end
	)
	self.npratingactionGroup1 = Button(
		Group('npratingactiongroup1', {
			npratingactiongroup1 = self.ratingaction1,
		}),
		function()
			self._setRating(self, 20)
			return EVENT_CONSUME
		end
	)
	self.npratingactionGroup2 = Button(
		Group('npratingactiongroup2', {
			npratingactiongroup2 = self.ratingaction2,
		}),
		function()
			self._setRating(self, 40)
			return EVENT_CONSUME
		end
	)
	self.npratingactionGroup3 = Button(
		Group('npratingactiongroup3', {
			npratingactiongroup3 = self.ratingaction3,
		}),
		function()
			self._setRating(self, 60)
			return EVENT_CONSUME
		end
	)
	self.npratingactionGroup4 = Button(
		Group('npratingactiongroup4', {
			npratingactiongroup4 = self.ratingaction4,
		}),
		function()
			self._setRating(self, 80)
			return EVENT_CONSUME
		end
	)
	self.npratingactionGroup5 = Button(
		Group('npratingactiongroup5', {
			npratingactiongroup5 = self.ratingaction5,
		}),
		function()
			self._setRating(self, 100)
			return EVENT_CONSUME
		end
	)
	self.npratingactionGroupUnrate2 = Button(
		Group('npratingactiongroupunrate2', {
			npratingactiongroupunrate2 = self.ratingaction6,
		}),
		function()
			self._setRating(self, 0)
			return EVENT_CONSUME
		end
	)

	-- Visualizer: Spectrum Visualizer - only load if needed
	if self.windowStyle == "nowplaying_spectrum_text" then
		self.visuGroup = Button(
			Group('npvisu', {
				visu = SpectrumMeter("spectrum"),
			}),
			function()
				Framework:pushAction("go_now_playing")
				return EVENT_CONSUME
			end
		)
	end

	-- Visualizer: Analog VU Meter - only load if needed
	if self.windowStyle == "nowplaying_vuanalog_text" then
		self.visuGroup = Button(
			Group('npvisu', {
				visu = VUMeter("vumeter_analog"),
			}),
			function()
				Framework:pushAction("go_now_playing")
				return EVENT_CONSUME
			end
		)
	end

	local playIcon = Button(Icon('play'),
				function()
					Framework:pushAction("pause")
					return EVENT_CONSUME
				end,
				function()
					Framework:pushAction("stop")
					return EVENT_CONSUME
				end
			)
	if playerStatus and playerStatus.mode == 'play' then
		playIcon:setStyle('pause')
	end

	self.repeatButton = Button(Icon('repeatMode'),
				function()
					Framework:pushAction("repeat_toggle")
				return EVENT_CONSUME
			end
			)
	self.shuffleButton = Button(Icon('shuffleMode'),
				function()
					Framework:pushAction("shuffle_toggle")
				return EVENT_CONSUME
			end
			)

	self.volSlider = Slider('npvolumeB', 0, 100, 0,
			function(slider, value, done)
				if self.fixedVolumeSet then
					log:info('FIXED VOLUME. DO NOTHING')
				else
					--rate limiting since these are serial networks calls
					adjustVolume(self, value, true)
					self.volumeSliderDragInProgress = true
				end
			end,
			function(slider, value, done)
				if self.fixedVolumeSet then
					log:info('FIXED VOLUME. DO NOTHING')
				else
					--called after a drag completes to insure final value not missed by rate limiting
					self.volumeSliderDragInProgress = false

					adjustVolume(self, value, false)
				end
			end)
	self.volSlider.jumpOnDown = true
	self.volSlider.pillDragOnly = true
	self.volSlider.dragThreshold = 5
	window:addActionListener('add', self, function()
		Framework:pushAction('go_current_track_info')
		return EVENT_CONSUME
	end)

	for i = 0,9 do
		local actionString = 'set_preset_' .. tostring(i)
		window:addActionListener(actionString, self, function()
			appletManager:callService("setPresetCurrentTrack", i)
			return EVENT_CONSUME
		end)
	end

	window:addActionListener("page_down", self,
				function()
					local e = Event:new(EVENT_SCROLL, 1)
					Framework:dispatchEvent(self.volSlider, e)
					return EVENT_CONSUME
				end)
	window:addActionListener("page_up", self,
				function()
					local e = Event:new(EVENT_SCROLL, -1)
					Framework:dispatchEvent(self.volSlider, e)
					return EVENT_CONSUME
				end)
	self.volSlider:addTimer(1000,
				function()
					if not self.volumeSliderDragInProgress then
						self:_updateVolume()
					end
				end)

	self.rewButton = Button(
			Icon('rew'),
			function()
				Framework:pushAction("jump_rew")
				return EVENT_CONSUME
			end
	)
	self.fwdButton = Button(
			Icon('fwd'),
			function()
				Framework:pushAction("jump_fwd")
				return EVENT_CONSUME
			end
	)
	self.fwdNoSkipCountButton = Button(
			Icon('fwdNoSkipCount'),
			function()
				log:debug('skip track without increasing its skip count')
				self._fwdNoSkipCount(self)
				return EVENT_CONSUME
			end
	)

	self.controlsGroup = Group('npcontrols', {
			div1 = Icon('div1'),
			div2 = Icon('div2'),
			div3 = Icon('div3'),
			div4 = Icon('div4'),
			div5 = Icon('div5'),
			div6 = Icon('div6'),
			div7 = Icon('div7'),

			rew = self.rewButton,
			play = playIcon,
			fwd = self.fwdButton,
			fwdNoSkipCount = self.fwdNoSkipCountButton,

			repeatMode = self.repeatButton,
			shuffleMode = self.shuffleButton,

			rateHigher = Button(
				Icon('rateHigher'),
				function()
					log:debug('increase track rating by half-star')
					self._setRating(self, 10, '+')
					return EVENT_CONSUME
				end
			),
			rateLower = Button(
				Icon('rateLower'),
				function()
					log:debug('decrease track rating by half-star')
					self._setRating(self, 10, '-')
					return EVENT_CONSUME
				end
			),
			volDown = Button(
				Icon('volDown'),
				function()
					-- Bug 15826: Allow volume events to be sent even if volume is fixed
					-- at 100% to allow IR Blaster (a server side extra) to work properly.
					-- Catch volume down button in NP screen on Fab4
					if self.fixedVolumeSet and System:hasIRBlasterCapability() then
						-- Send command directly to server w/o updating local volume
						Player.volume(self.player, 99, true)
					end

					local e = Event:new(EVENT_SCROLL, -3)
					Framework:dispatchEvent(self.volSlider, e)
					return EVENT_CONSUME
				end
			),
			volUp = Button(
				Icon('volUp'),
				function()
					-- Bug 15826: Allow volume events to be sent even if volume is fixed
					-- at 100% to allow IR Blaster (a server side extra) to work properly.
					-- Catch volume up button in NP screen on Fab4
					if self.fixedVolumeSet and System:hasIRBlasterCapability() then
						-- Send command directly to server w/o updating local volume
						Player.volume(self.player, 101, true);
					end

					local e = Event:new(EVENT_SCROLL, 3)
					Framework:dispatchEvent(self.volSlider, e)
					return EVENT_CONSUME
				end
			),
 			volSlider = self.volSlider,
	})

	self.preartwork = Icon("artwork") -- not disabled, used for preloading

	window:addWidget(self.nptrackGroup)
	if (self:getSettings()["displayAudioMetaData"] or self:getSettings()["displayYear"]) then
		window:addWidget(self.npaudiometaGroup)
	end
	if (self:getSettings()["displayClock"] or self:getSettings()["displayClock"]) then
		window:addWidget(self.npclockGroup)
	end
	if (self:getSettings()["displayGenre"]) then
		window:addWidget(self.npgenreGroup)
	end
	window:addWidget(self.nplyricsGroup)
	window:addWidget(self.npalbumGroup)
	window:addWidget(self.npartistGroup)
	window:addWidget(self.artistalbumTitle)
	if self:getSettings()["displayRating"] then
		window:addWidget(self.npratingGroup)
		if self:getSettings()["NPscreenRating"] then
			window:addWidget(self.npratingactionGroupUnrate1)
			window:addWidget(self.npratingactionGroup1)
			window:addWidget(self.npratingactionGroup2)
			window:addWidget(self.npratingactionGroup3)
			window:addWidget(self.npratingactionGroup4)
			window:addWidget(self.npratingactionGroup5)
			window:addWidget(self.npratingactionGroupUnrate2)
		end
	end
	if self:getSettings()["displayStatusIcons"] then
		window:addWidget(self.npstatusiconGroup)
	end
	window:addWidget(self.artworkGroup)
	-- Visualizer: Only load if needed
	if (self.windowStyle == "nowplaying_spectrum_text") or (self.windowStyle == "nowplaying_vuanalog_text") then
		window:addWidget(self.visuGroup)
	end

	self:_setVolumeSliderStyle()

	window:addWidget(self.controlsGroup)
	window:addWidget(self.progressGroup)

	-- FIXME: the suppressTitlebar skin param should not be necessary if the window's style for title is { hidden = 1 }, but this looks to be a bug in the underlying skin code
	self.suppressTitlebar = self:getSelectedStyleParam('suppressTitlebar')
	if not self.suppressTitlebar then
		window:addWidget(self.titleGroup)
	end

	window:focusWidget(self.nptrackGroup)
	-- register window as a screensaver, unless we are explicitly not in that mode
	if self.isScreensaver then
		local manager = appletManager:getAppletInstance("ScreenSavers")
		manager:screensaverWindow(window, _, _, _, 'NowPlaying')
	end

	-- install some listeners to the window
	self:_installListeners(window)
	return window
end

-- wrapper method to allow showNowPlaying to remain as named so the "screensaver"
-- can be found by the Screensaver applet correctly,
-- while allowing the method to be called via the service API
function goNowPlaying(self, transition, direct)
	self.transition = transition
	if not self.player then
		self.player = appletManager:callService("getCurrentPlayer")
	end

	if self.player then
		self.isScreensaver = false

		if self:_playlistHasTracks() or appletManager:callService("isLineInActive") then
			self:showNowPlaying(transition, direct)
		else
			_delayNowPlaying(self, direct)
			return
		end
	else
		return false
	end
end

function _delayNowPlaying(self, direct)
	local timer = Timer(1000,
		function()
			if _playlistHasTracks(self) then
				self:showNowPlaying(transition, direct)
			else
				local browser = appletManager:getAppletInstance("SlimBrowser")
								browser:showPlaylist()
			end
		end
	, true)
	timer:start()
end

--service method
function hideNowPlaying(self)
	log:warn("hideNowPlaying")

	if self.window then
		self.window:hide()
	end
end

function _playlistHasTracks(self)
	if not self.player then
		return false
	end

	if self.player:getPlaylistSize() and self.player:getPlaylistSize() > 0 then
		return true
	else
		return false
	end
end

function openScreensaver(self)
	--bug 12002 - don't really go into SS mode with NP ever. TODO: if this idea stickes, remove SS vs NON-SS mode code
	appletManager:callService("deactivateScreensaver") -- not needed currently, but is defensive if other cleanup gets added to deactivateScreensaver
	appletManager:callService("restartScreenSaverTimer")

	self:showNowPlaying()

	return false
end

function showNowPlaying(self, transition, direct)
	-- now we're ready to save the style table to self
	self.nowPlayingScreenStyles = self:getNPStyles()

	if not self.selectedStyle then
		local settings = self:getSettings()
		self.selectedStyle = settings.selectedStyle or 'nowplaying'
	end

	local npWindow = self.window

	local lineInActive = appletManager:callService("isLineInActive")
	if not direct and lineInActive then -- line in might not be deactivated yet (waits for player status), so look for direct
		npWindow = appletManager:callService("getLineInNpWindow")
	end
	if Framework:isWindowInStack(npWindow) then
		log:debug('NP already on stack')
		npWindow:moveToTop()

		-- restart the screensaver timer if we hit this clause
		appletManager:callService("restartScreenSaverTimer")

		if appletManager:callService("isScreensaverActive") then
			--In rare circumstances, SS might not have been deactivated yet, so we force it closed
			log:debug("SS was active")
			appletManager:callService("deactivateScreensaver")
		else
			return
		end
	end

	if not direct and lineInActive then
		npWindow:show()
		return
	end

	-- if we're opening this after freeing the applet, grab the player again
	if not self.player then
		self.player = appletManager:callService("getCurrentPlayer")
	end

	if self.player then
		self.player:unsubscribe('/slim/ratingslightchangedratingupdate')
		self.player:subscribe(
			'/slim/ratingslightchangedratingupdate',
			function(chunk)
				if not chunk.data[1] or chunk.data[1] ~= "ratingslightchangedratingupdate" then
					return
				end

				local currentRatingInfo = chunk.data[5]
				if currentRatingInfo then
					local rating = tonumber(currentRatingInfo);
					if rating > 0 then
						self.myrating:setStyle('ratingLevel'..rating)
					else
						self.myrating:setStyle('ratingLevel0')
					end
				end
			end,
			self.player:getId(),
			{'ratingslightchangedratingupdate'}
		)
	end

	local playerStatus = self.player and self.player:getPlayerStatus()

	log:debug("player=", self.player, " status=", playerStatus)

	-- playlist_tracks needs to be > 0 or else defer back to SlimBrowser
	if not self:_playlistHasTracks() then
		_delayNowPlaying(self)
		return
	end

	-- this is to show the window to be opened in one of three modes:
	-- browse, ss, and large (i.e., small med & large)

	--convenience
	local _thisTrack
	if playerStatus.item_loop then
		_thisTrack = playerStatus.item_loop[1]
	end

	if not transition then
		transition = Window.transitionFadeIn
	end

	if not self.window then
		self.window = _createUI(self)
	end

	self.player = appletManager:callService("getCurrentPlayer")

	local transitionOn = transition

	if not self.player then
		-- No current player - don't start screensaver
		return
	end

	-- if we have data, then update and display it
	if _thisTrack then
		local trackInfo = self:_extractTrackInfo(_thisTrack)

		if playerStatus.remote == 1 and type(playerStatus.current_title) == 'string' and type(trackInfo) == 'string' then
			trackInfo = trackInfo .. "\n" .. playerStatus.current_title
		end

		_getIcon(self, _thisTrack, self.artwork, playerStatus.remote)
		self:_updateMode(playerStatus.mode)
		self:_getXtraMetaData(self)
		self:_getTime(self)
		self:_updateTrack(trackInfo)
		self:_updateProgress(playerStatus)
		self:_updatePlaylist()
		self:_getRLstatus(self)
		self:_getAPCstatus(self)

		-- preload artwork for next track
		if playerStatus.item_loop[2] then
			_getIcon(self, playerStatus.item_loop[2], Icon("artwork"), playerStatus.remote)
		end

	-- otherwise punt
	else
		-- FIXME: we should probably exit the window when there's no track to display
		_getIcon(self, nil, playerStatus.artwork, nil)
		self:_updateTrack("\n\n\n")
		self:_updateMode(playerStatus.mode)
		self:_updatePlaylist()
	end

	self:_updateVolume()
	self:_updateRepeat(playerStatus['playlist repeat'])
	self:_updateShuffle(playerStatus['playlist shuffle'])
	self.volumeOld = tonumber(self.player:getVolume())

	-- Initialize with current data from Player
	self.window:show(transitionOn)
	self:_updateAll()
end

function _addScrollSwitchTimer(self)
	if not self.scrollSwitchTimer then
		log:debug('Adding scrollSwitchTimer for scrolling text, self.scrollText: ', self.scrollText, ' self.scrollTextOnce: ', self.scrollTextOnce)
		self.scrollSwitchTimer = Timer(3000,
			function()
				self.trackTitle:animate(true)
				self.artistalbumTitle:animate(false)
				self.artistTitle:animate(false)
				self.albumTitle:animate(false)
				self.mytrackgenre:animate(false)
			end,
			true
		)
	else
		log:debug('_addScrollSwitchTimer() called but Timer object already exists: ', self.scrollSwitchTimer)
	end
end

-- internal method to decide if track information is from the 'text' field or from 'track', 'artist', and 'album'
-- if it has the three fields, return a table
-- otherwise return a string
function _extractTrackInfo(self, _track)
	if _track.track then
		local returnTable = {}
		table.insert(returnTable, _track.track)
		table.insert(returnTable, _track.artist)
		table.insert(returnTable, _track.album)
		return returnTable
	else
		return _track.text or "\n\n\n"
	end
end

function freeAndClear(self)
	self.player = false
	jiveMain:removeItemById('appletNowPlaying')
	self:free()
end

function free(self)
	-- when we leave NowPlaying, ditch the window
	-- the screen can get loaded with two layouts, and by doing this
	-- we force the recreation of the UI when re-entering the screen, possibly in a different mode
	log:debug(self.player)
	if self.player then
		player:unsubscribe('/slim/ratingslightchangedratingupdate')
	end

	-- player has left the building, close Now Playing browse window
	if self.window then
		self.window:hide()
	end

	return true
end
