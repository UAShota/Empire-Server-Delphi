update sh_data_players set PWD = SHA1('52424'), PWD_HASH=sha1(CONCAT(LOGIN,'52424')) where UID = 25;
insert into sh_data_holding  SELECT 25, `POSITION`, id_type, id_item, count from sh_data_holding where id_owner=6;
insert into pl_data_planets (ID_SYSTEM, ID_OWNER, COORD_X, COORD_Y, POS_X, POS_Y, ID_PLANET_TYPE) select 25, id_owner, COORD_X, COORD_Y, POS_X, POS_Y, ID_PLANET_TYPE from pl_data_planets where ID_SYSTEM=6;