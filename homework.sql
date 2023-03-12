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
        maxPriceId uuid;
    BEGIN
        if (select balance from users where id = sender)>=summa then
            if(select balance from users where id = receiver)>=0 then
                UPDATE users set balance = balance-summa*1.01 where id = sender;
                UPDATE users set balance = balance + summa where id = receiver;
                INSERT INTO click(sender_id,receive_id,price,comission)VALUES(sender,receiver,summa,summa*0.01);
                if (select count(*)>5 from click where sender_id=sender) then
                    UPDATE users set balance = balance + (select max(price)*0.005 from click where sender_id = sender and giveCashback=false) where id =sender;
                    SELECT id from click INTO maxPriceId  where sender_id = sender and price=(select max(price) from click where sender_id=sender and giveCashback=false) limit 1;
                    raise info '%',maxPriceId;
                    raise info 'cashback: %',(select max(price)*0.005 from click where sender_id = sender and giveCashback=false);
                    UPDATE click set giveCashback = true where id = maxPriceId;
                end if;
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


INSERT INTO users(name,balance)VALUES('Firdavs',2000000);
INSERT INTO users(name,balance)VALUES('Uacademy',0);

call payment('870014d6-6c17-4bfe-9108-2b92eb7ce51f','1818bbaf-9f57-4822-bd54-d62e24b1cea1',100000);






