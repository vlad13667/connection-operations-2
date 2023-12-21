create table reader(
    cod_reader integer not null  constraint  reader_p primary key ,
    reader_surname text not null,
    reader_name text not null ,
    second_name text,
    address text not null

);
create table  book(
    code_book integer not null  constraint  book_p primary key,
    book_name text not null,
    year_publication integer not null

);
create table subscription(
    code_reader integer not null constraint subscription_p references reader on update cascade on delete cascade,
    code_book integer not null constraint  book_p references book on update cascade on delete cascade,
    date_issue date not null,
    date_return date not null
);


create  or replace  view  lib as
    select  reader_name,reader_surname,second_name,address,book_name,year_publication,date_issue,date_return from reader inner join subscription s on reader.cod_reader = s.code_reader inner join book b on b.code_book = s.code_book

create or replace function delete_tg() returns trigger as $$
    declare
        reader_code int;
        book_code int;
    begin
        select cod_reader from reader where reader_surname = old."reader_surname" and reader_name = old."reader_name" and second_name=old."second_name" and address = old."address"   into reader_code;
        select code_book from book where book_name = old."book_name" and  year_publication = old."year_publication" into book_code;
        delete from subscription WHERE code_reader = reader_code and code_book = book_code and date_issue = old."date_issue" and date_return=old."date_return"  ;
        return null;
    end;
    $$ language plpgsql;

create or replace function insert_update() returns trigger as $$
    declare
        reader_code int;
        book_code int;
    begin
        select cod_reader from reader where reader_surname = new."reader_surname" and reader_name = new."reader_name" and second_name=new."second_name" and address = new."address"   into reader_code;
        select code_book from book where book_name = new."book_name" and  year_publication = new."year_publication" into book_code;
        if book_code is null then
            insert into book values ((select count(*) from  book)+1, new."book_name" , new."year_publication")
                                returning code_book into book_code;
        end if;
        if reader_code is null then
            insert into reader values ((select count(*) from  reader)+1, new."reader_surname", new."reader_name",new."second_name",new."address")
                                      returning cod_reader into reader_code;
        end if;
        if(tg_op = 'INSERT') then begin
            if (NOT EXISTS(SELECT * from subscription where code_reader = reader_code and code_book = book_code)) then
             INSERT INTO subscription
             VALUES (reader_code, book_code, new."date_issue",new."date_return");
             end if ;
             end;
        else
            update subscription set code_reader = reader_code, code_book = book_code, date_issue = new."date_issue" , date_return = new."date_return"
             where code_reader = (select code_reader from reader where reader_surname = old."reader_surname" and reader_name = old."reader_name" and second_name = old.second_name and address = old."address"  ) and
                   code_book = (select code_book from book where book_name = old."book_name" and year_publication = old."year_publication" );
        end if;
        return null;
    end
    $$ language plpgsql;

create trigger insert_update instead of update or insert on lib
    for each row execute procedure insert_update();

create trigger delete INSTEAD OF delete on lib
  for each row execute procedure delete_tg();

select * from "lib";

insert into "lib" values ('Ростислав','альбертович','Иоанов','маршала 3','Маша и медведь','2000','11.11.2001','25.11.2001');
insert into "lib" values ('Рома','альбертович','Иоанов','маршала 3','Cон','1998','11.11.2001','25.11.2001');

select * from "lib";
update "lib" set date_return = '12.01.2003'
                      where reader_name = 'Олег' and reader_surname = 'Петров' and second_name = 'Олегович' and book_name = 'Дежавю, Богемский реп, сода и я'  AND year_publication = '2022';

select * from "lib";

delete from lib where reader_name = 'Олег' and reader_surname = 'Петров' and second_name = 'Олегович' and book_name = 'Затмение: корона' AND year_publication = '2014';

select * from "lib";

drop view "lib";
drop table reader;
drop table book;
drop table subscription;
drop function delete_tg();
drop function insert_update();

update "lib" set year_publication = 2021 where reader_name = 'Олег' and reader_surname = 'Петров' and second_name = 'Олегович' and book_name = 'Дежавю, Богемский реп, сода и я'  AND year_publication = '2022';


