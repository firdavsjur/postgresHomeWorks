CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE users(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name varchar not null,
    balance numeric DEFAULT 0,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE click(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id uuid not null,
    receive_id uuid not null,
    price numeric not null,
    comission numeric not null,
    giveCashback boolean DEFAULT false,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



create or replace procedure payment(sender uuid,receiver uuid,summa numeric) language plpgsql
as
$$
    DECLARE
        chekId uuid = uuid_generate_v4();
        maxPriceId uuid;
        chek record;
    BEGIN
        if (select balance from users where id = sender)>=summa then
            if(select balance from users where id = receiver)>=0 then
                UPDATE users set balance = balance-summa*1.01 where id = sender;
                UPDATE users set balance = balance + summa where id = receiver;
                INSERT INTO click(id,sender_id,receive_id,price,comission)VALUES(chekId,sender,receiver,summa,summa*0.01);
                if (select count(*)>5 from click where sender_id=sender) then
                    UPDATE users set balance = balance + (select max(price)*0.005 from click where sender_id = sender and giveCashback=false) where id =sender;
                    SELECT id from click INTO maxPriceId  where sender_id = sender and price=(select max(price) from click where sender_id=sender and giveCashback=false) limit 1;
                    UPDATE click set giveCashback = true where id = maxPriceId;
                end if;
                select * from getChek(chekId) into chek;
                raise info 'Chek: %',chek;
                COMMIT;
            else
                ROLLBACK;
                raise info 'Qabul qiluvchi topilmadi!';
            end if;

        else
            ROLLBACK;
            raise info 'Balansda mablag yetarli emas!';
        end if;

    END;

$$;

CREATE OR REPLACE function getChek(chekId uuid)returns TABLE(
    sender1 varchar,
    receiver1 varchar,
    price1 numeric,
    comission1 numeric,
    cashback1 numeric
) language plpgsql
as
$$
    DECLARE 
        var_result record;
    BEGIN

            
        FOR var_result IN(SELECT
            sender.name as Sender,
            receiver.name as Receiver,
            price as Price,
            comission as Komissiya,
            CASE giveCashback
                WHEN true then comission/2
                WHEN false then 0
                END as Cashback
            FROM click
            JOIN users as sender on sender.id = click.sender_id
            JOIN users as receiver on receiver.id = click.receive_id
            WHERE click.id = chekId)  
        LOOP
            sender1 := (var_result.sender) ; 
            receiver1 := (var_result.receiver) ; 
            price1 := (var_result.price) ; 
            comission1 := (var_result.komissiya) ; 
            cashback1 := (var_result.cashback) ; 
            RETURN NEXT;
        END LOOP;
        
    END;

$$;



INSERT INTO users(name,balance)VALUES('Firdavs',2000000);
INSERT INTO users(name,balance)VALUES('Uacademy',0);

call payment('435248de-b4b9-4f96-aa01-05b93665c89f','08379d00-5b71-427a-a055-56e77ffa826d',100000);






