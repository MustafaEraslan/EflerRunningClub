-- DEVELOPMENT ONLY. Run after the core migration while signed in as an admin.
insert into public.efeler_runs(app_id,title,starts_at,location,status,points)
values
 ('efeler','Salı Tempo Koşusu',now()+interval '2 days','Aydın Tekstil Park','scheduled',10),
 ('efeler','Pazar Uzun Koşu',now()+interval '6 days','Efeler Kent Meydanı','scheduled',20);

insert into public.efeler_rewards(app_id,name,description,points_cost,stock,active)
values
 ('efeler','Kulüp Tişörtü','Nefes alan teknik kumaş',100,25,true),
 ('efeler','Koşu Çorabı','Efeler Running Club baskılı',60,40,true),
 ('efeler','Kulüp Buff’ı','Çok amaçlı boyunluk',45,30,true);
