
create table bdz_jezdnia_delta(
	id serial primary key, 
	idref integer, 
	old text, 
	new text, 
	data date, 
	operator text
);
	
create table BDZ_RodzNaw(
	id text primary key,
	nazwa text
);
insert into BDZ_RodzNaw values ('bt','beton'),('br','bruk'),('gr','gruntNaturalny'),('kl','klinkier'),('kk','kostkaKamienna'),('kp','kostkaPrefabrykowana'),('mb','masaBitumiczna'),('pb','plytyBetonowe'),('gz','stabilizowanaZwiremlubZuzlem'),('tl','tluczen'),('zw','zwir'),('i','inny');

create table BDZ_RodzKomun(
	id text primary key,
	nazwa text
);
insert into BDZ_RodzKomun values ('rl','ruchLotniczy'),('rd','ruchDrogowy'),('rp','ruchPieszy'),('rr','ruchRowerowy'),('rpr','ruchPieszyIRowerowy');

create table BDZ_RodzajCRPIR(
	id text primary key,
	nazwa text
);

insert into BDZ_RodzajCRPIR values ('ap','alejka'),('ch','chodnik'),('pm','pasaz'),('sc','sciezka');

create table BDZ_RodzajObKomun(
	id text primary key,
	nazwa text
);

insert into BDZ_RodzajObKomun values ('bd','barieraDrogowaOchronna'),('b','brama'),('e','ekranAkustyczny'),('f','furtka'),('o','ogrodzenieTrwale'),('s','schodyWCiaguKomunikacyjnym');

create table BDZ_Poziom(
	id text primary key,
	nazwa text
);

insert into BDZ_Poziom values ('-2','drugiPoziomPodPowierzchniaGruntu'),('-1','pierwszyPoziomPodPowierzchniaGruntu'),('0','naPowierzchniGruntu'),('1','pierwszyPoziomPonadPowierzchniaGruntu'),('2','drugiPoziomPonadPowierzchniaGruntu'),('3','trzeciPoziomPonadPowierzchniaGruntu'),('4','czwartyPoziomPonadPowierzchniaGruntu');

create table BDZ_Zrodlo(
	id text primary key,
	nazwa text
);

insert into BDZ_Zrodlo values ('O','pomiarNaOsnowe'),('D','digitalizacjaIWektoryzacja'),('F','fotogrametria'),('I','inne'),('M','pomiarWoparciuOelementyMapy'),('N','niepoprawne'),('X','nieokreslone');

create table BT_OznaczenieZasobu(
	id text primary key,
	nazwa text
);

insert into BT_OznaczenieZasobu values('C','centralny'),('W','wojewodzki'),('P','powiatowy');

create table BT_IdMaterialu(
	id serial primary key,
	pierwszyCzlon text references BT_OznaczenieZasobu(id),
	drugiCzlon text check(case when pierwszyCzlon = 'C' then drugiCzlon = 'PL' else true end),
	trzeciCzlon integer,
	czwartyCzlon integer
);
create index idmaterialu_oznaczeniezasobu_idx on BT_IdMaterialu(pierwszyCzlon);
vacuum analyze BT_IdMaterialu(pierwszyCzlon);


create extension postgis;
select postgis_full_version();



create table BDZ_ObiektZwiazanyZKomunikacja(
	id text primary key,
	rodzajObKomun text references BDZ_RodzajObKomun(id),
	startObiekt date not null,
	koniecWersjiObiektu date check (koniecWersjiObiektu < poczatekWersjiObiektu),
	koniecObiekt date,											
	poczatekWersjiObiektu date not null,
	zrodlo text not null references BDZ_Zrodlo(id),
	dokument text,
	informacja text,
	dataPomiaru date check (case when zrodlo = 'o' then dataPomiaru is not null else true end),
	geometriaPoly geometry(POLYGON, 2180) check (rodzajObKomun IN ('o','s')),
	geometriaLine geometry(LINESTRING, 2180) check (rodzajObKomun IN ('o','bd','b','e','f')),
	poliliniaKierunkowa geometry(LINESTRING, 2180) check (rodzajObKomun ='s')											
);
create index obiekt_rodzaj_idx on BDZ_ObiektZwiazanyZKomunikacja(rodzajObKomun);
create index obiekt_zrodlo_idx on BDZ_ObiektZwiazanyZKomunikacja(zrodlo);
create index obiekt_geomPoly_idx on BDZ_ObiektZwiazanyZKomunikacja using gist(geometriaPoly);
create index obiekt_geomLine_idx on BDZ_ObiektZwiazanyZKomunikacja using gist(geometriaLine);
create index obiekt_polilinia_idx on BDZ_ObiektZwiazanyZKomunikacja using gist(poliliniaKierunkowa);
vacuum analyze BDZ_ObiektZwiazanyZKomunikacja(rodzajObKomun);
vacuum analyze BDZ_ObiektZwiazanyZKomunikacja(zrodlo);
vacuum analyze BDZ_ObiektZwiazanyZKomunikacja(geometriaPoly);
vacuum analyze BDZ_ObiektZwiazanyZKomunikacja(geometriaLine);
vacuum analyze BDZ_ObiektZwiazanyZKomunikacja(poliliniaKierunkowa);

	
create table int_ObiektZwZKom_IdMaterialu(
	id serial primary key,
	obiektId text references BDZ_ObiektZwiazanyZKomunikacja(id) not null,
	materialId integer references BT_IdMaterialu(id) not null		
);
create index int_obiekt_idmaterialu_obiektid_idx on int_ObiektZwZKom_IdMaterialu(obiektId);
create index int_obiekt_idmaterialu_materialid_idx on int_ObiektZwZKom_IdMaterialu(materialId);
vacuum analyze int_ObiektZwZKom_IdMaterialu(obiektId);
vacuum analyze int_ObiektZwZKom_IdMaterialu(materialId);

create table BDZ_Jezdnia(
	id text primary key,
	geometria geometry(POLYGON,2180),
	poziom text references BDZ_Poziom(id),
	materialNaw text references BDZ_RodzNaw(id),
	startObiekt date not null,
	koniecWersjiObiektu date check (koniecWersjiObiektu < poczatekWersjiObiektu),
	koniecObiekt date,											
	poczatekWersjiObiektu date not null,
	zrodlo text not null references BDZ_Zrodlo(id),
	dokument text,
	informacja text,
	dataPomiaru date check (case when zrodlo = 'O' then dataPomiaru is not null else true end)
);
create index jezdnia_geom_idx on BDZ_Jezdnia using gist(geometria);
create index jezdnia_poziom_idx on BDZ_Jezdnia(poziom);
create index jezdnia_material_idx on BDZ_Jezdnia(materialNaw);
create index jezdnia_zrodlo_idx on BDZ_Jezdnia(zrodlo);
vacuum analyze BDZ_Jezdnia(geometria);
vacuum analyze BDZ_Jezdnia(poziom);
vacuum analyze BDZ_Jezdnia(materialNaw);
vacuum analyze BDZ_Jezdnia(zrodlo);

create materialized view mv_jezdnia as
select j.id, j.geometria, r.nazwa as rodzaj, z.nazwa as źródło from BDZ_Jezdnia as j, BDZ_RodzNaw as r, BDZ_Zrodlo as z
where j.materialNaw = r.id and j.zrodlo = z.id
with data;

create unique index mv_jezd_id_idx on mv_jezdnia(id);
create index mv_jezd_geom_idx on mv_jezdnia(geometria);
create index mv_jezd_rodz_idx on mv_jezdnia(rodzaj);
create index mv_jezd_zrodlo_idx on mv_jezdnia(źródło);
vacuum analyze mv_jezdnia(id);
vacuum analyze mv_jezdnia(geometria);
vacuum analyze mv_jezdnia(rodzaj);
vacuum analyze mv_jezdnia(żródło);

create table int_Jezdnia_RodzKomun(
	id serial primary key,
	idJezdnia text references BDZ_Jezdnia(id),
	idRodzKomun text references BDZ_RodzKomun(id) not null check (idRodzKomun IN ('rd', 'rl'))
);
create index int_jezdnia_rodzkomun_idjezdnia_idx on int_Jezdnia_RodzKomun(idJezdnia);
create index int_jezdnia_rodzkomun_idrodzkomun_idx on int_Jezdnia_RodzKomun(idRodzKomun);
vacuum analyze int_Jezdnia_RodzKomun(idJezdnia);
vacuum analyze int_Jezdnia_RodzKomun(idRodzKomun);

create table int_Jezdnia_IdMaterialu(
	id serial primary key,
	jezdniaId text references BDZ_Jezdnia(id) not null,
	materialId integer references BT_IdMaterialu(id) not null		
);
create index int_jezdnia_idmaterialu_jezdniaid_idx on int_Jezdnia_IdMaterialu(jezdniaId);
create index int_jezdnia_idmaterialu_materialid_idx on int_Jezdnia_IdMaterialu(materialId);
vacuum analyze int_Jezdnia_IdMaterialu(jezdniaId);
vacuum analyze int_Jezdnia_IdMaterialu(materialId);

create table BDZ_Plac(
	id text primary key,
	geometria geometry(POLYGON,2180),
	materialNaw text references BDZ_RodzNaw(id),
	startObiekt date not null,
	koniecWersjiObiektu date check (koniecWersjiObiektu < poczatekWersjiObiektu),
	koniecObiekt date,											
	poczatekWersjiObiektu date not null,
	zrodlo text not null references BDZ_Zrodlo(id),
	dokument text,
	informacja text,
	dataPomiaru date check (case when zrodlo = 'O' then dataPomiaru is not null else true end)
);
create index plac_geom_idx on BDZ_Plac using gist(geometria);
create index plac_material_idx on BDZ_Plac(materialNaw);
create index plac_zrodlo_idx on BDZ_Plac(zrodlo);
vacuum analyze BDZ_Plac(geometria);
vacuum analyze BDZ_Plac(materialNaw);
vacuum analyze BDZ_Plac(zrodlo);

create table int_Plac_RodzKomun(
	id serial primary key,
	idPlac text references BDZ_Plac(id),
	idRodzKomun text references BDZ_RodzKomun(id) not null
);
create index int_plac_rodzkomun_idplac_idx on int_Plac_RodzKomun(idPlac);
create index int_plac_rodzkomun_idrodzkomun_idx on int_Plac_RodzKomun(idRodzKomun);
vacuum analyze int_Plac_RodzKomun(idPlac);
vacuum analyze int_Plac_RodzKomun(idRodzKomun);

create table int_Plac_IdMaterialu(
	id serial primary key,
	placId text references BDZ_Plac(id) not null,
	materialId integer references BT_IdMaterialu(id) not null		
);
create index int_plac_idmaterialu_placid_idx on int_Plac_IdMaterialu(placId);
create index int_plac_idmaterialu_materialid_idx on int_Plac_IdMaterialu(materialId);
vacuum analyze int_Plac_IdMaterialu(placId);
vacuum analyze int_Plac_IdMaterialu(materialId);
	
create table BDZ_CiagRuchuPieszegoIRowerowego(
	id text primary key,
	geometria geometry(POLYGON,2180),
	rodzajCiagu text references BDZ_RodzajCRPIR(id),
	poziom text references BDZ_Poziom(id),
	materialNaw text references BDZ_RodzNaw(id),
	startObiekt date not null,
	koniecWersjiObiektu date check (koniecWersjiObiektu < poczatekWersjiObiektu),
	koniecObiekt date,											
	poczatekWersjiObiektu date not null,
	zrodlo text not null references BDZ_Zrodlo(id),
	dokument text,
	informacja text,
	dataPomiaru date check (case when zrodlo = 'O' then dataPomiaru is not null else true end)
);
create index ciagruchupir_geom_idx on BDZ_CiagRuchuPieszegoIRowerowego using gist(geometria);
create index ciagruchupir_rodzajciagu_idx on BDZ_CiagRuchuPieszegoIRowerowego(rodzajCiagu);
create index ciagruchupir_poziom_idx on BDZ_CiagRuchuPieszegoIRowerowego(poziom);
create index ciagruchupir_materialnaw_idx on BDZ_CiagRuchuPieszegoIRowerowego(materialNaw);
create index ciagruchupir_zrodlo_idx on BDZ_CiagRuchuPieszegoIRowerowego(zrodlo);
vacuum analyze BDZ_CiagRuchuPieszegoIRowerowego(geometria);
vacuum analyze BDZ_CiagRuchuPieszegoIRowerowego(rodzajCiagu);
vacuum analyze BDZ_CiagRuchuPieszegoIRowerowego(poziom);
vacuum analyze BDZ_CiagRuchuPieszegoIRowerowego(materialNaw);
vacuum analyze BDZ_CiagRuchuPieszegoIRowerowego(zrodlo);

create table int_CiagRuchu_RodzKomun(
	id serial primary key,
	idCiagRuchu text references BDZ_CiagRuchuPieszegoIRowerowego(id),
	idRodzKomun text references BDZ_RodzKomun(id) not null
	check (idRodzKomun in ('rp', 'rpr','rr'))
);
create index int_ciagruchu_rodzkomun_idciagruchu_idx on int_CiagRuchu_RodzKomun(idCiagRuchu);
create index int_ciagruchu_rodzkomun_idrodzkomun_idx on int_CiagRuchu_RodzKomun(idRodzKomun);
vacuum analyze int_CiagRuchu_RodzKomun(idCiagRuchu);
vacuum analyze int_CiagRuchu_RodzKomun(idRodzKomun);


create table int_CiagRuchu_IdMaterialu(
	id serial primary key,
	ciagRuchuId text references BDZ_CiagRuchuPieszegoIRowerowego(id) not null,
	materialId integer references BT_IdMaterialu(id) not null		
);
create index int_ciagruchu_idmaterialu_ciagruchuid_idx on int_CiagRuchu_IdMaterialu(ciagRuchuId);
create index int_ciagruchu_idmaterialu_materialid_idx on int_CiagRuchu_IdMaterialu(materialId);
vacuum analyze int_CiagRuchu_IdMaterialu(ciagRuchuId);
vacuum analyze int_CiagRuchu_IdMaterialu(materialId);


create trigger trg_akt_jezdnia
before update
on BDZ_Jezdnia
for each row
execute procedure fun_akt_jezdnia()

create or replace function fun_akt_jezdnia()
returns trigger
as
$$
begin
		if new.materialNaw is not null then
			insert into bdz_jezdnia_delta values(default,old.materialNaw,new.materialNaw,current_date, current_user,old.id);
		end if;
	return new;
end;
$$
language plpgsql volatile cost 100;

create or replace function funkcja(wsp text, promien integer) returns text as
$$
declare

aa text;
bb geometry(polygon,2180);
bufor geometry(polygon,2180);
ileinter integer := 0;
ileinside integer :=0;
suma integer :=0;

cur1 cursor(wspolrzedne text) for
	select
		p.id, p.geometria 
		from BDZ_Plac as p 
		where ST_Within(p.geometria,ST_GeomFromText(wspolrzedne,2180));
	rec1 record;
begin
	drop table if exists tabela_place;
	create table tabela_place(
		id serial primary key, 
		idref text, 
		geom geometry(polygon,2180), 
		ile_intersect integer, 
		ile_inside integer
);
	open cur1(wsp);
	loop
		fetch cur1 into rec1;
		exit when not found;
		
		aa := rec1.id;
		bb := rec1.geometria;
		
		bufor = ST_Buffer(bb, promien);
		select into ileinter count(*) from BDZ_Jezdnia as j where ST_Intersects(bufor, j.geometria);
		select into ileinside count (*) from BDZ_Jezdnia as j where ST_Within(j.geometria, bufor);
		insert into tabela_place values(default,aa,bufor,ileinter,ileinside);
		
		suma:=suma+1;
		
		end loop;
		close cur1;
		
		return suma;
		
	end;
	
	$$
	language plpgsql;

	
create table prostokat(
	id serial primary key,
	geom geometry(polygon, 2180)
);