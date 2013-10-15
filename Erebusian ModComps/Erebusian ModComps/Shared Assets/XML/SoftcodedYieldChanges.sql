-- I would have done this in XML if I knew how to.
-- Have Firaxis added alter table support for XML?
-- I don't know and even if they have I don't know the syntax.

-- Recreate the whole table just to add YieldType, since it's a foreign key and sqlite doesn't support constraints for ALTER TABLE.
ALTER TABLE Building_ThemingBonuses RENAME TO Building_ThemingBonuses_temp;
CREATE TABLE Building_ThemingBonuses(
	BuildingType TEXT,
	Description TEXT,
	Bonus INT,
	YieldType TEXT,
	SameEra BOOL,
	UniqueEras BOOL,
	MustBeArt BOOL,
	MustBeArtifact BOOL,
	MustBeEqualArtArtifact BOOL,
	RequiresOwner BOOL,
	RequiresAnyButOwner BOOL,
	RequiresSamePlayer BOOL,
	RequiresUniquePlayers BOOL,
	AIPriority INT,
	FOREIGN KEY (BuildingType) REFERENCES Buildings(Type),
	FOREIGN KEY (YieldType) REFERENCES Yields(Type)
);

INSERT INTO Building_ThemingBonuses (BuildingType, Description, Bonus, SameEra, UniqueEras, MustBeArt, MustBeArtifact, MustBeEqualArtArtifact, RequiresOwner, RequiresAnyButOwner, RequiresSamePlayer, RequiresUniquePlayers, AIPriority)
SELECT * FROM Building_ThemingBonuses_temp;
DROP TABLE Building_ThemingBonuses_temp;

-- Additions that uses other yields must be loaded after this line.
-- You can't set yieldtype before this file is loaded anyway.
UPDATE Building_ThemingBonuses SET YieldType = "YIELD_CULTURE";


-- Yields from city connections
ALTER TABLE Yields ADD COLUMN CityConnectionBase INTEGER DEFAULT 0;
ALTER TABLE Yields ADD COLUMN CityConnectionCapitalPopMultiplier INTEGER DEFAULT 0;
ALTER TABLE Yields ADD COLUMN CityConnectionCityPopMultiplier INTERGER DEFAULT 0;

-- The old defines are no longer used, move them to the new system
UPDATE Yields SET CityConnectionBase = (SELECT Defines.value FROM Defines WHERE name = "TRADE_ROUTE_BASE_GOLD") WHERE Type = "YIELD_GOLD";
UPDATE Yields SET CityConnectionCapitalPopMultiplier = (SELECT Defines.value FROM Defines WHERE name = "TRADE_ROUTE_CAPITAL_POP_GOLD_MULTIPLIER") WHERE Type = "YIELD_GOLD";
UPDATE Yields SET CityConnectionCityPopMultiplier = (SELECT Defines.value FROM Defines WHERE name = "TRADE_ROUTE_CITY_POP_GOLD_MULTIPLIER") WHERE Type = "YIELD_GOLD";

-- Yield modifier on player level from golden age
ALTER TABLE Yields ADD COLUMN GoldenAgePlayerYieldMod INTEGER DEFAULT 0;

UPDATE Yields SET GoldenAgePlayerYieldMod = (SELECT Defines.value FROM Defines WHERE name = "GOLDEN_AGE_CULTURE_MODIFIER") WHERE Type = "YIELD_CULTURE";