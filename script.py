import mysql.connector
import logging
import os
import random
import string
from dotenv import load_dotenv

# Загрузка переменных окружения из .env файла
load_dotenv()

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('database.log'),
        logging.StreamHandler()
    ]
)

def generate_random_string(length=8):
    """Генерация случайной строки заданной длины."""
    letters = string.ascii_letters
    return ''.join(random.choice(letters) for i in range(length))

try:
    # Данные подключения из переменных окружения
    db_config = {
        'host': os.getenv('DB_HOST', '$DB_HOST'),
        'user': os.getenv('DB_USER', '$DB_USER'),
        'password': os.getenv('DB_PASSWORD', '$DB_PASSWORD'),
        'database': os.getenv('DB_NAME', '$DB_NAME')
    }

    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    logging.info("Успешное подключение к базе данных")

    # Создание 200 таблиц
    for i in range(200):
        table_name = f'table_{i + 1}'
        columns = ', '.join([f'col_{j + 1} VARCHAR(8)' for j in range(50)])
        create_table_query = f"CREATE TABLE IF NOT EXISTS {table_name} (id INT AUTO_INCREMENT PRIMARY KEY, {columns})"
        cursor.execute(create_table_query)
        logging.info(f"Таблица {table_name} создана или уже существует")

        # Вставка 10 случайных записей в каждую таблицу
        for _ in range(10):
            values = ', '.join([f'"{generate_random_string(random.randint(4, 8))}"' for _ in range(50)])
            insert_query = f"INSERT INTO {table_name} ({', '.join([f'col_{j + 1}' for j in range(50)])}) VALUES ({values})"
            cursor.execute(insert_query)

    conn.commit()
    logging.info("Данные успешно добавлены во все таблицы")

except mysql.connector.Error as e:
    logging.error(f"Ошибка базы данных: {e}")
except Exception as e:
    logging.error(f"Общая ошибка: {e}")
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
        logging.info("Соединение с базой данных закрыто")

