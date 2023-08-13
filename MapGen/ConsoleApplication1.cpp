#include "stdafx.h"
#include <cmath>
#include <time.h>
#include <fstream>
#include <windows.h>
#include <math.h>
#include <iostream>
#include "Empire.hpp"

using namespace std;

class inno {
	bool m_CotlType = true;

	int PlanetFlagHomeworld = 1;

	int PlanetFlagWormholePrepare = 8;
	int PlanetFlagWormholeOpen = 16;
	int PlanetFlagWormholeClose = 32;
	int PlanetFlagStabilizer = 128;

	int PlanetFlagCitadel = 256;

	int PlanetFlagLarge = 2;
	int PlanetFlagWormhole = 4;
	int PlanetFlagSun = 2048;
	int PlanetFlagGigant = 4096;

	bool TypeUser = true;
	bool TypeRich = false;

	int DefaultJumpRadius = 100;
	int PlanetOnSectorMaxSys = 4;
	int SectorSize = 100;
	int PlanetMinDist = 50;
	int PlanetOnSectorMin = 1;

	unsigned int PlanetTmpCold = 0;
	unsigned int PlanetTmpCalid = 1;
	unsigned int PlanetTmpHot = 2;

	unsigned int PlanetTecPassive = 0;
	unsigned int PlanetTecDynamic = 1;
	unsigned int PlanetTecSeismic = 2;

	unsigned int PlanetAtmNone = 0;
	unsigned int PlanetAtmHydrogen = 1;
	unsigned int PlanetAtmAcid = 2;
	unsigned int PlanetAtmOxigen = 3;
	unsigned int PlanetAtmNitric = 4;

	int m_SectorMinX;
	int m_SectorMinY;
	SSector * m_Sector;
	SPlanet * m_Planet;
	int m_SectorCntY;
	int m_SectorCntX;
	int m_CotlSize;
	int m_CntClear;
	bool m_Ready;
	int m_ReadyGTime;
	int m_ExitTestGTime;
	int m_HyperPortalLastTime;

	bool m_PlanetGrow;
	bool m_SessionPeriod;

	int m_ProtectKillMass = 0;
	int m_ProtectTime = 0;
	int m_PlanetDestroy = 0;

	int         m_NewShipId = 2;
	int         m_NewShipIdUser = 3;
	int         m_ScorePeriod = 0;
	int         m_GameState = 0;
	bool         m_PortalShipNoAccess = false;
	int         m_GameTime = 0;
	int         m_WorldVer = 0;
	int         m_StateVer = 0;
	int         m_HelpAtkId = 0;
	int         m_ActiveAtkId = 0;
	int         m_Occupancy = 0;
	int         m_OpsAnm = 1;
	int         m_OpsFlag = 0;
	int         m_OpsModuleMul = 1;
	int         m_OpsModuleAdd = 10;
	int         m_OpsCostBuildLvl = 256;
	int         m_OpsSpeedCapture = 1;
	int         m_OpsSpeedBuild = 256;
	int         m_OpsRestartCooldown = 0;
	int         m_OpsStartTime = 0;
	int         m_OpsPulsarActive = 0;
	int         m_OpsPulsarPassive = 0;
	int         m_OpsWinScore = 0;
	int         m_OpsRewardExp = 0;
	int         m_OpsMaxRating = 0;
	int         m_OpsPriceEnter = 0;
	int         m_OpsPriceEnterType = 0;
	int         m_OpsPriceCapture = 0;
	int         m_OpsPriceCaptureType = 0;
	int         m_OpsPriceCaptureEgm = 0;
	int         m_OpsProtectCooldown = 0;
	int         m_OpsTeamOwner = -1;
	int         m_OpsTeamEnemy = -1;
	int         m_OpsJumpRadius;
	int         JumpRadius2;


#define ATT(atm,tmp,tect,l1,l2,l3) (atm)|((tmp)<<3)|((tect)<<5)|((l1)<<7)|((l2)<<10)|((l3)<<13)

	void ERROR_E()
	{
		__halt();
	}

	SSector * GetSector(int x, int y)
	{
		if ((x < m_SectorMinX) || (abs(x) >= abs(m_SectorMinX)) || (y < m_SectorMinY) || (abs(y) >= abs(m_SectorMinY)))
			return NULL;
		else {
			x += abs(m_SectorMinX);
			y += abs(m_SectorMinY);
			return &m_Sector[x + y * m_SectorCntY];
		}
	}

	void * HAllocClear(size_t asize)
	{
		int *  a = (int *)malloc(asize);
		memset(a, 0, asize);
		return a;
	}

	void * HAlloc(size_t asize)
	{
		return malloc(asize);
	}

	void ATTRnd()
	{
		int cnt, i, u;
		SSector * sec;
		SPlanet * planet;

		cnt = m_SectorCntX*m_SectorCntY;
		sec = m_Sector;
		for (i = 0; i < cnt; i++, sec++) {
			planet = sec->m_Planet;
			for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
				if (planet->m_Flag & (PlanetFlagWormhole | PlanetFlagSun)) planet->m_ATT = 0;
				else if ((planet->m_Flag & (PlanetFlagGigant | PlanetFlagLarge)) == (PlanetFlagGigant | PlanetFlagLarge)) planet->m_ATT = ATT(PlanetAtmHydrogen, 0, 0, 0, 0, 0);
				else if (planet->m_Flag & PlanetFlagGigant) planet->m_ATT = 0;
				else {
					int atm = Rnd(0, 100);
					if (atm < 25) atm = PlanetAtmNone;
					else if (atm < 50) atm = PlanetAtmAcid;
					else if (atm < 75) atm = PlanetAtmOxigen;
					else atm = PlanetAtmNitric;

					planet->m_ATT = ATT(
						atm,
						Rnd(PlanetTmpCold, PlanetTmpHot),
						Rnd(PlanetTecPassive, PlanetTecSeismic),
						Rnd(0, 1),
						Rnd(0, 1),
						Rnd(0, 1)
						);
				}
			}
		}
	}

	int AssignOreItemSec(int secx, int secy, int r, int cnt, int itemtype)
	{
		int i, u, x, y;
		int sc = 0;

		int sx = secx - r; if (sx<m_SectorMinX) sx = m_SectorMinX;
		int sy = secy - r; if (sy<m_SectorMinY) sy = m_SectorMinY;
		int ex = secx + r + 1; if (ex>m_SectorMinX + m_SectorCntX) ex = m_SectorMinX + m_SectorCntX;
		int ey = secy + r + 1; if (ey>m_SectorMinY + m_SectorCntY) ey = m_SectorMinY + m_SectorCntY;

		while (cnt > 0) {
			cnt--;

			for (i = 0; i<100; i++) {
				x = Rnd(sx, ex - 1);
				y = Rnd(sy, ey - 1);

				SSector * sec = m_Sector + ((x - m_SectorMinX) + (y - m_SectorMinY)*m_SectorCntX);
				if (sec->m_InflOwner) continue;
				if (sec->m_PlanetCnt <= 0) continue;
				if (sec->m_PlanetCnt>1) u = Rnd(0, sec->m_PlanetCnt - 1);
				else u = 0;
				if (u < 0 || u >= sec->m_PlanetCnt) ERROR_E();
				SPlanet * planet = sec->m_Planet + u;
				if (planet->m_Flag & (PlanetFlagWormhole | PlanetFlagSun | PlanetFlagGigant)) continue;
				if (planet->m_OreItem) continue;

				planet->m_OreItem = itemtype;
				sc++;
			}
			if (i >= 100) break;
		}
		return sc;
	}

	void Clear()
	{
		m_CntClear++;

		m_Ready = false;
		m_ReadyGTime = 0;
		m_ExitTestGTime = 0;

		m_HyperPortalLastTime = 0;

		//		GangClearAll();

		if (m_Sector) {
			SSector * sec = m_Sector;
			free(m_Sector);
			m_Sector = NULL;
		}
		if (m_Planet) {
			free(m_Planet);
			m_Planet = NULL;
		}
		m_PlanetGrow = false;
		//	if(m_SectorSaveDataAll) {
		//		HFree(m_SectorSaveDataAll,m_Heap);
		//		m_SectorSaveDataAll=NULL;
		//	}
		//	m_SectorSaveDataEmpty=NULL;
		m_SectorMinX = 0;
		m_SectorMinY = 0;
		m_SectorCntX = 0;
		m_SectorCntY = 0;
		m_NewShipId = 2;
		m_NewShipIdUser = 3;
		m_ScorePeriod = 0;
		m_GameState = 0;
		m_PortalShipNoAccess = false;
		m_GameTime = 0;
		m_WorldVer = 0;
		m_StateVer = 0;
		m_HelpAtkId = 0;
		m_ActiveAtkId = 0;

		m_Occupancy = 0;

		m_OpsAnm = 1;
		m_OpsFlag = 0;
		m_OpsModuleMul = 1;
		m_OpsModuleAdd = 10;
		m_OpsCostBuildLvl = 256;
		m_OpsSpeedCapture = 1;
		m_OpsSpeedBuild = 256;
		m_OpsRestartCooldown = 0;
		m_OpsStartTime = 0;
		m_OpsPulsarActive = 0;
		m_OpsPulsarPassive = 0;
		m_OpsWinScore = 0;
		m_OpsRewardExp = 0;
		m_OpsMaxRating = 0;
		m_OpsPriceEnter = 0;
		m_OpsPriceEnterType = 0;
		m_OpsPriceCapture = 0;
		m_OpsPriceCaptureType = 0;
		m_OpsPriceCaptureEgm = 0;
		m_OpsProtectCooldown = 0;
		m_OpsTeamOwner = -1;
		m_OpsTeamEnemy = -1;
		m_OpsJumpRadius = DefaultJumpRadius;
		JumpRadius2 = m_OpsJumpRadius*m_OpsJumpRadius;

		m_ProtectKillMass = 0;
		m_ProtectTime = 0;
		m_PlanetDestroy = 0;
	}

	void CreateSector(int cntx, int cnty, int planetcnt)
	{
		//		GangClearAll();

		m_SectorCntX = cntx;
		m_SectorCntY = cnty;
		int cnt = m_SectorCntX*m_SectorCntY;
		m_Sector = (SSector *)HAllocClear(cnt*sizeof(SSector));

		m_Planet = (SPlanet *)HAllocClear(planetcnt*sizeof(SPlanet));
		m_PlanetGrow = (planetcnt >= cnt*PlanetOnSectorMaxSys);
	}

	void AllConvertToSun()
	{
		int i, u, cnt, ccc;
		SSector * sec;
		SPlanet * planet;

		cnt = m_SectorCntX*m_SectorCntY;
		sec = m_Sector;
		for (i = 0; i < cnt; i++, sec++) {
			SPlanet * normalplanet = NULL;
			SPlanet * sunplanet = NULL;

			planet = sec->m_Planet;
			for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
				if (planet->m_Flag & (PlanetFlagSun | PlanetFlagGigant)) { sunplanet = planet; break; }
				if (planet->m_Flag & (PlanetFlagHomeworld | PlanetFlagCitadel)) { normalplanet = planet; break; }
				if (planet->m_Flag & (PlanetFlagWormhole | PlanetFlagSun | PlanetFlagGigant)) continue;

				if (!normalplanet) {
					normalplanet = planet;
					ccc = 1;
				}
				else {
					ccc++;
					int kv = 10000 / ccc;
					if (Rnd(0, 10000) <= kv) { normalplanet = planet; }
				}
			}
			if (sunplanet) continue;
			if (!normalplanet) continue;

			planet = sec->m_Planet;
			for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
				if (planet == normalplanet) continue;
				if (planet->m_Flag & (PlanetFlagWormhole | PlanetFlagSun | PlanetFlagGigant)) continue;
				if (planet->m_Flag & (PlanetFlagHomeworld | PlanetFlagCitadel)) continue;

				//ALogFormat("!!!TestSun <i>,<i>,<i>",planet->m_Sector->m_SectorX,planet->m_Sector->m_SectorY,planet->m_PlanetNum);
				if (!TestConvertToSun(planet, 1)) continue;
				if (!TestConvertToSun(planet, 10)) continue;
				//ALogFormat("!!!TestSun OK");

				if (!sunplanet) {
					sunplanet = planet;
					ccc = 1;
				}
				else {
					ccc++;
					int kv = 10000 / ccc;
					if (Rnd(0, 10000) <= kv) { sunplanet = planet; }
				}

			}

			if (sunplanet) {
				planet = sunplanet;

				if (FindNearPlanetFlag(planet, SectorSize + (SectorSize >> 1), PlanetFlagSun)) {
					planet->m_Flag |= PlanetFlagGigant;
				}
				else {
					planet->m_Flag |= PlanetFlagSun;
					planet->m_Flag &= ~PlanetFlagLarge;
				}
				planet->m_Owner = 0;
				planet->m_Race = 0;
				planet->m_OreItem = 0;
				planet->m_Level = 0;
				planet->m_LevelBuy = 0;
			}
		}
	}

	SPlanet * FindNearPlanetFlag(SPlanet * planet, int maxd, int flag)
	{
		int i, x, y;
		SSector * sec;
		SPlanet * planet3;

		int cs = 2 + maxd / SectorSize;
		maxd *= maxd;

		int sx2 = planet->m_Sector->m_SectorX - cs; if (sx2<m_SectorMinX) sx2 = m_SectorMinX;
		int sy2 = planet->m_Sector->m_SectorY - cs; if (sy2<m_SectorMinY) sy2 = m_SectorMinY;
		int ex2 = planet->m_Sector->m_SectorX + cs + 1; if (ex2>m_SectorMinX + m_SectorCntX) ex2 = m_SectorMinX + m_SectorCntX;
		int ey2 = planet->m_Sector->m_SectorY + cs + 1; if (ey2>m_SectorMinY + m_SectorCntY) ey2 = m_SectorMinY + m_SectorCntY;

		SPlanet * planetnear = NULL;
		int md;

		sec = m_Sector + ((sx2 - m_SectorMinX) + (sy2 - m_SectorMinY)*m_SectorCntX);
		for (y = sy2; y < ey2; y++, sec += m_SectorCntX - (ex2 - sx2)) {
			for (x = sx2; x < ex2; x++, sec++) {
				planet3 = sec->m_Planet;
				for (i = 0; i<sec->m_PlanetCnt; i++, planet3++)  {
					if (!(planet3->m_Flag & flag)) continue;

					int dx = planet3->m_PosX - planet->m_PosX;
					int dy = planet3->m_PosY - planet->m_PosY;

					int rr = dx*dx + dy + dy;
					if (rr>maxd) continue;

					if (!planetnear || rr < md) {
						planetnear = planet3;
						md = rr;
					}
				}
			}
		}
		return planetnear;
	}

public: void CreateMap(int sx, int sy)
{
			int i, u, x, y, cnt;
			SSector * sec;
			SPlanet * planet;

			if (sx<10) sx = 10;
			else if (sx>500) sx = 500;
			//	else if(sx>100) sx=100;
			if (sy<10) sy = 10;
			else if (sy>500) sy = 500;
			//	else if(sy>100) sy=100;

			while (true) {
				Clear();

				m_SectorMinX = -sx / 2;
				m_SectorMinY = -sy / 2;

				//m_Sector=(SSector *)HAllocClear(cnt*sizeof(SSector),m_Heap);
				CreateSector(sx, sy, sx*sy*PlanetOnSectorMaxSys);

				//ALogFormat("!!!CM00");
				int planetnewcnt = 0;
				sec = m_Sector;
				for (y = 0; y < m_SectorCntY; y++) {
					for (x = 0; x < m_SectorCntX; x++, sec++) {
						sec->m_Planet = m_Planet + planetnewcnt;
						planetnewcnt += PlanetOnSectorMaxSys;
					}
				}
				if (planetnewcnt != m_SectorCntX*m_SectorCntY*PlanetOnSectorMaxSys) ERROR_E();

				//ALogFormat("!!!CM01");
				InitPtr();

				cnt = m_SectorCntX*m_SectorCntY;

				if (!FillPlanet()) continue;

				SSector * ss = m_Sector;

				//ALogFormat("!!!CM02");
				if (!PulsarClearNear()) ERROR_E();

				//ALogFormat("!!!CM03");
				CreateWormhole();

				if (m_CotlType == TypeUser) {
					if (!TestConnectAllPlanet(false)) continue;
					AllConvertToSun();
					if (!TestConnectAllPlanet(false)) continue;
				}
				else {
					if (!TestConnectAllPlanet(true)) continue;
					AllConvertToSun();
					if (!TestConnectAllPlanet(true)) continue;
				}

				int all_suncnt = 0;
				int all_normalcnt = 0;
				int all_othercnt = 0;
				int all_wormholecnt = 0;

				//ALogFormat("!!!CM04");
				// Print stat
				cnt = m_SectorCntX*m_SectorCntY;
				sec = m_Sector;
				for (i = 0; i < cnt; i++, sec++) {
					planet = sec->m_Planet;
					for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
						if (planet->m_Flag & PlanetFlagWormhole) all_wormholecnt++;
						else if (planet->m_Flag & PlanetFlagSun) all_suncnt++;
						else if (planet->m_Flag & PlanetFlagGigant) all_othercnt++;
						else all_normalcnt++;
					}
				}

				if (m_CotlType == TypeUser) {
					//			if(all_normalcnt<400 || all_normalcnt>500) continue;
					//            if(all_normalcnt<460) continue;
					//            if(all_wormholecnt<80) continue;
					if (all_normalcnt < 400) continue;
				}

				break;
			}

			AssignOreItem();

			ATTRnd();

			SSector * ss = m_Sector;
			FILE *f;
			string a;
			f = fopen("d:\\2.txt", "w");
			char * argv = new char[255];    //наш массив символов для хранения числа
			for (int y = 0; y < m_SectorCntY; y++){
				fputs("\n", f);
				for (int x = 0; x < m_SectorCntX; x++, ss++)
				{
					int a = ss->m_PlanetCnt;
					if (a == -1)
						fputs(" ", f);
					else
					if (a == 1)
						fputs("@", f);
					else
					if (a == 0)
						fputs(".", f);
					else {
						_itoa(a, argv, 10);
						fputs(argv, f);
					}
					fputs(" ", f);
				}
			}
			fclose(f);

			ss = m_Sector;
			f = fopen("d:\\3.txt", "w");
			for (int y = 0; y < m_SectorCntY; y++){

				for (int x = 0; x < m_SectorCntX; x++, ss++)
				{
					int a = ss->m_PlanetCnt;
					SPlanet * sp = ss->m_Planet;
					for (int zz = 0; zz < a; zz++, sp++)
					{

						fputs("(", f);
						fputs("1,", f);
						fputs("1,", f);

						_itoa(sp->m_PosX + abs(m_SectorMinX * SectorSize), argv, 10);
						fputs(argv, f);
						fputs(",", f);
						_itoa(sp->m_PosY + abs(m_SectorMinY * SectorSize), argv, 10);
						fputs(argv, f);
						fputs(",", f);


						//int PlanetFlagLarge = 2;
						//int PlanetFlagWormhole = 4;
						//int PlanetFlagSun = 2048;
						//int PlanetFlagGigant = 4096;

						if (sp->m_Flag == (PlanetFlagSun | PlanetFlagLarge))
							fputs("7", f);
						else
						if (sp->m_Flag == PlanetFlagLarge)
							fputs("1", f);
						else
						if (sp->m_Flag == (PlanetFlagLarge | PlanetFlagGigant))
							fputs("4", f);
						else
						if (sp->m_Flag == PlanetFlagGigant)
							fputs("2", f);
						else
						if (sp->m_Flag == PlanetFlagSun)
							fputs("3", f);
						else
						if (sp->m_Flag == PlanetFlagWormhole)
							fputs("6", f);
						else
						if (sp->m_Flag == 0)
							fputs("5", f);

						fputs("),", f);
						fputs("\n", f);
					}
				}
			}
			fclose(f);
}

		void CreateWormhole()
		{
			if (!m_PlanetGrow) ERROR_E();
			int i, u, t, px, py, cnt;
			SSector * sec;
			SPlanet * planet;

			//ALogFormat("CreateWormhole Begin");

			int deadspace = 50;

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				if (sec->m_PlanetCnt <= 0 || sec->m_PlanetCnt >= PlanetOnSectorMaxSys) continue;
				planet = sec->m_Planet;
				for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
					if (planet->m_Flag & PlanetFlagWormhole) break;
					if ((planet->m_Flag & (PlanetFlagSun | PlanetFlagLarge)) == (PlanetFlagSun | PlanetFlagLarge)) break;
				}
				if (u < sec->m_PlanetCnt) continue;

				//ALogFormat("Sector <i>,<i>",sec->m_SectorX,sec->m_SectorY);
				for (t = 0; t < 1000; t++) {
					px = Rnd(PlanetMinDist / 4, SectorSize - PlanetMinDist / 4) + int(sec->m_SectorX)*SectorSize;
					py = Rnd(PlanetMinDist / 4, SectorSize - PlanetMinDist / 4) + int(sec->m_SectorY)*SectorSize;

					if (!IsCorrectPlaceForPlanet(px, py, sec->m_SectorX, sec->m_SectorY, deadspace)) continue;

					break;
				}
				if (t >= 1000) continue;

				planet = sec->m_Planet + sec->m_PlanetCnt;
				sec->m_PlanetCnt++;
				planet->m_PosX = px;
				planet->m_PosY = py;
				planet->m_Flag = PlanetFlagWormhole;
				planet->m_Level = 0;
				planet->m_LevelBuy = 0;
				planet->m_Race = 0;
				planet->m_OreItem = 0;
			}
		}

		bool IsCorrectPlaceForPlanet(int x, int y, int secx, int secy, int deadspace)
		{
			//	int deadspace=50;

			int mr2 = PlanetMinDist*PlanetMinDist;

			int cnt = (m_OpsJumpRadius + deadspace) / SectorSize + 1;
			int fsx = max(m_SectorMinX, secx - cnt);
			int fsy = max(m_SectorMinY, secy - cnt);
			int esx = min(m_SectorMinX + m_SectorCntX, secx + cnt + 1);
			int esy = min(m_SectorMinY + m_SectorCntY, secy + cnt + 1);

			int ds2min = (m_OpsJumpRadius - deadspace)*(m_OpsJumpRadius - deadspace);
			int ds2max = (m_OpsJumpRadius + deadspace)*(m_OpsJumpRadius + deadspace);

			SSector * cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
			for (int sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
				for (int sx = fsx; sx < esx; sx++, cursec++) {
					SPlanet * planet = cursec->m_Planet;
					for (int u = 0; u < cursec->m_PlanetCnt; u++, planet++) {
						if (planet == nullptr) continue;
						int tx = x - planet->m_PosX;
						int ty = y - planet->m_PosY;
						int r = tx*tx + ty*ty;
						if (r < mr2) {
							//if(secx==-48 && secy==-47) {
							//ALogFormat("    r=<i> <i> Planet=<i>,<i>,<i>/<i>",r,mr2,cursec->m_SectorX,cursec->m_SectorY,u,cursec->m_PlanetCnt);
							//}
							return false;
						}

						//if(t==0) {
						//if (r>ds2min && r < ds2max) return false;
						//}

						//if(t==0) {
						//if (r<ds2max) {
						//	if (((secx - sx)>1) || ((secx - sx)<-1) || ((secy - sy)>1) || ((secy - sy) < -1)) {
						//						/*if(r<ds2max)*/ return false;
						//}
						//	}
						//}
					}
				}
			}

			return true;
		}

		void AssignOreItem()
		{
			int i, x, y, u, r, cnt, itemtype;
			SSector * sec;
			SPlanet * planet;

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				if (sec->m_InflOwner) continue;
				planet = sec->m_Planet;
				for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
					planet->m_OreItem = 0;
				}
			}

			int misscnt = 0;
			while (misscnt < 100) {
				x = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
				y = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);

				r = Rnd(0, 100);
				if (r < 33) itemtype = 1;
				else if (r < 66) itemtype = 2;
				else itemtype = 3;

				if (!AssignOreItemSec(x, y, 1, 5, itemtype)) {
					misscnt++;
				}
				else {
					misscnt = 0;
				}
				//ALogFormat("MissCnt=<i>",misscnt);
			}
		}

		void InitPtr()
		{
			int x, y, i;

			SSector * sec = m_Sector;
			for (y = 0; y < m_SectorCntY; y++) {
				for (x = 0; x < m_SectorCntX; x++, sec++) {
					sec->m_SectorX = x + m_SectorMinX;
					sec->m_SectorY = y + m_SectorMinY;

					SPlanet * planet = sec->m_Planet;
					for (i = 0; i < IF(m_PlanetGrow, PlanetOnSectorMaxSys, sec->m_PlanetCnt); i++, planet++) {
						planet->m_Sector = sec;
						planet->m_PlanetNum = i;
					}
				}
			}
		}

		int IF(bool a, int b, int c)
		{
			if (a)
				return b; else return c;
		}

		bool FillPlanet()
		{
			int i, u, t, x, y, px, py, cnt, k;
			SSector * sec;
			SPlanet * planet;

			//ALogFormat("!!!FP00");
			if (m_CotlType == TypeUser) {
				// Создаем внешние границы
				while (true) {
					cnt = m_SectorCntX*m_SectorCntY;
					sec = m_Sector;
					for (i = 0; i < cnt; i++, sec++) {
						sec->m_Infl = 0;
						sec->m_InflOwner = 0;
						sec->m_PlanetCnt = -1;
					}

					int linecnt = (m_SectorCntX + m_SectorCntY) / 8;
					if (linecnt <= 0) linecnt = 1;
					int linesize = 5;

					int inr = max(m_SectorCntX, m_SectorCntY) / 2;

					//ALogFormat("!!!FP00.00");
					for (i = 0; i<linecnt; i++) {
						int x1 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y1 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						if ((x1*x1 + y1*y1)>inr*inr) continue;

						int x2 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y2 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						if ((x2*x2 + y2*y2) > inr*inr) continue;

						int r = (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1);
						int d = inr >> 2;

						if (i == 0);
						else d = (d >> 1) + (d >> 2);

						if (r < d*d) { i--; continue; }

						FillLineSpecial(x1, y1, x2, y2, Rnd(3, 5), Rnd(3, 5), 0);
						//ALogFormat("!!!FLS<i> <i>,<i>,<i>,<i>",i,x1,y1,x2,y2);
					}

					//ALogFormat("!!!FP00.01");
					int cggg = 0;
					for (i = 0; i < linecnt; i++) {
						cggg++;
						if (cggg >= m_SectorCntY * m_SectorCntX * 10000) break;
						int x1 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y1 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						int x2 = x1 + Rnd(-20, 20);
						int y2 = y1 + Rnd(-20, 20);
						int r = (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1);

						if (r < 3 * 3) { i--; continue; }
						if (r >= 5 * 5) { i--; continue; }

						sec = GetSector(x1, y1);
						if (sec == NULL) { i--; continue; }
						if (sec->m_PlanetCnt != -1) { i--; continue; }

						sec = GetSector(x2, y2);
						if (sec == NULL) { i--; continue; }
						if (sec->m_PlanetCnt != 0) { i--; continue; }

						FillLineSpecial(x1, y1, x2, y2, Rnd(2, 4), Rnd(2, 4), 0);
					}
					//printf("!!!FLS%d %d, %d, %d, %d\n", i, x1, y1, x2, y2);
					if (cggg >= m_SectorCntY * m_SectorCntX * 10000) continue;
					//ALogFormat("!!!FP00.02 <i>",cggg);

					int cntb = CalcCntBound();
					//ALogFormat("!!!CntBound <i>",cntb);

					printf("Count: %d for %d\n", cntb, (m_SectorCntX*m_SectorCntY) / 7);

					if (cntb < ((m_SectorCntX*m_SectorCntY) / 7)) continue;
					//if (cntb<260) continue;

					break;
				}

				//ALogFormat("!!!FP01");

				//
				int island = 1;

				cnt = m_SectorCntX*m_SectorCntY;
				int islandignoresize = cnt;
				byte * islandignore = (byte *)HAllocClear(islandignoresize*islandignoresize);

				for (i = 0; i < cnt; i++) {
					x = Rnd(m_SectorMinX + 2, m_SectorMinX + m_SectorCntX - 3);
					y = Rnd(m_SectorMinY + 2, m_SectorMinY + m_SectorCntY - 3);

					if (FindGate(x, y, 5)) continue;
					if (FindBorder(x, y, 3)) continue;
					if (!AddGate2(x, y, island, island + 1)) continue;
					islandignore[island + (island + 1)*islandignoresize] = 1;
					islandignore[(island + 1) + island*islandignoresize] = 1;
					island += 2;
				}
				int * islandsize = (int *)HAlloc(island*sizeof(int)+island * 2 * sizeof(int));
				int * islandborder = islandsize + island;
				//ALogFormat("!!!FP02");


				int islandmaxsize = 2000;
				for (t = 0; t < 10000; t++) {
					GrowGateIsland(1000000);

					CalcGateIslandSize(islandsize, island);

					int mins = 1000000000;

					while (true) {
						mins = 1000000000;
						u = -1;
						for (i = 1; i<island; i++) {
							if (islandsize[i]>0 && islandsize[i] < mins) { mins = islandsize[i]; u = i; }
						}
						//ALogFormat("!!!CC00 i=<i> s=<i>",u,mins);
						if (u<0) break;
						if (mins>islandmaxsize) break;

						int bordercnt = CalcGateIslandBorder(u, islandborder, island << 1);
						//ALogFormat("!!!CC01 bordercnt=<i>",bordercnt);
						if (bordercnt <= 0) { islandsize[u] = 0; continue; }

						int mini = -1;
						int minb = 0;
						for (k = 0; k<bordercnt; k++) {
							int ci = islandborder[(k << 1) + 0];
							if (islandignore[ci + u*islandignoresize]) continue;
							if (islandsize[u] + islandsize[ci]>islandmaxsize) continue;
							if (mini < 0 || islandborder[(k << 1) + 1] < minb) { minb = islandborder[(k << 1) + 1]; mini = ci; }
						}
						if (mini < 0) { islandsize[u] = 0; continue; }

						ChangeGateIsland(u, mini);
						for (k = 0; k<islandignoresize; k++) {
							islandignore[mini + k*islandignoresize] = max(islandignore[mini + k*islandignoresize], islandignore[u + k*islandignoresize]);
							islandignore[k + mini*islandignoresize] = max(islandignore[k + mini*islandignoresize], islandignore[k + u*islandignoresize]);
						}

						islandsize[u] = 0;

						break;
					}
					if (mins>islandmaxsize) break;
				}


				//ALogFormat("!!!FP03");

				while (true) {
					CalcGateIslandSize(islandsize, island);

					int is0 = -1;
					int is1 = -1;
					int bscore = 0;

					for (u = 0; u < island; u++) {
						int bordercnt = CalcGateIslandBorder(u, islandborder, island << 1);
						for (k = 0; k < bordercnt; k++) {
							int ci = islandborder[(k << 1) + 0];
							int calcdist = CalcGateIslandDist(u, ci);

							if (calcdist < 15) continue;

							int score = islandsize[u] + islandsize[ci];
							if (is0 < 0 || score < bscore) {
								bscore = score;
								is0 = u;
								is1 = ci;
							}
						}
					}
					if (is0 < 0) break;

					ChangeGateIsland(is0, is1);
					GrowGateIsland(1000000);
				}

				//ALogFormat("!!!FP04");

				free(islandsize);
				free(islandignore);

				cnt = m_SectorCntX*m_SectorCntY;
				sec = m_Sector;

				for (i = 0; i < cnt; i++, sec++) {
					sec->m_Infl = 0;
					sec->m_InflOwner = 0;

					if (sec->m_PlanetCnt == -2) sec->m_PlanetCnt = 0;
					else if (sec->m_PlanetCnt == -3) { sec->m_PlanetCnt = 1; }
					else if (sec->m_PlanetCnt == 0) sec->m_PlanetCnt = -1;
				}

				//ALogFormat("!!!CntSector <i>,<i>",cnt0,cnt1);
				//ALogFormat("!!!FP05");

				// Средние объекты
				int e20[256];
				int e20cnt = CreateHoleTempl(e20,
					" xx           \n"
					"  xxxx        \n"
					"     xxxxx    \n"
					"         xxx  \n"
					"           xxx\n"
					);
				int e21[256];
				int e21cnt = CreateHoleTempl(e21,
					"  xxxx    xxxx \n"
					" xx      xx  xx\n"
					"xx      xx     \n"
					"            xxx\n"
					"           xx  \n"
					"          xx   \n"
					);
				int e22[256];
				int e22cnt = CreateHoleTempl(e22,
					" xx   xx  \n"
					"xx   xx   \n"
					" xx     xx\n"
					"  xx    x \n"
					"   xxxx   \n"
					);
				int e23[256];
				int e23cnt = CreateHoleTempl(e23,
					"  xxxx    \n"
					"     xxxx \n"
					"        xx\n"
					"         x\n"
					"         x\n"
					"xxx    xxx\n"
					"  xxxx    \n"
					);
				int e24[1024];
				int e24cnt = CreateHoleTempl(e24,
					"    xxxxxx     \n"
					"  xxxxxxxxxx   \n"
					"  xxxxxxxxxx   \n"
					" xxxxxxxxxxxx  \n"
					"xxxxxxxxxxxxxx \n"
					"xxxxxxxxxxxxxxx\n"
					" xxxxxxxxxxxxxx\n"
					" xxxxxxxxxxxxx \n"
					"  xxxxxxxxxxx  \n"
					"  xxxxxxxxxxx  \n"
					"  xxxxxxxxxx   \n"
					"   xxxxxxx     \n"
					);

			}
			else if (m_SessionPeriod || m_SectorCntX < 10 || m_SectorCntY < 10) {
				// Средние объекты
				int e20[256];
				int e20cnt = CreateHoleTempl(e20,
					"  x               \n"
					"  xx              \n"
					"   xx             \n"
					"    xxx  xx       \n"
					"          xxxx    \n"
					"             xxx  \n"
					);
				int e21[256];
				int e21cnt = CreateHoleTempl(e21,
					"   xxxxx    xxxxx \n"
					"  xx      xxx   xx\n"
					" xx               \n"
					"               xxx\n"
					"   xx         xx  \n"
					"    xxxxx   xxx   \n"
					);
				for (u = 0; u < m_SectorCntX*m_SectorCntY; u++) {
					CreateHole(e20, e20cnt, 5);
					CreateHole(e21, e21cnt, 5);
				}

			}
			else if (m_SessionPeriod || m_SectorCntX < 70 || m_SectorCntY < 70) {
				// Создаем внешние границы
				//ALogFormat("!!!FP01");
				while (true) {
					cnt = m_SectorCntX*m_SectorCntY;
					sec = m_Sector;
					for (i = 0; i<cnt; i++, sec++) {
						sec->m_Infl = 0;
						sec->m_InflOwner = 0;
						sec->m_PlanetCnt = -1;
					}

					int linecnt = (m_SectorCntX + m_SectorCntY) / 8;
					if (linecnt <= 0) linecnt = 1;
					int linesize = 5;
					if (m_CotlSize>50) linesize = 6;

					int inr = max(m_SectorCntX, m_SectorCntY) / 2;

					for (i = 0; i<linecnt; i++) {
						int x1 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y1 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						if ((x1*x1 + y1*y1)>inr*inr) continue;

						int x2 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y2 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						if ((x2*x2 + y2*y2) > inr*inr) continue;

						int r = (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1);
						int d = inr >> 2;

						if (i == 0);
						else d = (d >> 1) + (d >> 2);

						if (r < d*d) { i--; continue; }

						if (m_SectorCntX < 20 || m_SectorCntY < 20) FillLineSpecial(x1, y1, x2, y2, Rnd(1, 2), Rnd(1, 2), 0);
						else if (m_SectorCntX < 50 || m_SectorCntY < 50) FillLineSpecial(x1, y1, x2, y2, Rnd(1, 3), Rnd(1, 3), 0);
						else FillLineSpecial(x1, y1, x2, y2, Rnd(2, 4), Rnd(2, 4), 0);
						//ALogFormat("!!!FLS<i> <i>,<i>,<i>,<i>",i,x1,y1,x2,y2);
					}

					int rndrange = max(m_SectorCntX, m_SectorCntY) / 5;
					if (rndrange < 5) rndrange = 5;

					int crp = 0;
					for (i = 0; i < linecnt && crp < linecnt * 10; i++, crp++) {
						int x1 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y1 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						int x2 = x1 + Rnd(-rndrange, rndrange);
						int y2 = y1 + Rnd(-rndrange, rndrange);
						int r = (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1);

						if (r<5 * 5) { i--; continue; }
						if (r>10 * 10) { i--; continue; }

						sec = GetSector(x1, y1);
						if (sec == NULL) { i--; continue; }
						if (sec->m_PlanetCnt != -1) { i--; continue; }

						sec = GetSector(x2, y2);
						if (sec == NULL) { i--; continue; }
						if (sec->m_PlanetCnt != 0) { i--; continue; }

						if (m_SectorCntX < 30 || m_SectorCntY < 30) FillLineSpecial(x1, y1, x2, y2, Rnd(1, 2), Rnd(1, 2), 0);
						else FillLineSpecial(x1, y1, x2, y2, Rnd(2, 4), Rnd(2, 4), 0);
						//ALogFormat("!!!FLS<i> <i>,<i>,<i>,<i>",i,x1,y1,x2,y2);
					}
					if (crp >= linecnt * 10) continue;

					int cntb = CalcCntBound();
					//ALogFormat("!!!CntBound <i>",cntb);
					if (cntb < ((m_SectorCntX*m_SectorCntY) / 7)) continue;

					break;
				}
				//ALogFormat("!!!FP03");


				int e20[256];
				int e20cnt = CreateHoleTempl(e20,
					"  x               \n"
					"  xx              \n"
					"   xx             \n"
					"    xxx  xx       \n"
					"          xxxx    \n"
					"             xxx  \n"
					);
				int e21[256];
				int e21cnt = CreateHoleTempl(e21,
					"   xxxxx    xxxxx \n"
					"  xx      xxx   xx\n"
					" xx               \n"
					"               xxx\n"
					"   xx         xx  \n"
					"    xxxxx   xxx   \n"
					);
				for (u = 0; u < m_SectorCntX*m_SectorCntY; u++) {
					CreateHole(e20, e20cnt, 5);
					CreateHole(e21, e21cnt, 5);
				}
				//ALogFormat("!!!FP04");

			}
			else {
				//ALogFormat("!!!FP00");
				// Создаем внешние границы
				int subcntb = 0;
				while (true) {
					cnt = m_SectorCntX*m_SectorCntY;
					sec = m_Sector;
					for (i = 0; i < cnt; i++, sec++) {
						sec->m_Infl = 0;
						sec->m_InflOwner = 0;
						sec->m_PlanetCnt = -1;
					}
					//		FillCircleSpecial(0,0,m_SectorCntX/2-1,0);
					//ALogFormat("!!!FP00a");

					int linecnt = (m_SectorCntX + m_SectorCntY) / 8;
					if (linecnt <= 0) linecnt = 1;
					int linesize = 5;//min(m_SectorCntX,m_SectorCntY)/6;
					if (m_CotlSize > 50) linesize = 6;

					int inr = max(m_SectorCntX, m_SectorCntY) / 2;
					int addr = max(m_SectorCntX, m_SectorCntY) / 60;

					for (i = 0; i<linecnt; i++) {
						int x1 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y1 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						if ((x1*x1 + y1*y1)>inr*inr) continue;

						int x2 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y2 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						if ((x2*x2 + y2*y2) > inr*inr) continue;

						int r = (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1);
						int d = inr >> 2;

						if (i == 0);
						else d = (d >> 1) + (d >> 2);

						if (r < d*d) { i--; continue; }

						FillLineSpecial(x1, y1, x2, y2, Rnd(4, 8) + addr, Rnd(4, 8) + addr, 0);
						//ALogFormat("!!!FLS<i> <i>,<i>,<i>,<i>",i,x1,y1,x2,y2);
					}
					//ALogFormat("!!!FP00b");

					for (i = 0; i < linecnt; i++) {
						int x1 = Rnd(m_SectorMinX, m_SectorMinX + m_SectorCntX - 1);
						int y1 = Rnd(m_SectorMinY, m_SectorMinY + m_SectorCntY - 1);
						int x2 = x1 + Rnd(-20, 20);
						int y2 = y1 + Rnd(-20, 20);
						int r = (x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1);

						if (r<5 * 5) { i--; continue; }
						if (r>10 * 10) { i--; continue; }

						sec = GetSector(x1, y1);
						if (sec == NULL) { i--; continue; }
						if (sec->m_PlanetCnt != -1) { i--; continue; }

						sec = GetSector(x2, y2);
						if (sec == NULL) { i--; continue; }
						if (sec->m_PlanetCnt != 0) { i--; continue; }

						FillLineSpecial(x1, y1, x2, y2, Rnd(3, 6), Rnd(3, 6), 0);
						//ALogFormat("!!!FLS<i> <i>,<i>,<i>,<i>",i,x1,y1,x2,y2);
					}

					int cntb = CalcCntBound();
					//ALogFormat("!!!",cntb);
					int needcnt = ((m_SectorCntX*m_SectorCntY) / 7) - subcntb;
					//ALogFormat("!!!FP00c CntBound:<i> need:<i>",cntb,needcnt);
					if (cntb <= needcnt) { subcntb += max(1, needcnt >> 3); continue; }

					break;
				}
				//ALogFormat("!!!FP01");

				// Большие объекты
				int e20[256];
				int e20cnt = CreateHoleTempl(e20,
					"  x                                          \n"
					"  xx                                         \n"
					"   xx                                        \n"
					"    xxx                                      \n"
					"      xxx                                    \n"
					"        xx                                   \n"
					"         xxx                       xxxx      \n"
					"           xxx                  xxxx  xxx    \n"
					"             xxxx           xxxxx       xxxx \n"
					"                xxxxx    xxxx              x \n"
					"                    xxxxxx                   \n"
					);
				int e21[256];
				int e21cnt = CreateHoleTempl(e21,
					"              xxxxx                          \n"
					"           xxxx   xxxx         xxxxx  xx     \n"
					"          xx         xxxx  xxxxx       xx    \n"
					"        xxx             xxxx            x    \n"
					"        x                             xxx    \n"
					"        xx                           xx      \n"
					"         xxx                       xxx       \n"
					"                                xxxx         \n"
					"             xxxx           xxxxx            \n"
					"                xxxxx    xxxx                \n"
					"                    xxxxxx                   \n"
					);
				int e22[256];
				int e22cnt = CreateHoleTempl(e22,
					"                    x                        \n"
					"                    xx                 xxxx  \n"
					"                     x              xxxx     \n"
					"                     x           xxxx        \n"
					"       xxxxx                  xxxx           \n"
					"    xxxx   xxxxxxxx     xxxxxxx              \n"
					"  xxx                                        \n"
					"                   xx xx                     \n"
					"                  xx   xx                    \n"
					"                xxx     xxxxxxx              \n"
					"              xxx                            \n"
					);
				for (u = 0; u < m_SectorCntX*m_SectorCntY; u++) {
					CreateHole(e20, e20cnt, 5);
					CreateHole(e21, e21cnt, 5);
					CreateHole(e22, e22cnt, 5);
				}
				//ALogFormat("!!!FP02");
			}

			//ALogFormat("!!!FP05");
			// Малые линии
			int e01[16];
			int e01cnt = CreateHoleTempl(e01,
				"xx  \n"
				" xx \n"
				"  xx\n"
				);
			int e02[16];
			int e02cnt = CreateHoleTempl(e02,
				"x\n"
				"x\n"
				"x\n"
				);
			int e03[16];
			int e03cnt = CreateHoleTempl(e03,
				"xxx\n"
				);

			for (u = 0; u < m_SectorCntX*m_SectorCntY; u++) {
				CreateHole(e01, e01cnt, 10);
				CreateHole(e02, e02cnt, 10);
				CreateHole(e03, e03cnt, 10);
			}

			// Дырки 1x1
			int e10[16];
			int e10cnt = CreateHoleTempl(e10, "x");
			for (u = 0; u < m_SectorCntX*m_SectorCntY; u++) {
				CreateHole(e10, e10cnt, 10);
			}
			//ALogFormat("!!!FP06");

			//ALogFormat("!!!FP07");
			// Пульсары
			sec = m_Sector;
			cnt = m_SectorCntX*m_SectorCntY;
			for (i = 0; i < cnt; i++, sec++) {
				if (sec->m_PlanetCnt != 1) continue;
				planet = sec->m_Planet;
				planet->m_PosX = sec->m_SectorX*SectorSize + (SectorSize >> 1);
				planet->m_PosY = sec->m_SectorY*SectorSize + (SectorSize >> 1);
				planet->m_Flag |= PlanetFlagSun | PlanetFlagLarge;
				sec->m_PlanetCnt = 1;
			}

			//ALogFormat("!!!FP07");
			//ALogFormat("!!!FP08");
			// Другие объекты
			int prndfrom = PlanetMinDist / 4;
			int prndto = SectorSize - PlanetMinDist / 4;
			int dirfromcenter2 = (SectorSize >> 2)*(SectorSize >> 2);
			int mr2 = PlanetMinDist*PlanetMinDist;

			int deadspace = 50;
			int cntnochangelast = 0;
			int cntnochange = 0;

			bool again = false;
			int cntperpass = 0;
			int loopcnt = 0;
			x = 0;
			y = 0;

			while (true) {
				if (y >= m_SectorCntY) {
					printf("CreateMap CntPerPass=<%d>\n", cntperpass);
					if (!again) break;
					if (cntnochangelast == cntperpass) {
						cntnochangelast = cntperpass;
						cntnochange = 0;
					}
					cntnochange++;
					if (cntnochange > 20 && deadspace == 50) {
						deadspace = 40;
						prndfrom = PlanetMinDist / 6;
						prndto = SectorSize - PlanetMinDist / 6;

					}
					else if (cntnochange > 50 && deadspace == 40) {
						deadspace = 30;
					}
					x = 0;
					y = 0;
					again = false;
					cntperpass = 0;
					loopcnt++;
					//if(loopcnt>500 && cntperpass==1) break;
					if (loopcnt > 1000) return false;
				}
				sec = m_Sector + (x + y*m_SectorCntX);

				if (sec->m_PlanetCnt != 0 || sec->m_InflOwner) {
					x++; if (x >= m_SectorCntX) { x = 0; y++; }
					continue;
				}
				cntperpass++;

				//		sec->m_Infl=0;

				int smex = (x + m_SectorMinX)*SectorSize;
				int smey = (y + m_SectorMinY)*SectorSize;

				//printf("Build sector %d,%d %d\n",x+m_SectorMinX,y+m_SectorMinY,cntperpass);

				//int rrr;
				//for(rrr=0;rrr<10;rrr++) {
				int cntpl = Rnd(PlanetOnSectorMin, PlanetOnSectorMaxSys);
				//ALogFormat("Sector <i> <i>",m_SectorMinX+x,m_SectorMinY+y);

				for (i = 0; i < cntpl; i++) {
					for (t = 0; t < 100; t++) {
						px = Rnd(prndfrom, prndto);
						py = Rnd(prndfrom, prndto);

						//					if(cntpl>2) { // Если планет много то нет смысла в центре размещать
						//						int dcx=px-(SectorSize>>1);
						//						int dcy=py-(SectorSize>>1);
						//						if((dcx*dcx+dcy*dcy)<dirfromcenter2) { t--; continue; }
						//					}

						planet = sec->m_Planet;
						for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
							int tx = px + smex - planet->m_PosX;
							int ty = py + smey - planet->m_PosY;
							if ((tx*tx + ty*ty) < mr2) break;
						}
						//					if(u<sec->m_PlanetCnt) continue;

						if (!IsCorrectPlaceForPlanet(px + smex, py + smey, x + m_SectorMinX, y + m_SectorMinY, deadspace)) continue;

						break;
					}
					if (t >= 100) continue;
					//ALogFormat("    <i> <i> t=<i>",px,py,t);

					planet = sec->m_Planet + sec->m_PlanetCnt;
					planet->m_Flag = 0;
					planet->m_PosX = px + smex;
					planet->m_PosY = py + smey;
					sec->m_PlanetCnt++;
				}
				if (sec->m_PlanetCnt != cntpl) sec->m_PlanetCnt = 0;
				else if (IsConnectAll(x + m_SectorMinX, y + m_SectorMinY)) { sec->m_PlanetCnt = 0; sec->m_Infl++; }
				//}

				if (sec->m_PlanetCnt > 0) {
					x++; if (x >= m_SectorCntX) { x = 0; y++; }
				}
				else {
					again = true;

					if (sec->m_Infl > 8) {
						int fsx = max(m_SectorMinX, x + m_SectorMinX - 2);
						int fsy = max(m_SectorMinY, y + m_SectorMinY - 2);
						int esx = min(m_SectorMinX + m_SectorCntX, x + m_SectorMinX + 3);
						int esy = min(m_SectorMinY + m_SectorCntY, y + m_SectorMinY + 3);

						//ALogFormat("rrr=<i> clear=<i>,<i>,<i>,<i>",rrr,fsx,fsy,esx,esy);
						sec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
						for (int sy = fsy; sy<esy; sy++, sec += m_SectorCntX - (esx - fsx)) {
							for (int sx = fsx; sx<esx; sx++, sec++) {
								if (sec->m_PlanetCnt>0 && (sec->m_Planet->m_Flag & (PlanetFlagSun | PlanetFlagGigant))) continue;
								if (!sec->m_InflOwner && sec->m_PlanetCnt>0) { sec->m_PlanetCnt = 0; sec->m_Infl = 0; }
							}
						}
					}

					x++; if (x >= m_SectorCntX) { x = 0; y++; }
				}
			}

			//ALogFormat("!!!FP09");
			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				if (sec->m_PlanetCnt < 0) sec->m_PlanetCnt = 0;
				//	    allplanetcnt+=sec->m_PlanetCnt;
				sec->m_Infl = 0;
				if (sec->m_InflOwner) continue;

				planet = sec->m_Planet;
				for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
					if (planet->m_Flag & (PlanetFlagSun | PlanetFlagGigant)) {
						planet->m_Level = 0;
						planet->m_LevelBuy = 0;
						planet->m_Race = 0;
						planet->m_OreItem = 0;
					}
					else {
						planet->m_Level = Rnd(5, 10);
						planet->m_LevelBuy = 0;
						planet->m_Race = Rnd(1, 2);
						if (Rnd(0, 100) < 30) planet->m_Flag |= PlanetFlagLarge;
						planet->m_OreItem = 0;
					}
				}
			}
			//ALogFormat("!!!FP10");

			return true;
		}

		bool AddGate2(int x, int y, int island1, int island2)
		{
			if (x - 1 < m_SectorMinX) return false;
			if (x + 1 >= m_SectorMinX + m_SectorCntX) return false;
			if (y - 1 < m_SectorMinY) return false;
			if (y + 1 >= m_SectorMinY + m_SectorCntY) return false;

			SSector * sec = GetSector(x, y);
			sec->m_PlanetCnt = -3;
			SSector * s;

			if (Rnd(0, 99) < 50) {
				s = sec - 1 - m_SectorCntX; s->m_PlanetCnt = -2; s->m_Infl = island1;
				s = sec + 0 - m_SectorCntX; s->m_PlanetCnt = -2; s->m_Infl = island1;
				s = sec + 1 - m_SectorCntX; s->m_PlanetCnt = -2; s->m_Infl = island1;

				s = sec - 1 + m_SectorCntX; s->m_PlanetCnt = -2; s->m_Infl = island2;
				s = sec + 0 + m_SectorCntX; s->m_PlanetCnt = -2; s->m_Infl = island2;
				s = sec + 1 + m_SectorCntX; s->m_PlanetCnt = -2; s->m_Infl = island2;
			}
			else {
				s = sec - m_SectorCntX - 1; s->m_PlanetCnt = -2; s->m_Infl = island1;
				s = sec + 0 - 1; s->m_PlanetCnt = -2; s->m_Infl = island1;
				s = sec + m_SectorCntX - 1; s->m_PlanetCnt = -2; s->m_Infl = island1;

				s = sec - m_SectorCntX + 1; s->m_PlanetCnt = -2; s->m_Infl = island2;
				s = sec + 0 + 1; s->m_PlanetCnt = -2; s->m_Infl = island2;
				s = sec + m_SectorCntX + 1; s->m_PlanetCnt = -2; s->m_Infl = island2;
			}
			return true;
		}

		SSector * FindGate(int x, int y, int r)
		{
			int fsx = max(m_SectorMinX, x - r);
			int fsy = max(m_SectorMinY, y - r);
			int esx = min(m_SectorMinX + m_SectorCntX, x + r + 1);
			int esy = min(m_SectorMinY + m_SectorCntY, y + r + 1);

			SSector * cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
			for (int sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
				for (int sx = fsx; sx<esx; sx++, cursec++) {
					if (cursec->m_PlanetCnt != -3) continue;
					if (((x - sx)*(x - sx) + (y - sy)*(y - sy))>(r*r)) continue;
					return cursec;
				}
			}
			return false;
		}

		SSector * FindBorder(int x, int y, int r)
		{
			int fsx = max(m_SectorMinX, x - r);
			int fsy = max(m_SectorMinY, y - r);
			int esx = min(m_SectorMinX + m_SectorCntX, x + r + 1);
			int esy = min(m_SectorMinY + m_SectorCntY, y + r + 1);

			SSector * cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
			for (int sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
				for (int sx = fsx; sx<esx; sx++, cursec++) {
					if (cursec->m_PlanetCnt != -1) continue;
					if (((x - sx)*(x - sx) + (y - sy)*(y - sy))>(r*r)) continue;
					return cursec;
				}
			}
			return false;
		}

		int CalcCntBound()
		{
			int fsx = m_SectorMinX + 1;
			int fsy = m_SectorMinY + 1;
			int esx = m_SectorMinX + m_SectorCntX - 1;
			int esy = m_SectorMinY + m_SectorCntY - 1;

			int bc = 0;

			SSector * cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
			for (int sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
				for (int sx = fsx; sx < esx; sx++, cursec++) {
					if (cursec->m_PlanetCnt != (cursec - 1)->m_PlanetCnt) bc++;
					else if (cursec->m_PlanetCnt != (cursec + 1)->m_PlanetCnt) bc++;
					else if (cursec->m_PlanetCnt != (cursec - m_SectorCntX)->m_PlanetCnt) bc++;
					else if (cursec->m_PlanetCnt != (cursec + m_SectorCntX)->m_PlanetCnt) bc++;
				}
			}
			return bc;
		}

		int CalcGateIslandBorder(int island, int * islandborder, int bufmaxcnt)
		{
			int i, cnt, k, sy, sx, u;
			SSector * sec, *s, *cursec;

			int bordercnt = 0;
			memset(islandborder, 0, bufmaxcnt*sizeof(int));

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				if (sec->m_PlanetCnt != -2) continue;
				if (sec->m_Infl != island) continue;

				for (k = 0; k < 4; k++) {
					if (k == 0) {
						if (sec->m_SectorX - 1 < m_SectorMinX) continue;
						s = sec - 1;
					}
					else if (k == 1) {
						if (sec->m_SectorX + 1 >= m_SectorMinX + m_SectorCntX) continue;
						s = sec + 1;
					}
					else if (k == 2) {
						if (sec->m_SectorY - 1 < m_SectorMinY) continue;
						s = sec - m_SectorCntX;
					}
					else {
						if (sec->m_SectorY + 1 >= m_SectorMinY + m_SectorCntY) continue;
						s = sec + m_SectorCntX;
					}
					if (s->m_PlanetCnt != 0) continue;

					int fsx = max(m_SectorMinX, s->m_SectorX - 1);
					int fsy = max(m_SectorMinY, s->m_SectorY - 1);
					int esx = min(m_SectorMinX + m_SectorCntX, s->m_SectorX + 2);
					int esy = min(m_SectorMinY + m_SectorCntY, s->m_SectorY + 2);

					cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
					for (sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
						for (sx = fsx; sx < esx; sx++, cursec++) {
							if (cursec == s) continue;

							if (cursec->m_PlanetCnt == -2);
							else if (cursec->m_PlanetCnt == 0);
							else break;
						}
						if (sx < esx) break;
					}
					if (sy < esy) continue;

					cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
					for (sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
						for (sx = fsx; sx < esx; sx++, cursec++) {
							if (cursec == s) continue;

							if (cursec->m_PlanetCnt == -2);
							else if (cursec->m_PlanetCnt == 0) continue;
							else break;

							if (cursec->m_Infl == sec->m_Infl) continue;

							for (u = 0; u < bordercnt; u++) {
								if (islandborder[(u << 1) + 0] == cursec->m_Infl) break;
							}
							if (u < bordercnt) {
								islandborder[(u << 1) + 1]++;
							}
							else {
								if (((bordercnt << 1) + 1) >= bufmaxcnt) ERROR_E();
								islandborder[(bordercnt << 1) + 0] = cursec->m_Infl;
								islandborder[(bordercnt << 1) + 1] = 1;
								bordercnt++;
							}
						}
						if (sx < esx) break;
					}
					if (sy < esy) continue;

				}
			}
			return bordercnt;
		}

		int CalcGateIslandDist(int fromisland, int toisland)
		{
			int cnt, sx, sy, y;
			SSector * sec;

			SSector * * seclist = (SSector * *)HAlloc(m_SectorCntX*m_SectorCntY*sizeof(SSector *));
			int seccnt = 0;

			int lvl = 1;

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (y = 0; y < cnt; y++, sec++) {
				if ((sec->m_PlanetCnt != -2 && sec->m_PlanetCnt != -3) || sec->m_Infl != fromisland) {
					sec->m_InflOwner = 0;
					continue;
				}
				seclist[seccnt] = sec;
				seccnt++;
				sec->m_InflOwner = lvl;
			}

			lvl++;

			int sme = 0;
			int nextlvl = seccnt;
			while (sme < seccnt) {
				sec = seclist[sme];
				sme++;

				int fsx = max(m_SectorMinX, sec->m_SectorX - 1);
				int fsy = max(m_SectorMinY, sec->m_SectorY - 1);
				int esx = min(m_SectorMinX + m_SectorCntX, sec->m_SectorX + 2);
				int esy = min(m_SectorMinY + m_SectorCntY, sec->m_SectorY + 2);

				SSector * cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
				for (sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
					for (sx = fsx; sx < esx; sx++, cursec++) {
						if (cursec == sec) continue;
						if (cursec->m_InflOwner) continue;
						if (cursec->m_PlanetCnt >= 0) continue;

						if (cursec->m_PlanetCnt == -2 && cursec->m_Infl == toisland) { free(seclist); return lvl; }

						cursec->m_InflOwner = lvl;
						seclist[seccnt] = cursec;
						seccnt++;
						if (seccnt >= m_SectorCntX*m_SectorCntY) ERROR_E();
					}
				}

				if (sme >= nextlvl) {
					lvl++;
					nextlvl = seccnt;
				}
			}

			free(seclist);

			return 1000000;
		}

		void CalcGateIslandSize(int * islandsize, int maxislandcnt)
		{
			int i, cnt;
			SSector * sec;

			memset(islandsize, 0, maxislandcnt*sizeof(int));

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				if (sec->m_PlanetCnt != -2) continue;
				if (sec->m_Infl >= maxislandcnt) continue;
				islandsize[sec->m_Infl]++;
			}
		}

		void ChangeGateIsland(int oldisland, int newisland)
		{
			int i, cnt;
			SSector * sec;

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				if (sec->m_PlanetCnt != -2) continue;
				if (sec->m_Infl != oldisland) continue;
				sec->m_Infl = newisland;
			}
		}

		void CreateHole(int * el, int elcnt, int loopcnt)
		{
			int i, x, y, sx, sy, h, swap;
			SSector * sec;

			if (elcnt < 1) ERROR_E();
			int bx = el[0];
			int by = el[1];
			int ex = bx + 1;
			int ey = by + 1;

			int mulx = 1;
			if (Rnd(0, 100) < 50) mulx = -1;
			int muly = 1;
			if (Rnd(0, 100) < 50) muly = -1;
			bool swapxy = false;
			if (Rnd(0, 100) < 50) swapxy = true;

			for (i = 0; i < elcnt; i++) {
				x = el[(i << 1) + 0]; if (mulx < 0) x = -x;
				y = el[(i << 1) + 1]; if (muly < 0) y = -y;
				if (swapxy) { swap = x; x = y; y = swap; }
				bx = min(bx, x);
				by = min(by, y);
				ex = max(ex, x + 1);
				ey = max(ey, y + 1);
			}

			for (h = 0; h < loopcnt; h++) {
				sx = Rnd(m_SectorMinX - bx, m_SectorMinX + m_SectorCntX - ex);
				sy = Rnd(m_SectorMinY - by, m_SectorMinY + m_SectorCntY - ey);
				//ALogFormat("    Sxy=<i>,<i> Cxy=<i>,<i> Bxy=<i>,<i> Exy=<i>,<i>",sx,sy,m_SectorCntX,m_SectorCntY,bx,by,ex,ey);

				for (i = 0; i < elcnt; i++) {
					x = el[(i << 1) + 0]; if (mulx < 0) x = -x;
					y = el[(i << 1) + 1]; if (muly < 0) y = -y;
					if (swapxy) { swap = x; x = y; y = swap; }
					x += sx;
					y += sy;
					if (x < m_SectorMinX || x >= m_SectorMinX + m_SectorCntX) break;//ERROR_E();
					if (y<m_SectorMinY || y >= m_SectorMinY + m_SectorCntY) break;//ERROR_E();

					sec = m_Sector + ((x - m_SectorMinX) + (y - m_SectorMinY)*m_SectorCntX);
					if (sec->m_InflOwner) break;

					if (x>m_SectorMinX && sec[-1].m_PlanetCnt < 0) break;
					if (x < (m_SectorMinX + m_SectorCntX - 1) && sec[+1].m_PlanetCnt<0) break;
					if (y>m_SectorMinY && sec[-m_SectorCntX].m_PlanetCnt < 0) break;
					if (y < (m_SectorMinY + m_SectorCntY - 1) && sec[+m_SectorCntX].m_PlanetCnt < 0) break;
				}
				if (i < elcnt) continue;

				for (i = 0; i < elcnt; i++) {
					x = el[(i << 1) + 0]; if (mulx < 0) x = -x;
					y = el[(i << 1) + 1]; if (muly < 0) y = -y;
					if (swapxy) { swap = x; x = y; y = swap; }
					x += sx;
					y += sy;

					sec = m_Sector + ((x - m_SectorMinX) + (y - m_SectorMinY)*m_SectorCntX);

					sec->m_PlanetCnt = -1;
				}
				break;
			}
		}

		int CreateHoleTempl(int * el, const char * str)
		{
			int cnt = 0;
			int x = 0;
			int y = 0;
			while (true) {
				char ch = *str;
				str++;
				if (ch == 0) break;
				if (ch == '\n') { y++; x = 0; continue; }

				if (ch != ' ') {
					el[0] = x;
					el[1] = y;
					//ALogFormat("    CreateHoleTempl <i> <i>",x,y);
					el += 2;
					cnt++;
				}

				x++;
			}
			return cnt;
		}

		void FillLineSpecial(int x1, int y1, int x2, int y2, int r1, int r2, int v)
		{
			int dx = abs(x2 - x1);
			int dy = abs(y2 - y1);
			int sx = x2 >= x1 ? 1 : -1;
			int sy = y2 >= y1 ? 1 : -1;
			int x = x1;
			int y = y1;

			if (dy <= dx) {
				int d = (dy << 1) - dx;
				int d1 = dy << 1;
				int d2 = (dy - dx) << 1;
				FillCircleSpecial(x, y, r1, v);

				x += sx;
				for (int i = 1; i <= dx; i++, x += sx) {
					if (d > 0) { d += d2; y += sy; }
					else d += d1;
					int r = int(r1 + double(r2 - r1)*double(x - x1) / double(x2 - x1));
					FillCircleSpecial(x, y, r, v);
				}
			}
			else {
				int d = (dx << 1) - dy;
				int d1 = dx << 1;
				int d2 = (dx - dy) << 1;

				y += sy;
				for (int i = 1; i <= dy; i++, y += sy) {
					if (d > 0) { d += d2; x += sx; }
					else d += d1;
					int r = int(r1 + double(r2 - r1)*double(y - y1) / double(y2 - y1));
					FillCircleSpecial(x, y, r, v);
				}
			}
		}

		void FillCircleSpecial(int x, int y, int r, int v)
		{
			r *= r;
			int fsx = max(m_SectorMinX, x - r);
			int fsy = max(m_SectorMinY, y - r);
			int esx = min(m_SectorMinX + m_SectorCntX, x + r + 1);
			int esy = min(m_SectorMinY + m_SectorCntY, y + r + 1);

			SSector * cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
			for (int sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
				for (int sx = fsx; sx<esx; sx++, cursec++) {
					int rr = (sx - x)*(sx - x) + (sy - y)*(sy - y);
					if (rr>r) continue;
					cursec->m_PlanetCnt = v;
				}
			}
		}

		void GrowGateIsland(int cntlvl)
		{
			int cnt, sx, sy, y, k;
			SSector * sec;
			SSector * s;

			SSector * * seclist = (SSector * *)HAlloc(m_SectorCntX*m_SectorCntY*sizeof(SSector *));
			int seccnt = 0;

			int lvl = 1;

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (y = 0; y < cnt; y++, sec++) {
				if (sec->m_PlanetCnt != -2) {
					sec->m_InflOwner = 0;
					continue;
				}
				seclist[seccnt] = sec;
				seccnt++;
				sec->m_InflOwner = lvl;
			}

			lvl++;

			int sme = 0;
			int nextlvl = seccnt;
			while (sme < seccnt) {
				sec = seclist[sme];
				sme++;

				for (k = 0; k < 4; k++) {
					if (k == 0) {
						if (sec->m_SectorX - 1 < m_SectorMinX) continue;
						s = sec - 1;
					}
					else if (k == 1) {
						if (sec->m_SectorX + 1 >= m_SectorMinX + m_SectorCntX) continue;
						s = sec + 1;
					}
					else if (k == 2) {
						if (sec->m_SectorY - 1 < m_SectorMinY) continue;
						s = sec - m_SectorCntX;
					}
					else {
						if (sec->m_SectorY + 1 >= m_SectorMinY + m_SectorCntY) continue;
						s = sec + m_SectorCntX;
					}
					if (s->m_PlanetCnt != 0) continue;

					int fsx = max(m_SectorMinX, s->m_SectorX - 1);
					int fsy = max(m_SectorMinY, s->m_SectorY - 1);
					int esx = min(m_SectorMinX + m_SectorCntX, s->m_SectorX + 2);
					int esy = min(m_SectorMinY + m_SectorCntY, s->m_SectorY + 2);

					SSector * cursec = m_Sector + ((fsx - m_SectorMinX) + (fsy - m_SectorMinY)*m_SectorCntX);
					for (sy = fsy; sy < esy; sy++, cursec += m_SectorCntX - (esx - fsx)) {
						for (sx = fsx; sx < esx; sx++, cursec++) {
							if (cursec == s) continue;

							if (cursec->m_PlanetCnt == 0);
							else if (cursec->m_PlanetCnt == -2 && cursec->m_Infl == sec->m_Infl);
							else break;
						}
						if (sx < esx) break;
					}
					if (sy < esy) continue;

					s->m_PlanetCnt = -2;
					s->m_Infl = sec->m_Infl;
					s->m_InflOwner = lvl;

					seclist[seccnt] = s;
					seccnt++;
					if (seccnt >= m_SectorCntX*m_SectorCntY) ERROR_E();
				}

				if (sme >= nextlvl) {
					lvl++;
					nextlvl = seccnt;
					if (lvl > cntlvl) break;
				}
			}

			free(seclist);
		}

		int IsConnectAll(int secx, int secy)
		{
			bool up_empty = false;
			bool down_empty = false;
			bool left_empty = false;
			bool right_empty = false;

			SSector * sec = m_Sector + ((secx - m_SectorMinX) + (secy - m_SectorMinY)*m_SectorCntX);
			SSector * cursec;

			int r = 0;

			if (secy <= m_SectorMinY) up_empty = true;
			else {
				cursec = sec - m_SectorCntX;
				if (cursec->m_PlanetCnt<0) up_empty = true;
				else if (cursec->m_PlanetCnt>0 && !IsConnectSector(sec, cursec)) {
					if (sec->m_Infl > 3 && !cursec->m_InflOwner) {
						cursec->m_Infl++; if (cursec->m_Infl > 5) { cursec->m_PlanetCnt = 0; cursec->m_Infl = 0; }
					}
					r++;
				}
			}

			if (secy >= m_SectorMinY + m_SectorCntY - 1) down_empty = true;
			else {
				cursec = sec + m_SectorCntX;
				if (cursec->m_PlanetCnt<0) down_empty = true;
				else if (cursec->m_PlanetCnt>0 && !IsConnectSector(sec, cursec)) {
					if (sec->m_Infl > 3 && !cursec->m_InflOwner) {
						cursec->m_Infl++; if (cursec->m_Infl > 5) { cursec->m_PlanetCnt = 0; cursec->m_Infl = 0; }
					}
					r++;
				}
			}

			if (secx <= m_SectorMinX) left_empty = true;
			else {
				cursec = sec - 1;
				if (cursec->m_PlanetCnt<0) left_empty = true;
				else if (cursec->m_PlanetCnt>0 && !IsConnectSector(sec, cursec)) {
					if (sec->m_Infl > 3 && !cursec->m_InflOwner) {
						cursec->m_Infl++; if (cursec->m_Infl > 5) { cursec->m_PlanetCnt = 0; cursec->m_Infl = 0; }
					}
					r++;
				}
			}

			if (secx >= m_SectorMinX + m_SectorCntX - 1) right_empty = true;
			else {
				cursec = sec + 1;
				if (cursec->m_PlanetCnt<0) right_empty = true;
				else if (cursec->m_PlanetCnt>0 && !IsConnectSector(sec, cursec)) {
					if (sec->m_Infl > 3 && !cursec->m_InflOwner) {
						cursec->m_Infl++; if (cursec->m_Infl > 5) { cursec->m_PlanetCnt = 0; cursec->m_Infl = 0; }
					}
					r++;
				}
			}

			// up left
			if (up_empty && left_empty && secy > m_SectorMinY && secx > m_SectorMinX) {
				cursec = sec - m_SectorCntX - 1;
				if (cursec->m_PlanetCnt > 0 && !IsConnectSector(sec, cursec)) {
					if (sec->m_Infl > 3 && !cursec->m_InflOwner) {
						cursec->m_Infl++; if (cursec->m_Infl > 5) { cursec->m_PlanetCnt = 0; cursec->m_Infl = 0; }
					}
					r++;
				}
			}

			// up right
			if (up_empty && right_empty && secy > m_SectorMinY && secx<m_SectorMinX + m_SectorCntX - 1) {
				cursec = sec - m_SectorCntX + 1;
				if (cursec->m_PlanetCnt>0 && !IsConnectSector(sec, cursec)) {
					if (sec->m_Infl > 3 && !cursec->m_InflOwner) {
						cursec->m_Infl++; if (cursec->m_Infl > 5) { cursec->m_PlanetCnt = 0; cursec->m_Infl = 0; }
					}
					r++;
				}
			}

			// down left
			if (down_empty && left_empty && secy<m_SectorMinY + m_SectorCntY - 1 && secx>m_SectorMinX) {
				cursec = sec + m_SectorCntX - 1;
				if (cursec->m_PlanetCnt > 0 && !IsConnectSector(sec, cursec)) {
					if (sec->m_Infl > 3 && !cursec->m_InflOwner) {
						cursec->m_Infl++; if (cursec->m_Infl > 5) { cursec->m_PlanetCnt = 0; cursec->m_Infl = 0; }
					}
					r++;
				}
			}

			// down right
			if (down_empty && right_empty && secy<m_SectorMinY + m_SectorCntY - 1 && secx<m_SectorMinX + m_SectorCntX - 1) {
				cursec = sec + m_SectorCntX + 1;
				if (cursec->m_PlanetCnt>0 && !IsConnectSector(sec, cursec)) {
					if (sec->m_Infl>3 && !cursec->m_InflOwner) {
						cursec->m_Infl++; if (cursec->m_Infl > 5) { cursec->m_PlanetCnt = 0; cursec->m_Infl = 0; }
					}
					r++;
				}
			}

			return r;
		}

		bool IsConnectSector(SSector * sec, SSector * sec2)
		{
			int jr2 = JumpRadius2;

			SPlanet * planet = sec->m_Planet;
			for (int i = 0; i < sec->m_PlanetCnt; i++, planet++) {
				SPlanet * planet2 = sec2->m_Planet;
				for (int u = 0; u < sec2->m_PlanetCnt; u++, planet2++) {
					int x = planet->m_PosX - planet2->m_PosX;
					int y = planet->m_PosY - planet2->m_PosY;

					if ((x*x + y*y) < jr2) return true;
				}
			}
			return false;
		}

		bool PulsarClearNear()
		{
			int i, u, cnt, x, y;
			SSector * sec, *sec2;
			SPlanet * planet;

			//	dword at=my_time_nq();
			//	dword ct=my_time();

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				planet = sec->m_Planet;
				for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
					if ((planet->m_Flag & (PlanetFlagSun | PlanetFlagLarge)) != (PlanetFlagSun | PlanetFlagLarge)) continue;
					break;
				}
				if (u >= sec->m_PlanetCnt) continue;

				if (sec->m_PlanetCnt != 1) return false;

				int sx2 = sec->m_SectorX - 1; if (sx2<m_SectorMinX) sx2 = m_SectorMinX;
				int sy2 = sec->m_SectorY - 1; if (sy2<m_SectorMinY) sy2 = m_SectorMinY;
				int ex2 = sec->m_SectorX + 2; if (ex2>m_SectorMinX + m_SectorCntX) ex2 = m_SectorMinX + m_SectorCntX;
				int ey2 = sec->m_SectorY + 2; if (ey2>m_SectorMinY + m_SectorCntY) ey2 = m_SectorMinY + m_SectorCntY;

				sec2 = m_Sector + ((sx2 - m_SectorMinX) + (sy2 - m_SectorMinY)*m_SectorCntX);
				for (y = sy2; y < ey2; y++, sec2 += m_SectorCntX - (ex2 - sx2)) {
					for (x = sx2; x < ex2; x++, sec2++) {
						planet = sec2->m_Planet;
						for (u = 0; u < sec2->m_PlanetCnt; u++, planet++)  {
							if ((planet->m_Flag & (PlanetFlagSun | PlanetFlagLarge)) == (PlanetFlagSun | PlanetFlagLarge)) continue;
							if (planet->m_Flag & (PlanetFlagSun | PlanetFlagGigant | PlanetFlagWormhole)) continue;

							//ALogFormat("!!!PulsarClearNear");
							planet->m_Flag |= PlanetFlagGigant;
							planet->m_Level = 0;
							planet->m_Race = 0;
							planet->m_LevelBuy = 0;
							planet->m_Race = 0;
							planet->m_OreItem = 0;
							//					planet->m_ConstructionPoint=0;
						}
					}
				}
			}

			return true;
		}

		int Rnd(int a, int b)
		{
			int x, y;
			if (a < b) {
				x = a;
				y = b;
			}
			else{
				x = b;
				y = a;
			}

			int max = abs(a) + abs(b);
			max = rand() % (max + 1);

			int pp = 0;
			int v;

			for (v = x; v < y; v++, pp++){
				if (pp == max)
					break;
			}

			return v;
		}

		bool TestConnectAllPlanet(bool skip_sun_gigant)
		{
			int i, u, cnt, x, y;
			SSector * sec;
			SPlanet * planet, *planet2, *planet3;

			SPlanet * plfirst = NULL;

			cnt = m_SectorCntX*m_SectorCntY;
			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				planet = sec->m_Planet;
				for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
					planet->m_Island = 0;

					if (!plfirst) {
						if (planet->m_Flag & (PlanetFlagWormhole | PlanetFlagSun | PlanetFlagGigant));
						else plfirst = planet;
					}
				}
			}

			SPlanet * * plist = (SPlanet **)HAllocClear(cnt * 4 * sizeof(SPlanet *));

			plist[0] = plfirst;
			int pcnt = 1;
			int psme = 0;
			plfirst->m_Island = 0;

			while (psme < pcnt) {
				planet2 = plist[psme];
				psme++;

				int sx2 = planet2->m_Sector->m_SectorX - 1; if (sx2<m_SectorMinX) sx2 = m_SectorMinX;
				int sy2 = planet2->m_Sector->m_SectorY - 1; if (sy2<m_SectorMinY) sy2 = m_SectorMinY;
				int ex2 = planet2->m_Sector->m_SectorX + 2; if (ex2>m_SectorMinX + m_SectorCntX) ex2 = m_SectorMinX + m_SectorCntX;
				int ey2 = planet2->m_Sector->m_SectorY + 2; if (ey2>m_SectorMinY + m_SectorCntY) ey2 = m_SectorMinY + m_SectorCntY;

				sec = m_Sector + ((sx2 - m_SectorMinX) + (sy2 - m_SectorMinY)*m_SectorCntX);
				for (y = sy2; y < ey2; y++, sec += m_SectorCntX - (ex2 - sx2)) {
					for (x = sx2; x < ex2; x++, sec++) {
						planet3 = sec->m_Planet;
						for (i = 0; i<sec->m_PlanetCnt; i++, planet3++)  {
							if (planet3->m_Flag & (PlanetFlagWormhole)) continue;
							if (skip_sun_gigant && (planet3->m_Flag & (PlanetFlagSun | PlanetFlagGigant))) continue;

							if (planet3->m_Island) continue;

							int dx = planet3->m_PosX - planet2->m_PosX;
							int dy = planet3->m_PosY - planet2->m_PosY;

							if ((dx*dx + dy*dy)>JumpRadius2) continue;

							if (pcnt >= (cnt << 2)) ERROR_E();

							plist[pcnt] = planet3;
							pcnt++;
							planet3->m_Island = 1;
						}
					}
				}
			}

			free(plist);

			bool r = true;

			sec = m_Sector;
			for (i = 0; i < cnt; i++, sec++) {
				planet = sec->m_Planet;
				for (u = 0; u < sec->m_PlanetCnt; u++, planet++) {
					if (planet->m_Flag & (PlanetFlagWormhole)) continue;
					if (skip_sun_gigant && (planet->m_Flag & (PlanetFlagSun | PlanetFlagGigant))) continue;
					if (!planet->m_Island) {
						printf("PlanetConnectError %d %d %d\n", planet->m_Sector->m_SectorX, planet->m_Sector->m_SectorY, planet->m_PlanetNum);
						r = false;
					}
					planet->m_Island = 0;
				}
			}

			return r;
		}

		bool TestConvertToSun(SPlanet * planet, int rs)
		{
			int sx = planet->m_Sector->m_SectorX - rs; if (sx<m_SectorMinX) sx = m_SectorMinX;
			int sy = planet->m_Sector->m_SectorY - rs; if (sy<m_SectorMinY) sy = m_SectorMinY;
			int ex = planet->m_Sector->m_SectorX + rs + 1; if (ex>m_SectorMinX + m_SectorCntX) ex = m_SectorMinX + m_SectorCntX;
			int ey = planet->m_Sector->m_SectorY + rs + 1; if (ey>m_SectorMinY + m_SectorCntY) ey = m_SectorMinY + m_SectorCntY;

			int owner = 0xffffffff;

			int x, y, i;
			SSector * sec;
			SPlanet * planet2, *planet3;

			SPlanet * plist[1024];
			int pcnt;
			int psme;

			sec = m_Sector + ((sx - m_SectorMinX) + (sy - m_SectorMinY)*m_SectorCntX);
			for (y = sy; y < ey; y++, sec += m_SectorCntX - (ex - sx)) {
				for (x = sx; x < ex; x++, sec++) {
					planet3 = sec->m_Planet;
					for (i = 0; i < sec->m_PlanetCnt; i++, planet3++)  {
						planet3->m_Island = 0;
						planet3->m_IslandCalc = 0;
					}
				}
			}

			plist[0] = planet;
			pcnt = 1;
			psme = 0;
			planet->m_Island = 1;

			while (psme < pcnt) {
				planet2 = plist[psme];
				psme++;

				int sx2 = planet2->m_Sector->m_SectorX - 1; if (sx2<m_SectorMinX) sx2 = m_SectorMinX;
				int sy2 = planet2->m_Sector->m_SectorY - 1; if (sy2<m_SectorMinY) sy2 = m_SectorMinY;
				int ex2 = planet2->m_Sector->m_SectorX + 2; if (ex2>m_SectorMinX + m_SectorCntX) ex2 = m_SectorMinX + m_SectorCntX;
				int ey2 = planet2->m_Sector->m_SectorY + 2; if (ey2>m_SectorMinY + m_SectorCntY) ey2 = m_SectorMinY + m_SectorCntY;

				sec = m_Sector + ((sx2 - m_SectorMinX) + (sy2 - m_SectorMinY)*m_SectorCntX);
				for (y = sy2; y < ey2; y++, sec += m_SectorCntX - (ex2 - sx2)) {
					for (x = sx2; x < ex2; x++, sec++) {
						planet3 = sec->m_Planet;
						for (i = 0; i < sec->m_PlanetCnt; i++, planet3++)  {
							if (planet3->m_Flag & (PlanetFlagWormhole | PlanetFlagSun | PlanetFlagGigant)) continue;

							if (planet3->m_Island) continue;

							if (planet3->m_Sector->m_SectorX < sx) continue;
							if (planet3->m_Sector->m_SectorY<sy) continue;
							if (planet3->m_Sector->m_SectorX >= ex) continue;
							if (planet3->m_Sector->m_SectorY >= ey) continue;

							int dx = planet3->m_PosX - planet2->m_PosX;
							int dy = planet3->m_PosY - planet2->m_PosY;

							if ((dx*dx + dy*dy)>JumpRadius2) continue;

							if (pcnt >= 1024) continue;

							plist[pcnt] = planet3;
							pcnt++;
							planet3->m_Island = 1;
						}
					}
				}
			}

			if (pcnt <= 2) return false;
			//ALogFormat("pcnt=<i>",pcnt);

			plist[0] = plist[pcnt - 1];
			pcnt = 1;
			psme = 0;
			planet->m_IslandCalc = 1;

			while (psme < pcnt) {
				planet2 = plist[psme];
				psme++;

				int sx2 = planet2->m_Sector->m_SectorX - 1; if (sx2<m_SectorMinX) sx2 = m_SectorMinX;
				int sy2 = planet2->m_Sector->m_SectorY - 1; if (sy2<m_SectorMinY) sy2 = m_SectorMinY;
				int ex2 = planet2->m_Sector->m_SectorX + 2; if (ex2>m_SectorMinX + m_SectorCntX) ex2 = m_SectorMinX + m_SectorCntX;
				int ey2 = planet2->m_Sector->m_SectorY + 2; if (ey2>m_SectorMinY + m_SectorCntY) ey2 = m_SectorMinY + m_SectorCntY;

				sec = m_Sector + ((sx2 - m_SectorMinX) + (sy2 - m_SectorMinY)*m_SectorCntX);
				for (y = sy2; y < ey2; y++, sec += m_SectorCntX - (ex2 - sx2)) {
					for (x = sx2; x < ex2; x++, sec++) {
						planet3 = sec->m_Planet;
						for (i = 0; i < sec->m_PlanetCnt; i++, planet3++)  {
							if (planet3 == planet) continue;
							if (planet3->m_Flag & (PlanetFlagWormhole | PlanetFlagSun | PlanetFlagGigant)) continue;

							if (planet3->m_IslandCalc) continue;

							if (planet3->m_Sector->m_SectorX < sx) continue;
							if (planet3->m_Sector->m_SectorY<sy) continue;
							if (planet3->m_Sector->m_SectorX >= ex) continue;
							if (planet3->m_Sector->m_SectorY >= ey) continue;

							int dx = planet3->m_PosX - planet2->m_PosX;
							int dy = planet3->m_PosY - planet2->m_PosY;

							if ((dx*dx + dy*dy)>JumpRadius2) continue;

							if (pcnt >= 1024) continue;

							plist[pcnt] = planet3;
							pcnt++;
							planet3->m_IslandCalc = 1;
						}
					}
				}
			}

			bool r = true;

			sec = m_Sector + ((sx - m_SectorMinX) + (sy - m_SectorMinY)*m_SectorCntX);
			for (y = sy; y < ey; y++, sec += m_SectorCntX - (ex - sx)) {
				for (x = sx; x < ex; x++, sec++) {
					planet3 = sec->m_Planet;
					for (i = 0; i < sec->m_PlanetCnt; i++, planet3++)  {
						if (planet3 == planet) continue;
						if (planet3->m_Island != planet3->m_IslandCalc) { r = false; }
						planet3->m_Island = 0;
						planet3->m_IslandCalc = 0;
					}
				}
			}

			//ALogFormat("pcnt2=<i> r=<i>",pcnt,int(r));

			return r;
		}

};


int _tmain(int argc, _TCHAR* argv[])
{

	inno nn;

	srand(unsigned(time(0)));

	nn.CreateMap(100, 100);

	return 0;
}