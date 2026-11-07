--==============================================================================
-- COSMOS ODYSSEY - COMPLETE CLIENT-SIDE SPACE EXPERIENCE (LUAU)
-- Compatível com Delta Executor (Mobile/PC) & Roblox StarterPlayerScripts
-- Arquitetura Modular Unificada (< 30 locals no escopo raiz, 0 RemoteEvents)
--==============================================================================

if _G.__CosmosCleanup then
	pcall(_G.__CosmosCleanup)
	_G.__CosmosCleanup = nil
end

local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	TweenService = game:GetService("TweenService"),
	Lighting = game:GetService("Lighting"),
	SoundService = game:GetService("SoundService"),
	Workspace = game:GetService("Workspace"),
	GuiService = game:GetService("GuiService"),
	CoreGui = game:GetService("CoreGui"),
}

local LocalPlayer = Services.Players.LocalPlayer
local Cosmos = {
	Version = "4.0.0-ARGON",
	ActivePartsCount = 0,
	MaxActiveParts = 2000,
	IsRunning = false,
	IsPaused = false,
	InMenu = true,
	QualityLevel = 3, -- 3 = Alta, 2 = Média, 1 = Baixa
	TimeElapsed = 0,
	FrameTimes = {},
	Modules = {},
	ModuleOrder = {
		"Audio",
		"CameraFX",
		"Universe",
		"Atmosphere",
		"Gravity",
		"Flight",
		"AuraRNG",
		"Combat",
		"EnemyAI",
		"Props",
		"Missions",
		"Settings",
		"HUD",
	},
	State = {
		Character = nil,
		Humanoid = nil,
		RootPart = nil,
		Head = nil,
		Camera = Services.Workspace.CurrentCamera,
		Health = 100,
		MaxHealth = 100,
		Shield = 100,
		MaxShield = 100,
		Stamina = 100,
		MaxStamina = 100,
		Oxygen = 100,
		MaxOxygen = 100,
		SpaceFactor = 0,
		Altitude = 0,
		Speed = 0,
		IsFlying = false,
		FlightMode = 1, -- 1 = Normal, 2 = Turbo, 3 = Hiper
		WalkBody = nil,
		ActiveSlot = 1,
		EquippedAura = nil,
		LuckMultiplier = 1.0,
		LuckExpiry = 0,
		RollCount = 0,
		PityCounter = 0,
		BestAuraIndex = 0,
		XP = 0,
		Level = 1,
		Kills = 0,
		PropsBroken = 0,
		VisitedBodies = {},
		UnlockedAuras = {},
		AuraInventory = {},
		MoveVector = Vector3.zero,
		VerticalInput = 0,
		TouchLookDelta = Vector2.zero,
		Aiming = false,
		Firing = false,
	},
}

--==============================================================================
-- [SEÇÃO 01] UTIL, CONFIG, MAID, SIGNAL, POOL, SPRING E TABELAS DE DADOS
--==============================================================================

local Config = {
	UniverseCenter = Vector3.new(0, 8500, 0),
	SunRadius = 800, -- Diâmetro 1600 studs
	AltStart = 1200,
	AltFull = 3800,
	StarCountHigh = 600,
	StarCountMed = 360,
	StarCountLow = 180,
	AsteroidCountHigh = 150,
	AsteroidCountMed = 95,
	AsteroidCountLow = 45,
	NebulaClouds = 28,
	Flight = {
		NormalSpeed = 140,
		TurboSpeed = 360,
		HyperSpeed = 950,
		Accel = 6.5,
		Decel = 5.0,
		TurnSpeed = 8.0,
		BankAngle = math.rad(38),
		SonicBoomThreshold = 310,
		StaminaDrainTurbo = 8,
		StaminaDrainHyper = 18,
		StaminaRegen = 14,
	},
	Gravity = {
		EngageSurfaceDist = 48,
		DisengageSurfaceDist = 90,
		MoonGravityAccel = 38,
		PlanetGravityAccel = 85,
		JumpImpulse = 62,
		AlignSpeed = 10,
		CamUpSmooth = 6.5,
	},
	Theme = {
		BgDark = Color3.fromRGB(8, 20, 24),
		BgPanel = Color3.fromRGB(11, 28, 34),
		BgHeader = Color3.fromRGB(14, 38, 46),
		StrokeCyan = Color3.fromRGB(0, 225, 255),
		AccentTeal = Color3.fromRGB(0, 195, 180),
		AccentGold = Color3.fromRGB(255, 200, 60),
		AccentRed = Color3.fromRGB(255, 70, 85),
		AccentGreen = Color3.fromRGB(60, 245, 155),
		AccentPurple = Color3.fromRGB(185, 95, 255),
		TextMain = Color3.fromRGB(230, 250, 255),
		TextDim = Color3.fromRGB(140, 185, 195),
	},
	RarityTiers = {
		{ Name = "Comum", Color = Color3.fromRGB(175, 190, 200), SuspTime = 1.3, Shake = 0.2 },
		{ Name = "Incomum", Color = Color3.fromRGB(70, 235, 130), SuspTime = 1.7, Shake = 0.35 },
		{ Name = "Raro", Color = Color3.fromRGB(55, 165, 255), SuspTime = 2.3, Shake = 0.55 },
		{ Name = "Épico", Color = Color3.fromRGB(185, 85, 255), SuspTime = 3.1, Shake = 0.85 },
		{ Name = "Lendário", Color = Color3.fromRGB(255, 190, 40), SuspTime = 4.2, Shake = 1.25 },
		{ Name = "Mítico", Color = Color3.fromRGB(255, 55, 95), SuspTime = 5.4, Shake = 1.75 },
		{ Name = "Cósmico", Color = Color3.fromRGB(110, 250, 255), SuspTime = 6.8, Shake = 2.4 },
	},
}

Config.Bodies = {
	{
		Id = "SylphTerra",
		Name = "Nova Terra",
		Type = "Terra",
		Radius = 380,
		OrbitMajor = 2500,
		OrbitMinor = 2350,
		OrbitSpeed = 0.018,
		OrbitTilt = math.rad(4),
		Phase = 0.2,
		RotSpeed = 0.08,
		Color = Color3.fromRGB(28, 105, 205),
		SecondaryColor = Color3.fromRGB(45, 155, 78),
		AtmosphereColor = Color3.fromRGB(95, 185, 255),
		HasAtmosphere = true,
		Walkable = true,
		SurfaceGravity = 78,
		Moons = {
			{
				Id = "Selene",
				Name = "Lua Selene",
				Radius = 115,
				OrbitRadius = 640,
				OrbitSpeed = 0.09,
				OrbitTilt = math.rad(11),
				Phase = 1.0,
				Color = Color3.fromRGB(175, 180, 190),
				CrateColor = Color3.fromRGB(115, 120, 130),
				Walkable = true,
				SurfaceGravity = 34,
			},
		},
	},
	{
		Id = "AresPrime",
		Name = "Pyros (Marte)",
		Type = "Mars",
		Radius = 290,
		OrbitMajor = 4100,
		OrbitMinor = 3800,
		OrbitSpeed = 0.013,
		OrbitTilt = math.rad(-7),
		Phase = 1.8,
		RotSpeed = 0.07,
		Color = Color3.fromRGB(205, 82, 42),
		SecondaryColor = Color3.fromRGB(240, 248, 255),
		AtmosphereColor = Color3.fromRGB(235, 130, 85),
		HasAtmosphere = true,
		Walkable = true,
		SurfaceGravity = 52,
		Moons = {
			{
				Id = "Phobos",
				Name = "Fobos",
				Radius = 78,
				OrbitRadius = 470,
				OrbitSpeed = 0.14,
				OrbitTilt = math.rad(6),
				Phase = 0.4,
				Color = Color3.fromRGB(142, 128, 118),
				CrateColor = Color3.fromRGB(95, 84, 78),
				Walkable = true,
				SurfaceGravity = 26,
			},
			{
				Id = "Deimos",
				Name = "Deimos",
				Radius = 62,
				OrbitRadius = 680,
				OrbitSpeed = 0.08,
				OrbitTilt = math.rad(-14),
				Phase = 2.7,
				Color = Color3.fromRGB(155, 148, 138),
				CrateColor = Color3.fromRGB(108, 102, 95),
				Walkable = true,
				SurfaceGravity = 22,
			},
		},
	},
	{
		Id = "Kronos",
		Name = "Kronos Prime",
		Type = "GasGiant",
		Radius = 590,
		OrbitMajor = 6400,
		OrbitMinor = 6050,
		OrbitSpeed = 0.008,
		OrbitTilt = math.rad(9),
		Phase = 3.2,
		RotSpeed = 0.14,
		Color = Color3.fromRGB(215, 175, 120),
		SecondaryColor = Color3.fromRGB(175, 125, 82),
		AtmosphereColor = Color3.fromRGB(245, 210, 155),
		HasAtmosphere = true,
		Walkable = false,
		SurfaceGravity = 120,
		HasRings = true,
		RingInner = 740,
		RingOuter = 1180,
		Moons = {
			{
				Id = "Titanis",
				Name = "Titanis",
				Radius = 135,
				OrbitRadius = 1380,
				OrbitSpeed = 0.065,
				OrbitTilt = math.rad(8),
				Phase = 0.9,
				Color = Color3.fromRGB(215, 168, 88),
				CrateColor = Color3.fromRGB(155, 115, 52),
				Walkable = true,
				SurfaceGravity = 38,
			},
			{
				Id = "Encelad",
				Name = "Encélado",
				Radius = 92,
				OrbitRadius = 1720,
				OrbitSpeed = 0.045,
				OrbitTilt = math.rad(-10),
				Phase = 4.1,
				Color = Color3.fromRGB(210, 240, 255),
				CrateColor = Color3.fromRGB(145, 195, 230),
				Walkable = true,
				SurfaceGravity = 28,
			},
		},
	},
	{
		Id = "Cryon",
		Name = "Cryon V",
		Type = "Ice",
		Radius = 330,
		OrbitMajor = 8500,
		OrbitMinor = 7950,
		OrbitSpeed = 0.0055,
		OrbitTilt = math.rad(-12),
		Phase = 4.7,
		RotSpeed = 0.09,
		Color = Color3.fromRGB(130, 215, 250),
		SecondaryColor = Color3.fromRGB(210, 248, 255),
		AtmosphereColor = Color3.fromRGB(155, 235, 255),
		HasAtmosphere = true,
		Walkable = true,
		SurfaceGravity = 60,
		Moons = {
			{
				Id = "Glacies",
				Name = "Glacies",
				Radius = 88,
				OrbitRadius = 560,
				OrbitSpeed = 0.10,
				OrbitTilt = math.rad(15),
				Phase = 2.1,
				Color = Color3.fromRGB(185, 230, 250),
				CrateColor = Color3.fromRGB(125, 175, 205),
				Walkable = true,
				SurfaceGravity = 27,
			},
		},
	},
	{
		Id = "Vulcanis",
		Name = "Obsidian (Lava)",
		Type = "Lava",
		Radius = 310,
		OrbitMajor = 1650,
		OrbitMinor = 1480,
		OrbitSpeed = 0.027,
		OrbitTilt = math.rad(14),
		Phase = 5.4,
		RotSpeed = 0.06,
		Color = Color3.fromRGB(28, 24, 30),
		SecondaryColor = Color3.fromRGB(255, 95, 15),
		AtmosphereColor = Color3.fromRGB(255, 80, 20),
		HasAtmosphere = false,
		Walkable = true,
		SurfaceGravity = 68,
		Moons = {},
	},
}

Config.Auras = {
	{ Id = 1, Name = "Stardust Whisper", Rarity = 1, Chance = 2, Primary = Color3.fromRGB(190, 215, 230), Secondary = Color3.fromRGB(120, 155, 180), Rings = 1, Orbs = 2, Speed = 1.2, Scale = 1.0, Style = "Dust" },
	{ Id = 2, Name = "Orbital Breeze", Rarity = 1, Chance = 3, Primary = Color3.fromRGB(155, 225, 245), Secondary = Color3.fromRGB(90, 175, 210), Rings = 1, Orbs = 3, Speed = 1.5, Scale = 1.0, Style = "Orbit" },
	{ Id = 3, Name = "Lunar Glimmer", Rarity = 1, Chance = 4, Primary = Color3.fromRGB(220, 225, 240), Secondary = Color3.fromRGB(150, 160, 195), Rings = 1, Orbs = 4, Speed = 1.4, Scale = 1.05, Style = "Halo" },
	{ Id = 4, Name = "Meteor Spark", Rarity = 2, Chance = 5, Primary = Color3.fromRGB(255, 160, 75), Secondary = Color3.fromRGB(205, 85, 35), Rings = 1, Orbs = 4, Speed = 1.8, Scale = 1.1, Style = "Flame" },
	{ Id = 5, Name = "Ion Cascade", Rarity = 2, Chance = 8, Primary = Color3.fromRGB(70, 245, 155), Secondary = Color3.fromRGB(25, 165, 110), Rings = 2, Orbs = 4, Speed = 2.0, Scale = 1.15, Style = "Helix" },
	{ Id = 6, Name = "Aurora Veil", Rarity = 2, Chance = 12, Primary = Color3.fromRGB(85, 250, 205), Secondary = Color3.fromRGB(145, 110, 255), Rings = 2, Orbs = 5, Speed = 1.7, Scale = 1.2, Style = "Curtain" },
	{ Id = 7, Name = "Comet Tail", Rarity = 3, Chance = 20, Primary = Color3.fromRGB(95, 195, 255), Secondary = Color3.fromRGB(220, 248, 255), Rings = 2, Orbs = 6, Speed = 2.3, Scale = 1.25, Style = "Star" },
	{ Id = 8, Name = "Solar Flare", Rarity = 3, Chance = 35, Primary = Color3.fromRGB(255, 195, 45), Secondary = Color3.fromRGB(255, 80, 20), Rings = 2, Orbs = 6, Speed = 2.6, Scale = 1.3, Style = "Crown" },
	{ Id = 9, Name = "Cryo Nova", Rarity = 3, Chance = 50, Primary = Color3.fromRGB(125, 235, 255), Secondary = Color3.fromRGB(50, 130, 255), Rings = 3, Orbs = 6, Speed = 2.2, Scale = 1.3, Style = "Crystal" },
	{ Id = 10, Name = "Magnetar Pulse", Rarity = 3, Chance = 75, Primary = Color3.fromRGB(90, 155, 255), Secondary = Color3.fromRGB(255, 90, 215), Rings = 3, Orbs = 7, Speed = 2.8, Scale = 1.35, Style = "Lightning" },
	{ Id = 11, Name = "Nebula Heart", Rarity = 4, Chance = 100, Primary = Color3.fromRGB(215, 85, 255), Secondary = Color3.fromRGB(75, 195, 255), Rings = 3, Orbs = 8, Speed = 2.5, Scale = 1.45, Style = "Nebula" },
	{ Id = 12, Name = "Void Walker", Rarity = 4, Chance = 220, Primary = Color3.fromRGB(125, 45, 225), Secondary = Color3.fromRGB(25, 10, 45), Rings = 3, Orbs = 8, Speed = 3.0, Scale = 1.5, Style = "Void" },
	{ Id = 13, Name = "Plasma Tempest", Rarity = 4, Chance = 450, Primary = Color3.fromRGB(255, 65, 185), Secondary = Color3.fromRGB(80, 240, 255), Rings = 4, Orbs = 9, Speed = 3.4, Scale = 1.55, Style = "Storm" },
	{ Id = 14, Name = "Starlight Seraph", Rarity = 4, Chance = 750, Primary = Color3.fromRGB(255, 245, 185), Secondary = Color3.fromRGB(130, 220, 255), Rings = 4, Orbs = 10, Speed = 2.9, Scale = 1.6, Style = "Wings" },
	{ Id = 15, Name = "Pulsar Storm", Rarity = 5, Chance = 1000, Primary = Color3.fromRGB(255, 205, 55), Secondary = Color3.fromRGB(255, 110, 30), Rings = 4, Orbs = 10, Speed = 3.8, Scale = 1.7, Style = "Pulsar" },
	{ Id = 16, Name = "Supernova Remnant", Rarity = 5, Chance = 2500, Primary = Color3.fromRGB(255, 140, 40), Secondary = Color3.fromRGB(165, 65, 255), Rings = 5, Orbs = 12, Speed = 4.0, Scale = 1.8, Style = "Supernova" },
	{ Id = 17, Name = "Astral Sovereign", Rarity = 5, Chance = 6000, Primary = Color3.fromRGB(255, 220, 95), Secondary = Color3.fromRGB(70, 245, 255), Rings = 5, Orbs = 12, Speed = 4.2, Scale = 1.85, Style = "Throne" },
	{ Id = 18, Name = "Quasar Crown", Rarity = 6, Chance = 10000, Primary = Color3.fromRGB(255, 55, 95), Secondary = Color3.fromRGB(255, 215, 80), Rings = 5, Orbs = 14, Speed = 4.6, Scale = 1.95, Style = "Quasar" },
	{ Id = 19, Name = "Accretion Abyss", Rarity = 6, Chance = 35000, Primary = Color3.fromRGB(255, 120, 30), Secondary = Color3.fromRGB(20, 10, 35), Rings = 6, Orbs = 15, Speed = 5.0, Scale = 2.05, Style = "BlackHole" },
	{ Id = 20, Name = "Galactic Weaver", Rarity = 6, Chance = 120000, Primary = Color3.fromRGB(255, 70, 165), Secondary = Color3.fromRGB(95, 255, 230), Rings = 6, Orbs = 16, Speed = 5.2, Scale = 2.15, Style = "Galaxy" },
	{ Id = 21, Name = "Event Horizon", Rarity = 7, Chance = 500000, Primary = Color3.fromRGB(95, 250, 255), Secondary = Color3.fromRGB(255, 95, 220), Rings = 7, Orbs = 18, Speed = 5.8, Scale = 2.3, Style = "Singularity" },
	{ Id = 22, Name = "ARCHITECT OF COSMOS", Rarity = 7, Chance = 1000000, Primary = Color3.fromRGB(135, 255, 255), Secondary = Color3.fromRGB(255, 215, 90), Rings = 8, Orbs = 20, Speed = 6.4, Scale = 2.5, Style = "Genesis" },
}

Config.Weapons = {
	{
		Id = "PulseRifle",
		Name = "Rifle de Pulso VX-9",
		Damage = 24,
		FireRate = 0.11,
		MagSize = 32,
		ReserveMax = 192,
		ReloadTime = 1.55,
		SpreadBase = 0.008,
		SpreadMove = 0.018,
		SpreadFire = 0.006,
		RecoilKick = 0.045,
		Range = 950,
		Color = Color3.fromRGB(0, 230, 255),
		Auto = true,
	},
	{
		Id = "PlasmaPistol",
		Name = "Pistola de Plasma Ion-4",
		Damage = 42,
		FireRate = 0.24,
		MagSize = 12,
		ReserveMax = 96,
		ReloadTime = 1.15,
		SpreadBase = 0.005,
		SpreadMove = 0.012,
		SpreadFire = 0.008,
		RecoilKick = 0.065,
		Range = 700,
		Color = Color3.fromRGB(80, 255, 155),
		Auto = false,
	},
	{
		Id = "SingularityCannon",
		Name = "Canhão Quasar X-1",
		Damage = 115,
		FireRate = 0.72,
		MagSize = 6,
		ReserveMax = 36,
		ReloadTime = 2.1,
		SpreadBase = 0.002,
		SpreadMove = 0.010,
		SpreadFire = 0.015,
		RecoilKick = 0.12,
		Range = 1400,
		Color = Color3.fromRGB(255, 110, 220),
		Auto = false,
		ExplosiveRadius = 26,
	},
}

Config.Enemies = {
	Scout = {
		Name = "Drone Scout",
		MaxHealth = 85,
		Speed = 62,
		DetectRange = 360,
		AttackRange = 220,
		FireInterval = 1.05,
		ProjectileSpeed = 190,
		Damage = 8,
		Radius = 4.2,
		Color = Color3.fromRGB(0, 215, 255),
		EyeColor = Color3.fromRGB(255, 210, 60),
		XP = 35,
	},
	Gunner = {
		Name = "Drone Gunner",
		MaxHealth = 165,
		Speed = 46,
		DetectRange = 420,
		AttackRange = 280,
		FireInterval = 0.45,
		BurstCount = 3,
		ProjectileSpeed = 230,
		Damage = 11,
		Radius = 5.6,
		Color = Color3.fromRGB(255, 130, 40),
		EyeColor = Color3.fromRGB(255, 50, 65),
		XP = 65,
	},
	Heavy = {
		Name = "Drone Heavy",
		MaxHealth = 320,
		Shield = 120,
		Speed = 30,
		DetectRange = 480,
		AttackRange = 340,
		FireInterval = 1.65,
		ProjectileSpeed = 155,
		Homing = true,
		Damage = 22,
		Radius = 7.8,
		Color = Color3.fromRGB(165, 75, 255),
		EyeColor = Color3.fromRGB(255, 65, 180),
		XP = 120,
	},
	Boss = {
		Name = "Guardião Estelar",
		MaxHealth = 2200,
		Shield = 600,
		Speed = 38,
		DetectRange = 800,
		AttackRange = 540,
		FireInterval = 0.85,
		ProjectileSpeed = 240,
		Homing = true,
		Damage = 28,
		Radius = 18,
		Color = Color3.fromRGB(255, 200, 60),
		EyeColor = Color3.fromRGB(90, 250, 255),
		XP = 800,
		IsBoss = true,
	},
}

Config.HotbarItems = {
	{ Slot = 1, Id = "FlightSuit", Name = "Propulsor", Icon = "🚀", Desc = "Ativa/Desativa voo Superman" },
	{ Slot = 2, Id = "PulseRifle", Name = "Rifle VX-9", Icon = "🔫", Desc = "Rifle automático de pulso" },
	{ Slot = 3, Id = "PlasmaPistol", Name = "Pistola Ion", Icon = "⚡", Desc = "Pistola de plasma precisa" },
	{ Slot = 4, Id = "SingularityCannon", Name = "Canhão X-1", Icon = "💥", Desc = "Canhão pesado explosivo" },
	{ Slot = 5, Id = "Scanner", Name = "Scanner", Icon = "📡", Desc = "Escaneia planetas e minérios" },
	{ Slot = 6, Id = "AuraRoller", Name = "Orbe RNG", Icon = "✨", Desc = "Abre o altar de Auras Cósmicas" },
	{ Slot = 7, Id = "HyperBoost", Name = "Injetor", Icon = "🔥", Desc = "Recarrega stamina e escudo" },
	{ Slot = 8, Id = "StarMap", Name = "Mapa Estelar", Icon = "🪐", Desc = "Navegação e teleporte orbital" },
	{ Slot = 9, Id = "Settings", Name = "Sistemas", Icon = "⚙️", Desc = "Qualidade, áudio e missões" },
}

local Util = {}
Util.UniverseRng = Random.new(20261107)
Util.FxRng = Random.new()

function Util.Clamp(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

function Util.Lerp(a, b, t)
	return a + (b - a) * t
end

function Util.LerpColor(c1, c2, t)
	return c1:Lerp(c2, Util.Clamp(t, 0, 1))
end

function Util.SmoothStep(edge0, edge1, x)
	local t = Util.Clamp((x - edge0) / math.max(0.0001, edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

function Util.ExpDecay(current, target, speed, dt)
	return target + (current - target) * math.exp(-speed * dt)
end

function Util.ExpDecayVec3(current, target, speed, dt)
	local f = math.exp(-speed * dt)
	return target + (current - target) * f
end

function Util.FormatInt(n)
	local s = tostring(math.floor(n + 0.5))
	local left, num, right = string.match(s, "^([^%d]*%d)(%d*)(.-)$")
	return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

function Util.Tween(inst, info, props)
	local tw = Services.TweenService:Create(inst, info, props)
	tw:Play()
	return tw
end

-- Maid: Gerenciador de Conexões e Instâncias
local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(taskItem)
	if taskItem ~= nil then
		table.insert(self._tasks, taskItem)
	end
	return taskItem
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		local item = tasks[i]
		local t = typeof(item)
		if t == "RBXScriptConnection" then
			pcall(function() item:Disconnect() end)
		elseif t == "Instance" then
			pcall(function() item:Destroy() end)
		elseif t == "function" then
			pcall(item)
		elseif t == "table" and item.Destroy then
			pcall(function() item:Destroy() end)
		elseif t == "table" and item.Clean then
			pcall(function() item:Clean() end)
		end
	end
end

function Maid:Destroy()
	self:Clean()
end

Util.Maid = Maid
Cosmos.RootMaid = Maid.new()

-- Signal leve
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(fn)
	local entry = { fn = fn, connected = true }
	table.insert(self._listeners, entry)
	local sig = self
	return {
		Connected = true,
		Disconnect = function(conn)
			conn.Connected = false
			entry.connected = false
			for i = #sig._listeners, 1, -1 do
				if sig._listeners[i] == entry then
					table.remove(sig._listeners, i)
					break
				end
			end
		end,
	}
end

function Signal:Fire(...)
	local snapshot = table.clone(self._listeners)
	for i = 1, #snapshot do
		local entry = snapshot[i]
		if entry.connected then
			task.spawn(entry.fn, ...)
		end
	end
end

function Signal:Destroy()
	table.clear(self._listeners)
end

Util.Signal = Signal

-- Spring: Mola criticamente amortecida (1D e Vector3)
local Spring = {}
Spring.__index = Spring

function Spring.new(initial, speed, damper)
	return setmetatable({
		Position = initial,
		Velocity = initial * 0,
		Target = initial,
		Speed = speed or 14,
		Damper = damper or 1,
	}, Spring)
end

function Spring:Impulse(vel)
	self.Velocity = self.Velocity + vel
end

function Spring:Update(dt)
	local step = math.min(dt, 0.05)
	local w = self.Speed
	local d = self.Damper
	local accel = -w * w * (self.Position - self.Target) - 2 * d * w * self.Velocity
	self.Velocity = self.Velocity + accel * step
	self.Position = self.Position + self.Velocity * step
	return self.Position
end

Util.Spring = Spring

-- Pool de Parts Reutilizáveis (Zero Instance.new em loops por frame)
local Pool = {}
Pool.__index = Pool

function Pool.new(factoryFn, resetFn, prewarmCount)
	local self = setmetatable({
		_factory = factoryFn,
		_reset = resetFn,
		_free = {},
		_active = {},
	}, Pool)
	for _ = 1, (prewarmCount or 0) do
		local item = self._factory()
		if self._reset then
			self._reset(item, false)
		end
		table.insert(self._free, item)
	end
	return self
end

function Pool:Acquire()
	local item = table.remove(self._free)
	if not item then
		item = self._factory()
	end
	self._active[item] = true
	if self._reset then
		self._reset(item, true)
	end
	return item
end

function Pool:Release(item)
	if not self._active[item] then
		return
	end
	self._active[item] = nil
	if self._reset then
		self._reset(item, false)
	end
	table.insert(self._free, item)
end

function Pool:Destroy()
	for item in pairs(self._active) do
		if typeof(item) == "Instance" then
			pcall(function() item:Destroy() end)
		end
	end
	for i = 1, #self._free do
		local item = self._free[i]
		if typeof(item) == "Instance" then
			pcall(function() item:Destroy() end)
		end
	end
	table.clear(self._active)
	table.clear(self._free)
end

Util.Pool = Pool

-- Helper de criação de Part decorativa otimizada
function Util.MakePart(props)
	local part = Instance.new(props.ClassName or "Part")
	part.Name = props.Name or "CosmosPart"
	part.Anchored = (props.Anchored ~= false)
	part.CanCollide = (props.CanCollide == true)
	part.CanQuery = (props.CanQuery == true)
	part.CanTouch = (props.CanTouch == true)
	part.CastShadow = (props.CastShadow == true)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Color = props.Color or Color3.new(1, 1, 1)
	part.Transparency = props.Transparency or 0
	if props.Shape and part:IsA("Part") then
		part.Shape = props.Shape
	end
	local sz = props.Size or Vector3.new(4, 4, 4)
	part.Size = Vector3.new(
		math.min(sz.X, 2048),
		math.min(sz.Y, 2048),
		math.min(sz.Z, 2048)
	)
	if props.CFrame then
		part.CFrame = props.CFrame
	elseif props.Position then
		part.Position = props.Position
	end
	if props.Parent then
		part.Parent = props.Parent
	end
	Cosmos.ActivePartsCount = Cosmos.ActivePartsCount + 1
	part.Destroying:Connect(function()
		Cosmos.ActivePartsCount = math.max(0, Cosmos.ActivePartsCount - 1)
	end)
	return part
end

function Util.CreateUI(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

function Util.AddStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Config.Theme.StrokeCyan
	stroke.Thickness = thickness or 1.2
	stroke.Transparency = transparency or 0.25
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function Util.AddCorner(parent, radiusPx)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radiusPx or 6)
	corner.Parent = parent
	return corner
end

Cosmos.Util = Util
Cosmos.Config = Config

--==============================================================================
-- [SEÇÃO 02] UNIVERSE (SISTEMA SOLAR VIVO, PLANETAS, LUAS, ESTRELAS, COMETAS)
--==============================================================================
-- Truque de Iluminação Solar nos Planetas:
-- Como o Lighting do Roblox é direcional global, cada planeta possui uma
-- esfera "TerminatorShadow" levemente maior (Radius * 1.015), preta com
-- Transparency = 0.36, deslocada 12% do raio na direção oposta ao Sol
-- (unitVec de SunPos -> PlanetPos). Isso cria um hemisfério diurno iluminado
-- voltado para o Sol e um hemisfério noturno escuro realista. Na Nova Terra,
-- as luzes das cidades usam produto escalar: dot(normalDaCidade, dirProSol) < -0.08
-- para acenderem apenas no lado noturno!
--==============================================================================

local Universe = {
	Maid = Maid.new(),
	RootFolder = nil,
	StarShellFolder = nil,
	SunData = nil,
	Planets = {},
	AllBodies = {},
	BodyById = {},
	Stars = {},
	StarTwinkleBatch = 1,
	Asteroids = {},
	Comet = nil,
	CometTimer = 0,
}

function Universe:Init()
	local folder = Instance.new("Folder")
	folder.Name = "CosmosOdyssey_Universe"
	folder.Parent = Services.Workspace
	self.RootFolder = self.Maid:Give(folder)

	local starFolder = Instance.new("Folder")
	starFolder.Name = "Cosmos_StarShell"
	starFolder.Parent = folder
	self.StarShellFolder = starFolder

	self:BuildSun()
	self:BuildNebulae()
	self:BuildStarShell()
	self:BuildPlanetsAndMoons()
	self:BuildAsteroidBelt()
	self:BuildComet()
end

function Universe:BuildSun()
	local center = Config.UniverseCenter
	local r = Config.SunRadius
	local sunModel = Instance.new("Model")
	sunModel.Name = "Solaris_Sun"
	sunModel.Parent = self.RootFolder

	local core = Util.MakePart({
		Name = "SunCore",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 95),
		Size = Vector3.new(r * 2, r * 2, r * 2),
		Position = center,
		Parent = sunModel,
	})
	sunModel.PrimaryPart = core

	local coronaInner = Util.MakePart({
		Name = "CoronaInner",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 145, 35),
		Transparency = 0.58,
		Size = Vector3.new(r * 2.18, r * 2.18, r * 2.18),
		Position = center,
		Parent = sunModel,
	})

	local coronaOuter = Util.MakePart({
		Name = "CoronaOuter",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 85, 20),
		Transparency = 0.78,
		Size = Vector3.new(r * 2.42, r * 2.42, r * 2.42),
		Position = center,
		Parent = sunModel,
	})

	local rays = {}
	for i = 1, 14 do
		local angle1 = (i / 14) * math.pi * 2
		local angle2 = ((i * 7) % 14 / 14) * math.pi - math.pi * 0.5
		local ray = Util.MakePart({
			Name = "SolarRay_" .. i,
			Material = Enum.Material.Neon,
			Color = (i % 2 == 0) and Color3.fromRGB(255, 195, 70) or Color3.fromRGB(255, 120, 35),
			Transparency = 0.45,
			Size = Vector3.new(28, 28, r * 2.65),
			CFrame = CFrame.new(center) * CFrame.Angles(angle1, angle2, i * 0.4),
			Parent = sunModel,
		})
		table.insert(rays, { Part = ray, BaseAngles = Vector3.new(angle1, angle2, i * 0.4), Speed = (i % 2 == 0 and 1 or -1) * (0.04 + i * 0.003) })
	end

	self.SunData = {
		Model = sunModel,
		Core = core,
		CoronaInner = coronaInner,
		CoronaOuter = coronaOuter,
		Rays = rays,
		Position = center,
		Radius = r,
	}

	local sunEntry = {
		Id = "Solaris",
		Name = "Estrela Solaris",
		Type = "Sun",
		Radius = r,
		Position = center,
		Color = Color3.fromRGB(255, 205, 70),
		Walkable = false,
		HasAtmosphere = false,
	}
	table.insert(self.AllBodies, sunEntry)
	self.BodyById["Solaris"] = sunEntry
end

function Universe:BuildNebulae()
	local nebFolder = Instance.new("Folder")
	nebFolder.Name = "Nebulae"
	nebFolder.Parent = self.RootFolder
	local palette = {
		Color3.fromRGB(145, 55, 235),
		Color3.fromRGB(45, 145, 255),
		Color3.fromRGB(235, 65, 165),
		Color3.fromRGB(40, 225, 205),
	}
	local rng = Util.UniverseRng
	for i = 1, Config.NebulaClouds do
		local theta = rng:NextNumber(0, math.pi * 2)
		local phi = rng:NextNumber(-0.65, 0.65)
		local dist = rng:NextNumber(11500, 15500)
		local dir = Vector3.new(
			math.cos(phi) * math.cos(theta),
			math.sin(phi),
			math.cos(phi) * math.sin(theta)
		)
		local pos = Config.UniverseCenter + dir * dist
		local col = palette[(i % #palette) + 1]
		for j = 1, 3 do
			local offset = Vector3.new(
				rng:NextNumber(-600, 600),
				rng:NextNumber(-350, 350),
				rng:NextNumber(-600, 600)
			)
			Util.MakePart({
				Name = "NebulaCloud_" .. i .. "_" .. j,
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = col,
				Transparency = 0.88 + j * 0.025,
				Size = Vector3.new(
					rng:NextNumber(1100, 1950),
					rng:NextNumber(650, 1300),
					rng:NextNumber(1100, 1950)
				),
				Position = pos + offset,
				Parent = nebFolder,
			})
		end
	end
end

function Universe:BuildStarShell()
	for i = 1, #self.Stars do
		if self.Stars[i].Part then
			self.Stars[i].Part:Destroy()
		end
	end
	table.clear(self.Stars)

	local count = Config.StarCountHigh
	if Cosmos.QualityLevel == 2 then
		count = Config.StarCountMed
	elseif Cosmos.QualityLevel == 1 then
		count = Config.StarCountLow
	end

	local starColors = {
		Color3.fromRGB(255, 252, 245),
		Color3.fromRGB(175, 215, 255),
		Color3.fromRGB(255, 220, 175),
	}
	local rng = Util.UniverseRng
	local shellRadius = 1850
	for i = 1, count do
		local u = rng:NextNumber(-1, 1)
		local theta = rng:NextNumber(0, math.pi * 2)
		local s = math.sqrt(math.max(0, 1 - u * u))
		local unitDir = Vector3.new(s * math.cos(theta), u, s * math.sin(theta))
		local sz = rng:NextNumber(2.8, 7.5)
		local col = starColors[(i % 3) + 1]
		local part = Util.MakePart({
			Name = "Star_" .. i,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = col,
			Transparency = 1,
			Size = Vector3.new(sz, sz, sz),
			Position = unitDir * shellRadius,
			Parent = self.StarShellFolder,
		})
		table.insert(self.Stars, {
			Part = part,
			Offset = unitDir * shellRadius,
			BaseAlpha = rng:NextNumber(0.04, 0.35),
			TwinklePhase = rng:NextNumber(0, math.pi * 2),
		})
	end
end

function Universe:BuildPlanetsAndMoons()
	local rng = Util.UniverseRng
	for _, bCfg in ipairs(Config.Bodies) do
		local pModel = Instance.new("Model")
		pModel.Name = bCfg.Name
		pModel.Parent = self.RootFolder

		local r = bCfg.Radius
		local core = Util.MakePart({
			Name = "SurfaceCore",
			Shape = Enum.PartType.Ball,
			Material = bCfg.Type == "Lava" and Enum.Material.Slate or Enum.Material.SmoothPlastic,
			Color = bCfg.Color,
			Size = Vector3.new(r * 2, r * 2, r * 2),
			Position = Config.UniverseCenter + Vector3.new(bCfg.OrbitMajor, 0, 0),
			Parent = pModel,
		})
		pModel.PrimaryPart = core

		-- Esfera de Sombra Direcional (oposta ao Sol)
		local shadowBall = Util.MakePart({
			Name = "TerminatorShadow",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(4, 6, 12),
			Transparency = 0.36,
			Size = Vector3.new(r * 2.025, r * 2.025, r * 2.025),
			Position = core.Position,
			Parent = pModel,
		})

		local atmoGlow = nil
		if bCfg.HasAtmosphere then
			atmoGlow = Util.MakePart({
				Name = "AtmosphereHalo",
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = bCfg.AtmosphereColor,
				Transparency = 0.82,
				Size = Vector3.new(r * 2.11, r * 2.11, r * 2.11),
				Position = core.Position,
				Parent = pModel,
			})
		end

		local localFeatures = {}
		local cityLights = {}
		local cloudLayer = nil
		local ringModels = {}
		local lavaCracks = {}

		if bCfg.Type == "Terra" then
			-- Continentes semi-embutidos
			for c = 1, 16 do
				local lat = rng:NextNumber(-1.1, 1.1)
				local lon = rng:NextNumber(0, math.pi * 2)
				local nDir = Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
				local blobSize = r * rng:NextNumber(0.32, 0.56)
				local cont = Util.MakePart({
					Name = "Continent_" .. c,
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.Grass,
					Color = (c % 3 == 0) and Color3.fromRGB(125, 110, 75) or bCfg.SecondaryColor,
					Size = Vector3.new(blobSize, blobSize * 0.65, blobSize),
					Parent = pModel,
				})
				table.insert(localFeatures, {
					Part = cont,
					LocalNormal = nDir,
					Depth = r * 0.84,
				})

				-- Luzes de cidade no centro dos continentes (aparecem no lado noturno)
				for k = 1, 2 do
					local lDir = (nDir + Vector3.new(rng:NextNumber(-0.14, 0.14), rng:NextNumber(-0.14, 0.14), rng:NextNumber(-0.14, 0.14))).Unit
					local lightPart = Util.MakePart({
						Name = "CityLight_" .. c .. "_" .. k,
						Shape = Enum.PartType.Ball,
						Material = Enum.Material.Neon,
						Color = Color3.fromRGB(255, 210, 95),
						Transparency = 1,
						Size = Vector3.new(12, 12, 12),
						Parent = pModel,
					})
					table.insert(cityLights, {
						Part = lightPart,
						LocalNormal = lDir,
						Dist = r * 1.008,
					})
				end
			end

			-- Camada de nuvens independente
			cloudLayer = Instance.new("Model")
			cloudLayer.Name = "CloudLayer"
			cloudLayer.Parent = pModel
			local cloudHub = Util.MakePart({
				Name = "CloudHub",
				Transparency = 1,
				Size = Vector3.new(2, 2, 2),
				Position = core.Position,
				Parent = cloudLayer,
			})
			cloudLayer.PrimaryPart = cloudHub
			for cl = 1, 18 do
				local lat = rng:NextNumber(-1.2, 1.2)
				local lon = rng:NextNumber(0, math.pi * 2)
				local nDir = Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
				local cPart = Util.MakePart({
					Name = "CloudPatch_" .. cl,
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.SmoothPlastic,
					Color = Color3.fromRGB(245, 250, 255),
					Transparency = 0.42,
					Size = Vector3.new(r * 0.45, r * 0.14, r * 0.35),
					CFrame = CFrame.lookAt(core.Position + nDir * (r * 1.03), core.Position + nDir * (r * 2)),
					Parent = cloudLayer,
				})
				cPart.CFrame = cPart.CFrame * CFrame.Angles(math.pi * 0.5, 0, 0)
			end
		elseif bCfg.Type == "Mars" then
			-- Calotas polares + crateras marcianas
			for pole = -1, 1, 2 do
				local nDir = Vector3.new(0, pole, 0)
				local cap = Util.MakePart({
					Name = "PolarCap_" .. pole,
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.Ice,
					Color = bCfg.SecondaryColor,
					Size = Vector3.new(r * 0.72, r * 0.28, r * 0.72),
					Parent = pModel,
				})
				table.insert(localFeatures, { Part = cap, LocalNormal = nDir, Depth = r * 0.90 })
			end
			for cr = 1, 12 do
				local lat = rng:NextNumber(-0.9, 0.9)
				local lon = rng:NextNumber(0, math.pi * 2)
				local nDir = Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
				local crater = Util.MakePart({
					Name = "MarsCrater_" .. cr,
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.Slate,
					Color = Color3.fromRGB(135, 50, 28),
					Size = Vector3.new(r * 0.32, r * 0.22, r * 0.32),
					Parent = pModel,
				})
				table.insert(localFeatures, { Part = crater, LocalNormal = nDir, Depth = r * 0.91 })
			end
		elseif bCfg.Type == "GasGiant" then
			-- Bandas coloridas atmosféricas
			local bandOffsets = { -0.58, -0.28, 0, 0.28, 0.58 }
			for bi, yFrac in ipairs(bandOffsets) do
				local sliceR = math.sqrt(math.max(0.1, 1 - yFrac * yFrac)) * r * 2.03
				local band = Util.MakePart({
					Name = "GasBand_" .. bi,
					Shape = Enum.PartType.Cylinder,
					Material = Enum.Material.SmoothPlastic,
					Color = (bi % 2 == 0) and bCfg.SecondaryColor or Color3.fromRGB(238, 198, 145),
					Size = Vector3.new(r * 0.22, sliceR, sliceR),
					Parent = pModel,
				})
				table.insert(localFeatures, {
					Part = band,
					LocalNormal = Vector3.new(0, yFrac, 0),
					Depth = r,
					IsBand = true,
				})
			end

			-- Anéis em 2 camadas (rochas + poeira translúcida)
			for layer = 1, 2 do
				local ringModel = Instance.new("Model")
				ringModel.Name = "RingLayer_" .. layer
				ringModel.Parent = pModel
				local hub = Util.MakePart({
					Name = "RingHub",
					Transparency = 1,
					Size = Vector3.new(2, 2, 2),
					Position = core.Position,
					Parent = ringModel,
				})
				ringModel.PrimaryPart = hub
				local segCount = (layer == 1) and 32 or 24
				local radiusRing = (layer == 1) and ((bCfg.RingInner + bCfg.RingOuter) * 0.46) or ((bCfg.RingInner + bCfg.RingOuter) * 0.56)
				for s = 1, segCount do
					local ang = (s / segCount) * math.pi * 2
					local rDist = radiusRing + rng:NextNumber(-55, 55)
					local lPos = Vector3.new(math.cos(ang) * rDist, rng:NextNumber(-8, 8), math.sin(ang) * rDist)
					Util.MakePart({
						Name = "RingRock_" .. s,
						Material = (layer == 1) and Enum.Material.Rock or Enum.Material.Neon,
						Color = (layer == 1) and Color3.fromRGB(195, 175, 145) or Color3.fromRGB(235, 205, 155),
						Transparency = (layer == 1) and 0.15 or 0.65,
						Size = (layer == 1) and Vector3.new(45, 10, 95) or Vector3.new(90, 4, 155),
						CFrame = CFrame.new(core.Position + lPos) * CFrame.Angles(0, -ang, 0),
						Parent = ringModel,
					})
				end
				table.insert(ringModels, {
					Model = ringModel,
					Tilt = CFrame.Angles(math.rad(18), 0, math.rad(14)),
					Speed = (layer == 1) and 0.04 or -0.025,
					Angle = 0,
				})
			end
		elseif bCfg.Type == "Ice" then
			-- Cristais de gelo emergindo da superfície
			for cr = 1, 16 do
				local lat = rng:NextNumber(-1.2, 1.2)
				local lon = rng:NextNumber(0, math.pi * 2)
				local nDir = Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
				local spike = Util.MakePart({
					Name = "IceCrystal_" .. cr,
					Material = Enum.Material.Neon,
					Color = bCfg.SecondaryColor,
					Transparency = 0.22,
					Size = Vector3.new(26, 95, 26),
					Parent = pModel,
				})
				table.insert(localFeatures, {
					Part = spike,
					LocalNormal = nDir,
					Depth = r * 1.04,
					AlignRadial = true,
				})
			end
		elseif bCfg.Type == "Lava" then
			-- Rachaduras de magma Neon que pulsam
			for lv = 1, 18 do
				local lat = rng:NextNumber(-1.2, 1.2)
				local lon = rng:NextNumber(0, math.pi * 2)
				local nDir = Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
				local crack = Util.MakePart({
					Name = "LavaVein_" .. lv,
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.Neon,
					Color = bCfg.SecondaryColor,
					Size = Vector3.new(r * 0.42, r * 0.12, r * 0.16),
					Parent = pModel,
				})
				table.insert(localFeatures, { Part = crack, LocalNormal = nDir, Depth = r * 0.96, AlignRadial = true })
				table.insert(lavaCracks, crack)
			end
		end

		local planetData = {
			Config = bCfg,
			Id = bCfg.Id,
			Name = bCfg.Name,
			Type = bCfg.Type,
			Radius = r,
			Color = bCfg.Color,
			Walkable = bCfg.Walkable,
			HasAtmosphere = bCfg.HasAtmosphere,
			SurfaceGravity = bCfg.SurfaceGravity,
			Model = pModel,
			Core = core,
			Shadow = shadowBall,
			AtmoGlow = atmoGlow,
			Features = localFeatures,
			CityLights = cityLights,
			CloudLayer = cloudLayer,
			CloudAngle = 0,
			RingModels = ringModels,
			LavaCracks = lavaCracks,
			OrbitAngle = bCfg.Phase,
			RotationAngle = 0,
			Position = core.Position,
			Moons = {},
		}

		-- Construir Luas
		for _, mCfg in ipairs(bCfg.Moons or {}) do
			local mModel = Instance.new("Model")
			mModel.Name = mCfg.Name
			mModel.Parent = self.RootFolder
			local mr = mCfg.Radius
			local mCore = Util.MakePart({
				Name = "MoonCore",
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Slate,
				Color = mCfg.Color,
				Size = Vector3.new(mr * 2, mr * 2, mr * 2),
				Position = core.Position + Vector3.new(mCfg.OrbitRadius, 0, 0),
				Parent = mModel,
			})
			mModel.PrimaryPart = mCore

			local mShadow = Util.MakePart({
				Name = "MoonShadow",
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(4, 6, 12),
				Transparency = 0.38,
				Size = Vector3.new(mr * 2.03, mr * 2.03, mr * 2.03),
				Position = mCore.Position,
				Parent = mModel,
			})

			local mCraters = {}
			for cr = 1, 10 do
				local lat = rng:NextNumber(-1.15, 1.15)
				local lon = rng:NextNumber(0, math.pi * 2)
				local nDir = Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
				local crater = Util.MakePart({
					Name = "MoonCrater_" .. cr,
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.Rock,
					Color = mCfg.CrateColor,
					Size = Vector3.new(mr * 0.34, mr * 0.22, mr * 0.34),
					Parent = mModel,
				})
				table.insert(mCraters, { Part = crater, LocalNormal = nDir, Depth = mr * 0.90 })
			end

			local moonEntry = {
				Config = mCfg,
				Id = mCfg.Id,
				Name = mCfg.Name,
				Type = "Moon",
				ParentPlanet = planetData,
				Radius = mr,
				Color = mCfg.Color,
				Walkable = mCfg.Walkable,
				HasAtmosphere = false,
				SurfaceGravity = mCfg.SurfaceGravity,
				Model = mModel,
				Core = mCore,
				Shadow = mShadow,
				Features = mCraters,
				OrbitAngle = mCfg.Phase,
				RotationAngle = 0,
				Position = mCore.Position,
			}
			table.insert(planetData.Moons, moonEntry)
			table.insert(self.AllBodies, moonEntry)
			self.BodyById[mCfg.Id] = moonEntry
		end

		table.insert(self.Planets, planetData)
		table.insert(self.AllBodies, planetData)
		self.BodyById[bCfg.Id] = planetData
	end
end

function Universe:BuildAsteroidBelt()
	local beltFolder = Instance.new("Folder")
	beltFolder.Name = "AsteroidBelt"
	beltFolder.Parent = self.RootFolder

	local count = Config.AsteroidCountHigh
	if Cosmos.QualityLevel == 2 then
		count = Config.AsteroidCountMed
	elseif Cosmos.QualityLevel == 1 then
		count = Config.AsteroidCountLow
	end

	local rng = Util.UniverseRng
	for i = 1, count do
		local ang = (i / count) * math.pi * 2 + rng:NextNumber(-0.04, 0.04)
		local dist = rng:NextNumber(4950, 5550)
		local yOff = rng:NextNumber(-180, 180)
		local isLarge = (i % 5 == 0)
		local sz = isLarge and Vector3.new(rng:NextNumber(38, 68), rng:NextNumber(32, 58), rng:NextNumber(38, 68))
			or Vector3.new(rng:NextNumber(14, 28), rng:NextNumber(12, 26), rng:NextNumber(14, 28))

		local pos = Config.UniverseCenter + Vector3.new(math.cos(ang) * dist, yOff, math.sin(ang) * dist)
		local rock = Util.MakePart({
			Name = isLarge and ("DestructibleAsteroid_" .. i) or ("Asteroid_" .. i),
			Material = Enum.Material.Rock,
			Color = (i % 3 == 0) and Color3.fromRGB(115, 108, 102) or Color3.fromRGB(88, 84, 82),
			Size = sz,
			CanCollide = isLarge,
			CanQuery = isLarge,
			CFrame = CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)),
			Parent = beltFolder,
		})

		local entry = {
			Part = rock,
			Angle = ang,
			Radius = dist,
			YOffset = yOff,
			OrbitSpeed = rng:NextNumber(0.004, 0.009),
			RotAxis = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit,
			RotAngle = 0,
			IsDestructible = isLarge,
			Alive = true,
		}
		table.insert(self.Asteroids, entry)
	end
end

function Universe:BuildComet()
	local cometModel = Instance.new("Model")
	cometModel.Name = "HalleyComet"
	cometModel.Parent = self.RootFolder

	local head = Util.MakePart({
		Name = "CometHead",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(185, 245, 255),
		Size = Vector3.new(44, 44, 44),
		Position = Config.UniverseCenter + Vector3.new(0, 1400, -7000),
		Parent = cometModel,
	})
	cometModel.PrimaryPart = head

	local tailParts = {}
	for t = 1, 6 do
		local tp = Util.MakePart({
			Name = "CometTail_" .. t,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = (t <= 3) and Color3.fromRGB(140, 230, 255) or Color3.fromRGB(255, 225, 130),
			Transparency = 0.25 + t * 0.11,
			Size = Vector3.new(40 - t * 4, 40 - t * 4, 85 + t * 18),
			Position = head.Position,
			Parent = cometModel,
		})
		table.insert(tailParts, tp)
	end

	self.Comet = {
		Model = cometModel,
		Head = head,
		Tail = tailParts,
		Phase = 0,
		History = {},
	}
end

function Universe:UpdatePlanetTransform(body, pos, rotAngle, sunPos, dt)
	body.Position = pos
	local rotCF = CFrame.Angles(0, rotAngle, 0)
	body.Core.CFrame = CFrame.new(pos) * rotCF

	-- Posiciona a esfera de sombra deslocada para longe do Sol
	local sunToBody = (pos - sunPos)
	local distSun = sunToBody.Magnitude
	local shadowDir = (distSun > 1) and (sunToBody / distSun) or Vector3.new(1, 0, 0)
	local lightDir = -shadowDir
	body.Shadow.Position = pos + shadowDir * (body.Radius * 0.13)

	if body.AtmoGlow then
		body.AtmoGlow.Position = pos
	end

	-- Atualiza continentes, calotas, bandas ou cristais
	for i = 1, #body.Features do
		local feat = body.Features[i]
		local worldNormal = rotCF:VectorToWorldSpace(feat.LocalNormal)
		if feat.IsBand then
			feat.Part.CFrame = CFrame.new(pos + feat.LocalNormal * feat.Depth) * CFrame.Angles(0, rotAngle, math.pi * 0.5)
		elseif feat.AlignRadial then
			feat.Part.CFrame = CFrame.lookAt(pos + worldNormal * feat.Depth, pos + worldNormal * (feat.Depth + 50)) * CFrame.Angles(math.pi * 0.5, 0, 0)
		else
			feat.Part.Position = pos + worldNormal * feat.Depth
		end
	end

	-- Luzes de cidade da Nova Terra (só acendem no hemisfério oposto ao Sol via produto escalar)
	if body.CityLights and #body.CityLights > 0 then
		for i = 1, #body.CityLights do
			local cl = body.CityLights[i]
			local worldNormal = rotCF:VectorToWorldSpace(cl.LocalNormal)
			cl.Part.Position = pos + worldNormal * cl.Dist
			local dotSun = worldNormal:Dot(lightDir)
			local targetTrans = (dotSun < -0.06) and Util.Clamp(1 - (-dotSun * 1.35), 0.05, 1) or 1
			if math.abs(cl.Part.Transparency - targetTrans) > 0.04 then
				cl.Part.Transparency = targetTrans
			end
		end
	end

	-- Camada de nuvens gira em velocidade diferente
	if body.CloudLayer and body.CloudLayer.PrimaryPart then
		body.CloudAngle = body.CloudAngle + dt * 0.13
		body.CloudLayer:PivotTo(CFrame.new(pos) * CFrame.Angles(0, body.CloudAngle, math.rad(6)))
	end

	-- Anéis do gigante gasoso
	if body.RingModels then
		for i = 1, #body.RingModels do
			local rm = body.RingModels[i]
			rm.Angle = rm.Angle + rm.Speed * dt
			rm.Model:PivotTo(CFrame.new(pos) * rm.Tilt * CFrame.Angles(0, rm.Angle, 0))
		end
	end

	-- Rachaduras de lava pulsando
	if body.LavaCracks and #body.LavaCracks > 0 then
		local pulse = 0.5 + 0.5 * math.sin(Cosmos.TimeElapsed * 3.4)
		local col = Color3.fromRGB(255, math.floor(70 + pulse * 95), 15)
		for i = 1, #body.LavaCracks do
			body.LavaCracks[i].Color = col
		end
	end
end

function Universe:Update(dt)
	local t = Cosmos.TimeElapsed
	local center = Config.UniverseCenter

	-- 1. Pulso da corona solar e rotação dos raios solares
	if self.SunData then
		local s1 = 1 + math.sin(t * 1.8) * 0.035
		local s2 = 1 + math.cos(t * 1.2) * 0.055
		local r = self.SunData.Radius
		self.SunData.CoronaInner.Size = Vector3.new(r * 2.18 * s1, r * 2.18 * s1, r * 2.18 * s1)
		self.SunData.CoronaOuter.Size = Vector3.new(r * 2.42 * s2, r * 2.42 * s2, r * 2.42 * s2)
		for i = 1, #self.SunData.Rays do
			local rayInfo = self.SunData.Rays[i]
			local b = rayInfo.BaseAngles
			rayInfo.Part.CFrame = CFrame.new(center) * CFrame.Angles(b.X + t * rayInfo.Speed, b.Y + t * rayInfo.Speed * 0.7, b.Z)
		end
	end

	-- 2. Casca de estrelas segue a câmera + cintilação em lotes
	local camPos = Cosmos.State.Camera and Cosmos.State.Camera.CFrame.Position or Vector3.zero
	local sf = Cosmos.State.SpaceFactor
	local starVisible = sf > 0.18
	local totalStars = #self.Stars
	if totalStars > 0 then
		for i = 1, totalStars do
			local st = self.Stars[i]
			st.Part.Position = camPos + st.Offset
		end
		local batchSize = math.max(12, math.floor(totalStars / 10))
		local startIdx = self.StarTwinkleBatch
		local endIdx = math.min(totalStars, startIdx + batchSize)
		for i = startIdx, endIdx do
			local st = self.Stars[i]
			if not starVisible then
				if st.Part.Transparency < 0.99 then
					st.Part.Transparency = 1
				end
			else
				local tw = 0.14 * math.sin(t * 3.2 + st.TwinklePhase)
				local targetAlpha = Util.Clamp(1 - sf * (1 - st.BaseAlpha - tw), 0.02, 1)
				if math.abs(st.Part.Transparency - targetAlpha) > 0.03 then
					st.Part.Transparency = targetAlpha
				end
			end
		end
		self.StarTwinkleBatch = (endIdx >= totalStars) and 1 or (endIdx + 1)
	end

	-- 3. Órbitas elípticas dos planetas e luas
	for i = 1, #self.Planets do
		local p = self.Planets[i]
		local cfg = p.Config
		p.OrbitAngle = p.OrbitAngle + cfg.OrbitSpeed * dt
		p.RotationAngle = p.RotationAngle + cfg.RotSpeed * dt

		local localOrb = Vector3.new(
			math.cos(p.OrbitAngle) * cfg.OrbitMajor,
			0,
			math.sin(p.OrbitAngle) * cfg.OrbitMinor
		)
		local tiltedOrb = CFrame.Angles(cfg.OrbitTilt, 0, cfg.OrbitTilt * 0.5):PointToWorldSpace(localOrb)
		local worldPos = center + tiltedOrb
		self:UpdatePlanetTransform(p, worldPos, p.RotationAngle, center, dt)

		for m = 1, #p.Moons do
			local moon = p.Moons[m]
			local mCfg = moon.Config
			moon.OrbitAngle = moon.OrbitAngle + mCfg.OrbitSpeed * dt
			moon.RotationAngle = moon.RotationAngle + mCfg.OrbitSpeed * dt
			local mOrb = Vector3.new(
				math.cos(moon.OrbitAngle) * mCfg.OrbitRadius,
				0,
				math.sin(moon.OrbitAngle) * mCfg.OrbitRadius
			)
			local mTilted = CFrame.Angles(mCfg.OrbitTilt, 0, 0):PointToWorldSpace(mOrb)
			self:UpdatePlanetTransform(moon, worldPos + mTilted, moon.RotationAngle, center, dt)
		end
	end

	-- 4. Cinturão de asteroides
	for i = 1, #self.Asteroids do
		local ast = self.Asteroids[i]
		if ast.Alive and ast.Part and ast.Part.Parent then
			ast.Angle = ast.Angle + ast.OrbitSpeed * dt
			ast.RotAngle = ast.RotAngle + dt * 0.45
			local pos = center + Vector3.new(math.cos(ast.Angle) * ast.Radius, ast.YOffset, math.sin(ast.Angle) * ast.Radius)
			ast.Part.CFrame = CFrame.new(pos) * CFrame.fromAxisAngle(ast.RotAxis, ast.RotAngle)
		end
	end

	-- 5. Cometa cruzando o sistema solar
	if self.Comet and self.Comet.Head then
		self.Comet.Phase = self.Comet.Phase + dt * 0.055
		local cAng = self.Comet.Phase
		local cPos = center + Vector3.new(
			math.cos(cAng) * 7600,
			math.sin(cAng * 2) * 1450,
			math.sin(cAng) * 4200
		)
		local nextPos = center + Vector3.new(
			math.cos(cAng + 0.02) * 7600,
			math.sin((cAng + 0.02) * 2) * 1450,
			math.sin(cAng + 0.02) * 4200
		)
		local dir = (nextPos - cPos).Unit
		self.Comet.Head.CFrame = CFrame.lookAt(cPos, nextPos)
		for idx, tp in ipairs(self.Comet.Tail) do
			local tailPos = cPos - dir * (idx * 58)
			tp.CFrame = CFrame.lookAt(tailPos, cPos)
		end
	end
end

function Universe:GetBodyPosition(idOrName)
	local b = self.BodyById[idOrName]
	if b then
		return b.Position
	end
	for i = 1, #self.AllBodies do
		if self.AllBodies[i].Name == idOrName then
			return self.AllBodies[i].Position
		end
	end
	return Config.UniverseCenter
end

function Universe:GetNearestBody(pos, onlyWalkable)
	local best = nil
	local bestSurfaceDist = math.huge
	for i = 1, #self.AllBodies do
		local b = self.AllBodies[i]
		if not onlyWalkable or b.Walkable then
			local surfDist = (pos - b.Position).Magnitude - b.Radius
			if surfDist < bestSurfaceDist then
				bestSurfaceDist = surfDist
				best = b
			end
		end
	end
	return best, bestSurfaceDist
end

function Universe:GetBodiesSortedByDistance(pos)
	local list = {}
	for i = 1, #self.AllBodies do
		local b = self.AllBodies[i]
		local centerDist = (pos - b.Position).Magnitude
		table.insert(list, {
			Body = b,
			CenterDistance = centerDist,
			SurfaceDistance = math.max(0, centerDist - b.Radius),
		})
	end
	table.sort(list, function(a, b)
		return a.SurfaceDistance < b.SurfaceDistance
	end)
	return list
end

function Universe:OnQualityChanged()
	self:BuildStarShell()
end

function Universe:Destroy()
	self.Maid:Clean()
	table.clear(self.Planets)
	table.clear(self.AllBodies)
	table.clear(self.BodyById)
	table.clear(self.Stars)
	table.clear(self.Asteroids)
end

Cosmos.Modules.Universe = Universe

--==============================================================================
-- [SEÇÃO 03] ATMOSPHERE / SPACE TRANSITION (CÉU -> ESPAÇO & REENTRADA)
--==============================================================================

local Atmosphere = {
	Maid = Maid.new(),
	SavedLighting = {},
	SavedAtmo = nil,
	AtmoInst = nil,
	ColorCorr = nil,
	Bloom = nil,
	Blur = nil,
	ReentryEmitterPart = nil,
	ReentryParticles = {},
	ReentryIntensity = 0,
	PrevSpaceFactor = 0,
}

function Atmosphere:Init()
	local L = Services.Lighting
	self.SavedLighting = {
		ClockTime = L.ClockTime,
		Brightness = L.Brightness,
		Ambient = L.Ambient,
		OutdoorAmbient = L.OutdoorAmbient,
		ExposureCompensation = L.ExposureCompensation,
		FogEnd = L.FogEnd,
		FogStart = L.FogStart,
		FogColor = L.FogColor,
		ColorShift_Top = L.ColorShift_Top,
	}

	local existingAtmo = L:FindFirstChildOfClass("Atmosphere")
	if existingAtmo then
		self.SavedAtmo = {
			Inst = existingAtmo,
			Density = existingAtmo.Density,
			Offset = existingAtmo.Offset,
			Color = existingAtmo.Color,
			Decay = existingAtmo.Decay,
			Glare = existingAtmo.Glare,
			Haze = existingAtmo.Haze,
		}
		self.AtmoInst = existingAtmo
	else
		local newAtmo = Instance.new("Atmosphere")
		newAtmo.Name = "Cosmos_Atmosphere"
		newAtmo.Parent = L
		self.AtmoInst = self.Maid:Give(newAtmo)
	end

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Cosmos_ColorCorrection"
	cc.Parent = L
	self.ColorCorr = self.Maid:Give(cc)

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "Cosmos_Bloom"
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 0.9
	bloom.Parent = L
	self.Bloom = self.Maid:Give(bloom)

	local blur = Instance.new("BlurEffect")
	blur.Name = "Cosmos_MotionBlur"
	blur.Size = 0
	blur.Parent = L
	self.Blur = self.Maid:Give(blur)

	-- Pool de faíscas de calor de reentrada atmosférica
	local reentryFolder = Instance.new("Folder")
	reentryFolder.Name = "Cosmos_ReentryFX"
	reentryFolder.Parent = Services.Workspace
	self.Maid:Give(reentryFolder)

	for i = 1, 18 do
		local p = Util.MakePart({
			Name = "ReentryPlasma_" .. i,
			Material = Enum.Material.Neon,
			Color = (i % 2 == 0) and Color3.fromRGB(255, 115, 25) or Color3.fromRGB(255, 205, 70),
			Transparency = 1,
			Size = Vector3.new(0.45, 0.45, 6.5),
			Parent = reentryFolder,
		})
		table.insert(self.ReentryParticles, {
			Part = p,
			Offset = Vector3.new(
				Util.FxRng:NextNumber(-5, 5),
				Util.FxRng:NextNumber(-4, 4),
				Util.FxRng:NextNumber(-8, -2)
			),
			Phase = Util.FxRng:NextNumber(0, math.pi * 2),
		})
	end
end

function Atmosphere:Update(dt)
	local root = Cosmos.State.RootPart
	local cam = Cosmos.State.Camera
	local refPos = root and root.Position or (cam and cam.CFrame.Position or Vector3.zero)
	Cosmos.State.Altitude = math.max(0, refPos.Y)

	-- Verifica proximidade de planetas com atmosfera
	local atmoPull = 0
	local nearestBody, surfDist = Universe:GetNearestBody(refPos, false)
	if nearestBody and nearestBody.HasAtmosphere and surfDist < 380 then
		atmoPull = Util.Clamp(1 - (surfDist / 380), 0, 1) * 0.55
	end

	local rawSpace = Util.Clamp((refPos.Y - Config.AltStart) / (Config.AltFull - Config.AltStart), 0, 1)
	local targetSpace = Util.Clamp(rawSpace - atmoPull, 0, 1)
	Cosmos.State.SpaceFactor = Util.ExpDecay(Cosmos.State.SpaceFactor, targetSpace, 3.8, dt)
	local sf = Cosmos.State.SpaceFactor

	-- Fases visuais:
	-- 0.00 - 0.25: Céu terrestre normal
	-- 0.25 - 0.60: Crepúsculo estratosférico laranja/violeta
	-- 0.60 - 1.00: Vácuo profundo escuro com Bloom e estrelas
	local L = Services.Lighting
	local orig = self.SavedLighting

	if sf < 0.25 then
		local t = sf / 0.25
		L.ClockTime = Util.Lerp(orig.ClockTime, 17.6, t)
	elseif sf < 0.60 then
		local t = (sf - 0.25) / 0.35
		L.ClockTime = Util.Lerp(17.6, 0.2, t)
	else
		L.ClockTime = 0
	end

	L.Brightness = Util.Lerp(orig.Brightness, 1.35, sf)
	L.Ambient = Util.LerpColor(orig.Ambient, Color3.fromRGB(14, 18, 28), sf)
	L.OutdoorAmbient = Util.LerpColor(orig.OutdoorAmbient, Color3.fromRGB(18, 24, 38), sf)
	L.ExposureCompensation = Util.Lerp(orig.ExposureCompensation, 0.28, sf)
	L.FogEnd = Util.Lerp(math.min(orig.FogEnd, 25000), 100000, sf)

	if self.AtmoInst then
		local duskFactor = math.sin(Util.Clamp((sf - 0.15) / 0.55, 0, 1) * math.pi)
		self.AtmoInst.Density = Util.Lerp(0.32, 0.02, sf)
		self.AtmoInst.Haze = Util.Lerp(1.2, 0.0, sf)
		self.AtmoInst.Glare = Util.Lerp(0.2, 0.65, duskFactor)
		local skyCol = Color3.fromRGB(115, 180, 255):Lerp(Color3.fromRGB(255, 115, 65), duskFactor):Lerp(Color3.fromRGB(8, 12, 22), sf)
		self.AtmoInst.Color = skyCol
		self.AtmoInst.Decay = Color3.fromRGB(155, 110, 195):Lerp(Color3.fromRGB(5, 8, 16), sf)
	end

	if self.Bloom then
		self.Bloom.Intensity = Util.Lerp(0.35, 1.15, sf)
		self.Bloom.Size = Util.Lerp(22, 38, sf)
	end

	-- Oxigênio: cai no espaço fora de atmosfera, regenera em atmosfera
	local inAtmosphere = (sf < 0.62) or (atmoPull > 0.22)
	if inAtmosphere then
		Cosmos.State.Oxygen = math.min(Cosmos.State.MaxOxygen, Cosmos.State.Oxygen + 22 * dt)
	else
		Cosmos.State.Oxygen = math.max(0, Cosmos.State.Oxygen - 2.4 * dt)
		if Cosmos.State.Oxygen <= 0.01 then
			Cosmos.State.Health = math.max(0, Cosmos.State.Health - 4.5 * dt)
		end
	end

	-- Calor de Reentrada Atmosférica: quando desce rápido atravessando a alta atmosfera
	local velVec = root and root.AssemblyLinearVelocity or Vector3.zero
	local speed = velVec.Magnitude
	local enteringAtmo = ((sf > 0.20 and sf < 0.78 and velVec.Y < -95) or (atmoPull > 0.12 and speed > 165))
	local targetReentry = enteringAtmo and Util.Clamp((speed - 120) / 240, 0, 1) or 0
	self.ReentryIntensity = Util.ExpDecay(self.ReentryIntensity, targetReentry, 6, dt)

	if self.ColorCorr then
		local heatTint = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 165, 125), self.ReentryIntensity * 0.45)
		self.ColorCorr.TintColor = heatTint
		self.ColorCorr.Contrast = Util.Lerp(0.04, 0.14, sf)
	end

	if self.ReentryIntensity > 0.05 and root then
		local moveCF = (speed > 5) and CFrame.lookAt(root.Position, root.Position + velVec.Unit) or root.CFrame
		if Cosmos.Modules.CameraFX then
			Cosmos.Modules.CameraFX:AddShake(self.ReentryIntensity * 0.32, 0.1)
		end
		for i = 1, #self.ReentryParticles do
			local rp = self.ReentryParticles[i]
			rp.Phase = rp.Phase + dt * 16
			local zShift = ((rp.Phase % 1) * 14) - 4
			local localOff = Vector3.new(rp.Offset.X, rp.Offset.Y, -zShift)
			rp.Part.CFrame = moveCF * CFrame.new(localOff)
			rp.Part.Transparency = Util.Clamp(1 - self.ReentryIntensity * 0.88, 0.08, 1)
		end
	else
		for i = 1, #self.ReentryParticles do
			if self.ReentryParticles[i].Part.Transparency < 0.99 then
				self.ReentryParticles[i].Part.Transparency = 1
			end
		end
	end

	self.PrevSpaceFactor = sf
end

function Atmosphere:Destroy()
	self.Maid:Clean()
	local L = Services.Lighting
	for k, v in pairs(self.SavedLighting) do
		pcall(function() L[k] = v end)
	end
	if self.SavedAtmo and self.SavedAtmo.Inst and self.SavedAtmo.Inst.Parent then
		local sa = self.SavedAtmo
		pcall(function()
			sa.Inst.Density = sa.Density
			sa.Inst.Offset = sa.Offset
			sa.Inst.Color = sa.Color
			sa.Inst.Decay = sa.Decay
			sa.Inst.Glare = sa.Glare
			sa.Inst.Haze = sa.Haze
		end)
	end
	table.clear(self.ReentryParticles)
end

Cosmos.Modules.Atmosphere = Atmosphere

--==============================================================================
-- [SEÇÃO 04] FLIGHT (VOO SUPERMAN COMPLETO, POSE, TURBO, HIPER-VELOCIDADE, VFX)
--==============================================================================

local Flight = {
	Maid = Maid.new(),
	BodyVel = nil,
	BodyGyro = nil,
	CurrentVelocity = Vector3.zero,
	CurrentRoll = 0,
	CurrentPitch = 0,
	WasSonic = false,
	SonicCooldown = 0,
	WindLines = {},
	HyperStars = {},
	ShockwaveRing = nil,
	ShockwaveAlpha = 1,
	TrailFolder = nil,
	TrailSegments = {},
	TrailIndex = 1,
	TrailTimer = 0,
	SavedMotorC0 = {},
}

function Flight:Init()
	local fxFolder = Instance.new("Folder")
	fxFolder.Name = "Cosmos_FlightFX"
	fxFolder.Parent = Services.Workspace
	self.TrailFolder = self.Maid:Give(fxFolder)

	-- Linhas de vento aerodinâmicas (pool fixo)
	for i = 1, 16 do
		local wl = Util.MakePart({
			Name = "WindLine_" .. i,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(210, 245, 255),
			Transparency = 1,
			Size = Vector3.new(0.18, 0.18, 9),
			Parent = fxFolder,
		})
		table.insert(self.WindLines, {
			Part = wl,
			Radius = Util.FxRng:NextNumber(4.5, 12),
			Angle = (i / 16) * math.pi * 2,
			ZProgress = Util.FxRng:NextNumber(0, 1),
		})
	end

	-- Túnel de estrelas esticadas para Hiper-Velocidade
	for i = 1, 24 do
		local hs = Util.MakePart({
			Name = "HyperStreak_" .. i,
			Material = Enum.Material.Neon,
			Color = (i % 2 == 0) and Color3.fromRGB(115, 235, 255) or Color3.fromRGB(205, 165, 255),
			Transparency = 1,
			Size = Vector3.new(0.32, 0.32, 28),
			Parent = fxFolder,
		})
		table.insert(self.HyperStars, {
			Part = hs,
			Radius = Util.FxRng:NextNumber(8, 24),
			Angle = (i / 24) * math.pi * 2,
			ZProgress = Util.FxRng:NextNumber(0, 1),
		})
	end

	-- Anel de Onda de Choque Sônica
	self.ShockwaveRing = Util.MakePart({
		Name = "SonicBoomRing",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(160, 240, 255),
		Transparency = 1,
		Size = Vector3.new(0.8, 4, 4),
		Parent = fxFolder,
	})

	-- Segmentos de rastro energético no espaço (cores adaptam à Aura equipada)
	for i = 1, 20 do
		local seg = Util.MakePart({
			Name = "FlightTrailSeg_" .. i,
			Material = Enum.Material.Neon,
			Color = Config.Theme.StrokeCyan,
			Transparency = 1,
			Size = Vector3.new(0.85, 0.85, 4.5),
			Parent = fxFolder,
		})
		table.insert(self.TrailSegments, { Part = seg, Alpha = 1 })
	end
end

function Flight:SetFlying(enable)
	local st = Cosmos.State
	if enable == st.IsFlying then
		return
	end
	local root = st.RootPart
	local hum = st.Humanoid
	if not root or not hum then
		st.IsFlying = false
		return
	end

	if enable then
		if Cosmos.Modules.Gravity and st.WalkBody then
			Cosmos.Modules.Gravity:DisengagePlanetWalk()
		end
		st.IsFlying = true
		hum.PlatformStand = true

		if not self.BodyVel or not self.BodyVel.Parent then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "CosmosFlightBV"
			bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
			bv.Velocity = root.AssemblyLinearVelocity
			bv.Parent = root
			self.BodyVel = bv
		end

		if not self.BodyGyro or not self.BodyGyro.Parent then
			local bg = Instance.new("BodyGyro")
			bg.Name = "CosmosFlightBG"
			bg.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
			bg.P = 18000
			bg.D = 900
			bg.CFrame = root.CFrame
			bg.Parent = root
			self.BodyGyro = bg
		end

		self.CurrentVelocity = root.AssemblyLinearVelocity
		if Cosmos.Modules.Audio then
			Cosmos.Modules.Audio:Play("UI_Click")
		end
	else
		st.IsFlying = false
		st.FlightMode = 1
		if self.BodyVel then
			self.BodyVel:Destroy()
			self.BodyVel = nil
		end
		if self.BodyGyro then
			self.BodyGyro:Destroy()
			self.BodyGyro = nil
		end
		if hum and hum.Parent then
			hum.PlatformStand = false
		end
		self:HideAllFX()
	end
end

function Flight:ToggleFlight()
	self:SetFlying(not Cosmos.State.IsFlying)
end

function Flight:CycleFlightSpeedMode()
	local st = Cosmos.State
	if not st.IsFlying then
		self:SetFlying(true)
	end
	if st.FlightMode == 1 then
		st.FlightMode = 2
	elseif st.FlightMode == 2 then
		if st.SpaceFactor > 0.55 then
			st.FlightMode = 3
		else
			st.FlightMode = 1
		end
	else
		st.FlightMode = 1
	end
	if Cosmos.Modules.Audio then
		Cosmos.Modules.Audio:Play("Whoosh")
	end
end

function Flight:Brake()
	self.CurrentVelocity = self.CurrentVelocity * 0.15
end

function Flight:TriggerSonicBoom(originCF)
	self.ShockwaveAlpha = 0.05
	self.ShockwaveRing.Size = Vector3.new(1.2, 6, 6)
	self.ShockwaveRing.CFrame = originCF * CFrame.Angles(0, math.pi * 0.5, 0)
	self.ShockwaveRing.Transparency = 0.05
	if Cosmos.Modules.CameraFX then
		Cosmos.Modules.CameraFX:AddShake(1.15, 0.45)
		Cosmos.Modules.CameraFX:Flash(Color3.fromRGB(165, 240, 255), 0.32, 0.28)
	end
	if Cosmos.Modules.Audio then
		Cosmos.Modules.Audio:Play("SonicBoom")
	end
end

function Flight:HideAllFX()
	for i = 1, #self.WindLines do
		self.WindLines[i].Part.Transparency = 1
	end
	for i = 1, #self.HyperStars do
		self.HyperStars[i].Part.Transparency = 1
	end
	for i = 1, #self.TrailSegments do
		self.TrailSegments[i].Part.Transparency = 1
	end
	if self.ShockwaveRing then
		self.ShockwaveRing.Transparency = 1
	end
end

function Flight:OnCharacterAdded()
	self.BodyVel = nil
	self.BodyGyro = nil
	if Cosmos.State.IsFlying then
		Cosmos.State.IsFlying = false
		self:SetFlying(true)
	end
end

function Flight:Update(dt)
	local st = Cosmos.State
	local root = st.RootPart
	local hum = st.Humanoid
	local cam = st.Camera

	if self.SonicCooldown > 0 then
		self.SonicCooldown = self.SonicCooldown - dt
	end

	-- Atualiza expansão do anel de estrondo sônico
	if self.ShockwaveAlpha < 1 and self.ShockwaveRing then
		self.ShockwaveAlpha = math.min(1, self.ShockwaveAlpha + dt * 2.2)
		local diam = Util.Lerp(8, 86, self.ShockwaveAlpha)
		self.ShockwaveRing.Size = Vector3.new(1.0, diam, diam)
		self.ShockwaveRing.Transparency = self.ShockwaveAlpha
	end

	-- Fade dos segmentos de rastro
	for i = 1, #self.TrailSegments do
		local seg = self.TrailSegments[i]
		if seg.Alpha < 1 then
			seg.Alpha = math.min(1, seg.Alpha + dt * 2.4)
			seg.Part.Transparency = seg.Alpha
		end
	end

	if not st.IsFlying or not root or not hum or not cam then
		st.Stamina = math.min(st.MaxStamina, st.Stamina + Config.Flight.StaminaRegen * dt)
		return
	end

	-- Se entrou em hiper-velocidade mas voltou pra atmosfera, reduz para Turbo
	if st.FlightMode == 3 and st.SpaceFactor < 0.45 then
		st.FlightMode = 2
	end

	-- Gerenciamento de Stamina de Voo
	if st.FlightMode == 2 then
		st.Stamina = math.max(0, st.Stamina - Config.Flight.StaminaDrainTurbo * dt)
		if st.Stamina <= 0.1 then
			st.FlightMode = 1
		end
	elseif st.FlightMode == 3 then
		st.Stamina = math.max(0, st.Stamina - Config.Flight.StaminaDrainHyper * dt)
		if st.Stamina <= 0.1 then
			st.FlightMode = 1
		end
	else
		st.Stamina = math.min(st.MaxStamina, st.Stamina + Config.Flight.StaminaRegen * dt)
	end

	-- Direção do voo combinando MoveDirection (analógico mobile/teclado) + câmera + vertical
	local camCF = cam.CFrame
	local rawMove = hum.MoveDirection
	if st.MoveVector.Magnitude > 0.05 then
		rawMove = (camCF.RightVector * st.MoveVector.X + camCF.LookVector * (-st.MoveVector.Z))
	end

	local desiredDir = Vector3.zero
	if rawMove.Magnitude > 0.05 then
		-- Quando o jogador empurra pra frente, voa na direção exata para onde a câmera aponta
		local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
		if flatRight.Magnitude > 0.01 then
			flatRight = flatRight.Unit
		end
		local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
		if flatLook.Magnitude > 0.01 then
			flatLook = flatLook.Unit
		end
		local forwardDot = rawMove:Dot(flatLook)
		local rightDot = rawMove:Dot(flatRight)
		desiredDir = (camCF.LookVector * forwardDot + camCF.RightVector * rightDot)
	end

	if math.abs(st.VerticalInput) > 0.05 then
		desiredDir = desiredDir + Vector3.new(0, st.VerticalInput, 0)
	end
	if desiredDir.Magnitude > 1 then
		desiredDir = desiredDir.Unit
	end

	local maxSpd = Config.Flight.NormalSpeed
	if st.FlightMode == 2 then
		maxSpd = Config.Flight.TurboSpeed
	elseif st.FlightMode == 3 then
		maxSpd = Config.Flight.HyperSpeed
	end

	local targetVel = desiredDir * maxSpd
	local rate = (desiredDir.Magnitude > 0.05) and Config.Flight.Accel or Config.Flight.Decel
	self.CurrentVelocity = Util.ExpDecayVec3(self.CurrentVelocity, targetVel, rate, dt)
	local spd = self.CurrentVelocity.Magnitude
	st.Speed = spd

	if self.BodyVel then
		self.BodyVel.Velocity = self.CurrentVelocity
	end

	-- Estrondo Sônico ao cruzar o limiar de velocidade
	if spd >= Config.Flight.SonicBoomThreshold and not self.WasSonic and self.SonicCooldown <= 0 then
		self.WasSonic = true
		self.SonicCooldown = 2.0
		self:TriggerSonicBoom(root.CFrame)
	elseif spd < Config.Flight.SonicBoomThreshold * 0.75 then
		self.WasSonic = false
	end

	-- Pose Superman (horizontal quando em movimento, hover em pé quando parado) + Banking lateral
	local moveRatio = Util.Clamp(spd / 75, 0, 1)
	local lookDir = (spd > 6) and self.CurrentVelocity.Unit or Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
	if lookDir.Magnitude < 0.01 then
		lookDir = Vector3.new(0, 0, -1)
	end

	local sideVel = self.CurrentVelocity:Dot(camCF.RightVector)
	local targetRoll = Util.Clamp(-sideVel / 140, -1, 1) * Config.Flight.BankAngle
	self.CurrentRoll = Util.ExpDecay(self.CurrentRoll, targetRoll, 7, dt)

	local targetPitch = Util.Lerp(0, -math.rad(82), moveRatio)
	self.CurrentPitch = Util.ExpDecay(self.CurrentPitch, targetPitch, 8, dt)

	if self.BodyGyro then
		local basePose = CFrame.lookAt(root.Position, root.Position + lookDir)
		self.BodyGyro.CFrame = basePose * CFrame.Angles(self.CurrentPitch, 0, self.CurrentRoll)
	end

	-- Verifica transição suave para pouso em planeta/lua caminhável
	if Cosmos.Modules.Gravity and spd < 145 then
		local nearBody, surfDist = Universe:GetNearestBody(root.Position, true)
		if nearBody and surfDist <= Config.Gravity.EngageSurfaceDist * 0.65 and st.VerticalInput <= 0 then
			self:SetFlying(false)
			Cosmos.Modules.Gravity:EngagePlanetWalk(nearBody)
			return
		end
	end

	-- VFX 1: Linhas de vento ao redor do jogador
	local windAlpha = Util.Clamp((spd - 75) / 220, 0, 0.85)
	local flyCF = CFrame.lookAt(root.Position, root.Position + lookDir)
	for i = 1, #self.WindLines do
		local wl = self.WindLines[i]
		if windAlpha > 0.04 then
			wl.ZProgress = (wl.ZProgress + dt * (2.2 + spd * 0.012)) % 1
			local zOff = Util.Lerp(-16, 18, wl.ZProgress)
			local xOff = math.cos(wl.Angle) * wl.Radius
			local yOff = math.sin(wl.Angle) * wl.Radius
			wl.Part.CFrame = flyCF * CFrame.new(xOff, yOff, zOff)
			wl.Part.Transparency = 1 - windAlpha * math.sin(wl.ZProgress * math.pi)
		elseif wl.Part.Transparency < 0.99 then
			wl.Part.Transparency = 1
		end
	end

	-- VFX 2: Túnel de Hiper-Velocidade no espaço
	local isHyper = (st.FlightMode == 3 and spd > 380)
	for i = 1, #self.HyperStars do
		local hs = self.HyperStars[i]
		if isHyper then
			hs.ZProgress = (hs.ZProgress + dt * 4.6) % 1
			local zOff = Util.Lerp(-45, 25, hs.ZProgress)
			local xOff = math.cos(hs.Angle) * hs.Radius
			local yOff = math.sin(hs.Angle) * hs.Radius
			hs.Part.CFrame = camCF * CFrame.new(xOff, yOff, zOff)
			hs.Part.Transparency = 0.15 + 0.75 * math.abs(hs.ZProgress - 0.5)
		elseif hs.Part.Transparency < 0.99 then
			hs.Part.Transparency = 1
		end
	end

	-- VFX 3: Rastro luminoso colorido (assume a cor da Aura equipada!)
	self.TrailTimer = self.TrailTimer + dt
	if spd > 40 and self.TrailTimer >= 0.035 then
		self.TrailTimer = 0
		local seg = self.TrailSegments[self.TrailIndex]
		self.TrailIndex = (self.TrailIndex % #self.TrailSegments) + 1
		local trailColor = Config.Theme.StrokeCyan
		if st.EquippedAura and Config.Auras[st.EquippedAura] then
			local auraCfg = Config.Auras[st.EquippedAura]
			trailColor = (self.TrailIndex % 2 == 0) and auraCfg.Primary or auraCfg.Secondary
		end
		seg.Part.Color = trailColor
		seg.Part.Size = Vector3.new(0.75, 0.75, math.clamp(spd * 0.04, 3.5, 14))
		seg.Part.CFrame = flyCF * CFrame.new(0, 0, 3.5)
		seg.Alpha = 0.12
		seg.Part.Transparency = 0.12
	end
end

function Flight:Destroy()
	self:SetFlying(false)
	self.Maid:Clean()
	table.clear(self.WindLines)
	table.clear(self.HyperStars)
	table.clear(self.TrailSegments)
end

Cosmos.Modules.Flight = Flight

--==============================================================================
-- [SEÇÃO 05] GRAVITY / PLANET WALK (GRAVIDADE ESFÉRICA EM LUAS E PLANETAS)
--==============================================================================

local Gravity = {
	Maid = Maid.new(),
	ColliderBall = nil,
	AlignGyro = nil,
	GravForce = nil,
	DustPool = {},
	DustIndex = 1,
	StepTimer = 0,
	JumpCooldown = 0,
	RadialVelocity = 0,
	SmoothedUp = Vector3.new(0, 1, 0),
	PrevBodyPos = nil,
}

function Gravity:Init()
	local folder = Instance.new("Folder")
	folder.Name = "Cosmos_PlanetWalk"
	folder.Parent = Services.Workspace
	self.Maid:Give(folder)

	-- Esfera de colisão invisível dinâmica (ativada apenas perto do corpo caminhável atual)
	self.ColliderBall = Util.MakePart({
		Name = "SphericalSurfaceCollider",
		Shape = Enum.PartType.Ball,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Size = Vector3.new(10, 10, 10),
		Position = Vector3.new(0, -5000, 0),
		Parent = folder,
	})

	-- Pool de partículas de poeira lunar nos passos
	for i = 1, 14 do
		local dp = Util.MakePart({
			Name = "LunarStepDust_" .. i,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(185, 190, 200),
			Transparency = 1,
			Size = Vector3.new(1.4, 1.4, 1.4),
			Parent = folder,
		})
		table.insert(self.DustPool, { Part = dp, Alpha = 1, Vel = Vector3.zero })
	end
end

function Gravity:EngagePlanetWalk(body)
	if not body or not body.Walkable then
		return
	end
	local st = Cosmos.State
	local root = st.RootPart
	local hum = st.Humanoid
	if not root or not hum then
		return
	end

	if st.IsFlying and Cosmos.Modules.Flight then
		Cosmos.Modules.Flight:SetFlying(false)
	end

	st.WalkBody = body
	self.PrevBodyPos = body.Position
	self.RadialVelocity = 0

	-- Registra visita ao planeta/lua para Missões
	if not st.VisitedBodies[body.Id] then
		st.VisitedBodies[body.Id] = true
		if Cosmos.Modules.Missions then
			Cosmos.Modules.Missions:OnBodyVisited(body)
		end
		if Cosmos.Modules.HUD then
			Cosmos.Modules.HUD:Notify("🪐", "Pouso Confirmado", "Você pisou na superfície de " .. body.Name .. "!", 4)
		end
	end

	-- Ativa colisão real se o diâmetro couber no limite de 2048 studs
	local diam = math.min(2048, body.Radius * 2)
	self.ColliderBall.Size = Vector3.new(diam, diam, diam)
	self.ColliderBall.Position = body.Position
	self.ColliderBall.CanCollide = true

	if not self.AlignGyro or not self.AlignGyro.Parent then
		local bg = Instance.new("BodyGyro")
		bg.Name = "CosmosPlanetWalkGyro"
		bg.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
		bg.P = 22000
		bg.D = 1100
		bg.CFrame = root.CFrame
		bg.Parent = root
		self.AlignGyro = bg
	end
end

function Gravity:DisengagePlanetWalk()
	local st = Cosmos.State
	st.WalkBody = nil
	self.PrevBodyPos = nil
	if self.AlignGyro then
		self.AlignGyro:Destroy()
		self.AlignGyro = nil
	end
	if self.ColliderBall then
		self.ColliderBall.CanCollide = false
		self.ColliderBall.Position = Vector3.new(0, -5000, 0)
	end
end

function Gravity:TakeOff()
	local st = Cosmos.State
	local root = st.RootPart
	local body = st.WalkBody
	if body and root then
		local normal = (root.Position - body.Position).Unit
		self:DisengagePlanetWalk()
		root.AssemblyLinearVelocity = normal * 95
		if Cosmos.Modules.Flight then
			Cosmos.Modules.Flight:SetFlying(true)
		end
		if Cosmos.Modules.Audio then
			Cosmos.Modules.Audio:Play("Whoosh")
		end
	elseif Cosmos.Modules.Flight then
		Cosmos.Modules.Flight:SetFlying(true)
	end
end

function Gravity:Jump()
	local st = Cosmos.State
	if not st.WalkBody or self.JumpCooldown > 0 then
		return
	end
	self.JumpCooldown = 0.45
	self.RadialVelocity = Config.Gravity.JumpImpulse
	if Cosmos.Modules.Audio then
		Cosmos.Modules.Audio:Play("Whoosh")
	end
end

function Gravity:SpawnStepDust(pos, normal, color)
	local d = self.DustPool[self.DustIndex]
	self.DustIndex = (self.DustIndex % #self.DustPool) + 1
	d.Part.Color = color or Color3.fromRGB(185, 190, 200)
	d.Part.Size = Vector3.new(1.2, 1.2, 1.2)
	d.Part.Position = pos
	d.Part.Transparency = 0.25
	d.Alpha = 0.25
	d.Vel = normal * 6 + Vector3.new(Util.FxRng:NextNumber(-3, 3), Util.FxRng:NextNumber(-3, 3), Util.FxRng:NextNumber(-3, 3))
end

function Gravity:OnCharacterAdded()
	self.AlignGyro = nil
	self:DisengagePlanetWalk()
end

function Gravity:Update(dt)
	local st = Cosmos.State
	local root = st.RootPart
	local hum = st.Humanoid
	local cam = st.Camera

	if self.JumpCooldown > 0 then
		self.JumpCooldown = self.JumpCooldown - dt
	end

	-- Animação das partículas de poeira nos passos
	for i = 1, #self.DustPool do
		local d = self.DustPool[i]
		if d.Alpha < 1 then
			d.Alpha = math.min(1, d.Alpha + dt * 1.6)
			d.Part.Position = d.Part.Position + d.Vel * dt
			local s = Util.Lerp(1.2, 3.6, d.Alpha)
			d.Part.Size = Vector3.new(s, s, s)
			d.Part.Transparency = d.Alpha
		end
	end

	if not root or not hum then
		return
	end

	-- Se não está caminhando em planeta nem voando, verifica proximidade de superfície caminhável
	if not st.WalkBody and not st.IsFlying then
		local nearBody, surfDist = Universe:GetNearestBody(root.Position, true)
		if nearBody and surfDist <= Config.Gravity.EngageSurfaceDist then
			self:EngagePlanetWalk(nearBody)
		end
	end

	local body = st.WalkBody
	if not body then
		self.SmoothedUp = Util.ExpDecayVec3(self.SmoothedUp, Vector3.new(0, 1, 0), Config.Gravity.CamUpSmooth, dt).Unit
		return
	end

	-- Move o jogador junto com o deslocamento orbital do planeta/lua
	local bodyDelta = Vector3.zero
	if self.PrevBodyPos then
		bodyDelta = body.Position - self.PrevBodyPos
	end
	self.PrevBodyPos = body.Position
	self.ColliderBall.Position = body.Position

	local nextRootPos = root.Position + bodyDelta
	local toPlayer = nextRootPos - body.Position
	local distFromCenter = toPlayer.Magnitude
	local surfDist = distFromCenter - body.Radius

	-- Se se afastou demais da superfície, desengata
	if surfDist > Config.Gravity.DisengageSurfaceDist then
		self:DisengagePlanetWalk()
		return
	end

	local upNormal = (distFromCenter > 0.1) and (toPlayer / distFromCenter) or Vector3.new(0, 1, 0)
	self.SmoothedUp = Util.ExpDecayVec3(self.SmoothedUp, upNormal, Config.Gravity.CamUpSmooth, dt).Unit

	if hum.Jump and self.JumpCooldown <= 0 then
		self:Jump()
	end

	-- Calcula tangente de movimento sobre a esfera a partir da câmera e controles
	local camLook = cam and cam.CFrame.LookVector or root.CFrame.LookVector
	local tangentForward = (camLook - upNormal * camLook:Dot(upNormal))
	if tangentForward.Magnitude < 0.01 then
		tangentForward = (root.CFrame.LookVector - upNormal * root.CFrame.LookVector:Dot(upNormal))
	end
	tangentForward = tangentForward.Unit
	local tangentRight = tangentForward:Cross(upNormal).Unit

	local rawMove = hum.MoveDirection
	local moveTangent = Vector3.zero
	if st.MoveVector.Magnitude > 0.05 then
		moveTangent = (tangentRight * st.MoveVector.X + tangentForward * (-st.MoveVector.Z))
	elseif rawMove.Magnitude > 0.05 then
		local proj = rawMove - upNormal * rawMove:Dot(upNormal)
		if proj.Magnitude > 0.01 then
			moveTangent = proj.Unit * math.min(1, rawMove.Magnitude)
		end
	end

	local walkSpeed = 24
	local gravAccel = body.SurfaceGravity or Config.Gravity.MoonGravityAccel
	self.RadialVelocity = self.RadialVelocity - gravAccel * dt

	local standRadius = body.Radius + 3.4
	local newRadius = distFromCenter + self.RadialVelocity * dt
	local grounded = false
	if newRadius <= standRadius then
		newRadius = standRadius
		if self.RadialVelocity < 0 then
			self.RadialVelocity = 0
		end
		grounded = true
	end

	local finalPos = body.Position + upNormal * newRadius + moveTangent * (walkSpeed * dt)
	local charLook = (moveTangent.Magnitude > 0.08) and moveTangent.Unit or tangentForward
	local orthoRight = charLook:Cross(upNormal).Unit
	local orthoLook = upNormal:Cross(orthoRight).Unit
	local alignedCF = CFrame.fromMatrix(finalPos, orthoRight, upNormal, -orthoLook)

	root.CFrame = alignedCF
	root.AssemblyLinearVelocity = moveTangent * walkSpeed + upNormal * self.RadialVelocity
	st.Speed = (moveTangent * walkSpeed).Magnitude

	if self.AlignGyro then
		self.AlignGyro.CFrame = alignedCF
	end

	-- Poeira lunar ao caminhar
	if grounded and moveTangent.Magnitude > 0.15 then
		self.StepTimer = self.StepTimer + dt
		if self.StepTimer >= 0.28 then
			self.StepTimer = 0
			self:SpawnStepDust(finalPos - upNormal * 2.8, upNormal, body.Color)
		end
	end
end

function Gravity:Destroy()
	self:DisengagePlanetWalk()
	self.Maid:Clean()
	table.clear(self.DustPool)
end

Cosmos.Modules.Gravity = Gravity
-- CONTINUA NA PARTE 2/4
