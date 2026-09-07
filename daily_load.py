import os
import requests
import pandas as pd
import psycopg2

from psycopg2.extras import execute_values
from datetime import date, timedelta

API_URL = "http://final-project.simulative.ru/data"


# Параметры подключения к PostgreSQL
DB_CONFIG = {
    "host": os.environ["DB_HOST"],
    "port": int(os.getenv("DB_PORT", "5432")),
    "dbname": os.environ["DB_NAME"],
    "user": os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"]
}


# 1. Получение данных из API за конкретную дату

def get_data(date_str):
    response = requests.get(
        API_URL,
        params={"date": date_str},
        timeout=30
    )
    #Проверка статуса ответа
    response.raise_for_status()
    data = response.json()

    df = pd.DataFrame(data)

    return df


# 2. Подготовка данных перед загрузкой в PostgreSQL
def prepare_data(df):
    df["purchase_datetime"] = pd.to_datetime(
        df["purchase_datetime"]
    ).dt.date

    return df


#3. Загрузка подготовленных данных в PostgreSQL

def load_to_postgres(df, date_str):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    # Защита от повторного запуска скрипта, при котором бы дублировались записи.
    try:
        cursor.execute(
            """
            DELETE FROM sales
            WHERE purchase_datetime = %s;
            """,
            (date_str,)
        )
        # Явно приводим значения к нужным типам Python
        records = [
            (
                int(row.client_id),
                row.gender,
                row.purchase_datetime,
                int(row.purchase_time_as_seconds_from_midnight),
                int(row.product_id),
                int(row.quantity),
                int(row.price_per_item),
                int(row.discount_per_item),
                float(row.total_price)
            )
            for row in df.itertuples(index=False)
        ]


        # Подготавливаем SQL-инсерт.
        query = """
            INSERT INTO sales (
                client_id,
                gender,
                purchase_datetime,
                purchase_time_as_seconds_from_midnight,
                product_id,
                quantity,
                price_per_item,
                discount_per_item,
                total_price
            )
            VALUES %s;
        """


        #Сразу вставляем большое количество строк
        execute_values(
            cursor,
            query,
            records,
            page_size=1000
        )


        # Фиксируем изменения
        conn.commit()


        print(
            f"{date_str}: успешно загружено "
            f"{len(records)} строк"
        )

    # Если произошла ошибка,
    # откатываем изменения
    except Exception as error:

        conn.rollback()

        print(
            f"{date_str}: ошибка при загрузке: "
            f"{error}"
        )

        raise

    # Закрываем соединение с базой
    finally:
        cursor.close()
        conn.close()


# Основная функция ежедневной загрузки
def main():
    yesterday = date.today() - timedelta(days=1)
    date_str = yesterday.strftime("%Y-%m-%d")
    print(
        f"Начинаем загрузку данных за {date_str}"
    )

    try:
        df = get_data(date_str)
        print(
            f"{date_str}: получено "
            f"{len(df)} строк из API"
        )

        if df.empty:
            print(
                f"{date_str}: данных нет"
            )
            return

        df = prepare_data(df)
        # Загружаем данные в PostgreSQL

        load_to_postgres(
            df,
            date_str
        )

        print(
            f"{date_str}: загрузка успешно завершена"
        )

    except Exception as error:
        print(
            f"{date_str}: загрузка завершилась с ошибкой: "
            f"{error}"
        )

        raise

if __name__ == "__main__":
    main() 