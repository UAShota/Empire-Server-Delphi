struct SSector;

struct SPlanet {
	SSector * m_Sector;
	int m_PosX;
	int m_PosY;
	DWORD m_Flag;
	DWORD m_Owner;
	char m_Race;
	char m_PlanetNum;
	int m_Island;	
	int m_IslandCalc;
	short m_ATT;
	int m_OreItem;
	int m_Level;
	int m_LevelBuy;
	SPlanet * m_TmpPlanet;
};

struct SSector {
	SPlanet * m_Planet;
	int m_SectorX;
	int m_SectorY;
	int m_PlanetCnt;
	int m_Infl;
	DWORD m_InflOwner;	
};