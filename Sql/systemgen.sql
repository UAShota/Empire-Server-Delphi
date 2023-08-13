/* Заполнение юнитов на карте */
delete from pl_data_ships;
-- враги
insert into pl_data_ships(ID_SYSTEM, ID_PLANET, ID_SLOT, ID_OWNER, ID_TYPE, COUNT, hp) select aa.id_system, aa.uid, 1, 3, 2, 999, 1000  from pl_data_planets aa where aa.id_planet_type = 2 and coord_x< 2000 and coord_y < 2000;
insert into pl_data_ships(ID_SYSTEM, ID_PLANET, ID_SLOT, ID_OWNER, ID_TYPE, COUNT, hp) select aa.id_system, aa.uid, 2, 3, 3, 100, 1000  from pl_data_planets aa where aa.id_planet_type = 2 and coord_x< 2000 and coord_y < 2000;
insert into pl_data_ships(ID_SYSTEM, ID_PLANET, ID_SLOT, ID_OWNER, ID_TYPE, COUNT, hp) select aa.id_system, aa.uid, 4, 3, 3, 100, 1000  from pl_data_planets aa where aa.id_planet_type = 2 and coord_x<2000 and coord_y < 2000;
insert into pl_data_ships(ID_SYSTEM, ID_PLANET, ID_SLOT, ID_OWNER, ID_TYPE, COUNT, hp) select aa.id_system, aa.uid, 5, 3, 5, 666, 1000  from pl_data_planets aa where aa.id_planet_type = 2 and coord_x< 2000 and coord_y < 2000;
insert into pl_data_ships(ID_SYSTEM, ID_PLANET, ID_SLOT, ID_OWNER, ID_TYPE, COUNT, hp) select aa.id_system, aa.uid, 6, 3, 7, 20,  1000  from pl_data_planets aa where aa.id_planet_type = 2 and coord_x< 2000 and coord_y < 2000;
-- научки
insert into pl_data_ships(ID_SYSTEM, ID_PLANET, ID_SLOT, ID_OWNER, ID_TYPE, COUNT, hp) select aa.id_system, aa.uid, 16, aa.ID_SYSTEM, 9, 1, 40000  from pl_data_planets aa where aa.id_planet_type =1 and coord_x< 500 and coord_y < 500;
insert into pl_data_ships(ID_SYSTEM, ID_PLANET, ID_SLOT, ID_OWNER, ID_TYPE, COUNT, hp) select aa.id_system, aa.uid, 16, aa.ID_SYSTEM, 9, 1, 40000  from pl_data_planets aa where aa.id_planet_type =2 and coord_x< 500 and coord_y < 500;
-- модули на складa
delete from pl_data_storage;
insert into pl_data_storage select aa.id_system, aa.uid, 2, 800000, 0, 1  from pl_data_planets aa where aa.id_planet_type = 2 and coord_x< 2000 and coord_y < 2000;
-- роли вражеским планетам
update pl_data_planets set ID_OWNER=id_system where ID_PLANET_TYPE=1 and  coord_x< 2000 and coord_y < 2000;

/* Заполнение зданий игроков */
delete from pl_data_building;
insert into pl_data_building(ID_SYSTEM, ID_PLANET, ID_TYPE, `POSITION`, LEVEL) select id_system, UID, 1, 1, 5 from pl_data_planets where ID_PLANET_TYPE=1;
insert into pl_data_building(ID_SYSTEM, ID_PLANET, ID_TYPE, `POSITION`, LEVEL) select id_system, UID, 1, 2, 5 from pl_data_planets where ID_PLANET_TYPE=1;
insert into pl_data_building(ID_SYSTEM, ID_PLANET, ID_TYPE, `POSITION`, LEVEL) select id_system, UID, 1, 3, 5 from pl_data_planets where ID_PLANET_TYPE=1;

/* Заполнение хранилища игроков */
delete from sh_data_holding;
insert into sh_data_holding SELECT UID, 1, 1, 3, 99999999 from sh_data_players;
insert into sh_data_holding SELECT UID, 2, 1, 3, 99999999 from sh_data_players;
insert into sh_data_holding SELECT UID, 4, 1, 3, 99999999 from sh_data_players;

/* Заполнение ангара игроков */
delete from pl_data_hangar;
insert into pl_data_hangar SELECT UID, 2,	90000,	3,	50000,	4,	40000,	6,	40000,	5,	30000,	null,	null, 11, 1 from sh_data_players;

/* Технологии бота */
delete from pl_data_tech_user;
-- самопочинка стационарок
insert INTO pl_data_tech_user select uid, 1, 7, 9, 2 from sh_data_players where bot=1;
insert INTO pl_data_tech_user select uid, 1, 8, 9, 2 from sh_data_players where bot=1;
insert INTO pl_data_tech_user select uid, 1, 9, 9, 2 from sh_data_players where bot=1;
insert INTO pl_data_tech_user select uid, 1, 10, 9, 2 from sh_data_players where bot=1;
