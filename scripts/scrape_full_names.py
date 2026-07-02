import asyncio
import aiohttp
from bs4 import BeautifulSoup
import csv
import os

# Database configuration
DB_PARAMS = {
    'dbname': 'football',
    'user': 'football',
    'password': 'football',
    'host': 'localhost',
    'port': '5432'
}

CSV_FILE = 'dbt/seeds/player_full_names.csv'

async def fetch_name(session, player_id, url, semaphore):
    async with semaphore:
        try:
            # Transfermarkt blocks requests without a User-Agent
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            async with session.get(url, headers=headers, timeout=15) as response:
                if response.status != 200:
                    print(f"[{player_id}] Error: HTTP {response.status}")
                    return player_id, None
                
                html = await response.text()
                soup = BeautifulSoup(html, 'html.parser')
                info_table = soup.find('div', {'class': 'info-table'})
                
                if info_table:
                    for row in info_table.find_all('span', {'class': 'info-table__content'}):
                        if 'Full name:' in row.text or 'Name in home country:' in row.text:
                            next_span = row.find_next_sibling('span')
                            if next_span:
                                full_name = next_span.text.strip()
                                print(f"[{player_id}] Found: {full_name}")
                                return player_id, full_name
                                
                print(f"[{player_id}] Not found in HTML")
                return player_id, None
        except Exception as e:
            print(f"[{player_id}] Exception: {e}")
            return player_id, None

async def main():
    print("Reading missing names from CSV...")
    players = []
    with open('scratch/missing_names.csv', 'r', encoding='utf-16') as f:
        reader = csv.reader(f)
        for row in reader:
            if row and len(row) >= 2:
                players.append((row[0], row[1]))
    
    print(f"Found {len(players)} players missing first name.")
    
    # Check already scraped
    already_scraped = set()
    if os.path.exists(CSV_FILE):
        with open(CSV_FILE, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            next(reader, None) # skip header
            for row in reader:
                if row:
                    already_scraped.add(int(row[0]))
                    
    to_scrape = [(pid, url) for pid, url in players if int(pid) not in already_scraped]
    print(f"{len(already_scraped)} already scraped. {len(to_scrape)} remaining.")
    
    # We will use a relatively high concurrency to finish quickly,
    # but not too high to get IP banned. 15 concurrent requests is a good balance.
    semaphore = asyncio.Semaphore(15)
    
    # Open CSV in append mode
    mode = 'a' if os.path.exists(CSV_FILE) else 'w'
    with open(CSV_FILE, mode, newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if mode == 'w':
            writer.writerow(['player_id', 'full_name'])
            
        async with aiohttp.ClientSession() as session:
            tasks = [fetch_name(session, pid, url, semaphore) for pid, url in to_scrape]
            
            # Use as_completed to write to file as soon as they finish
            count = 0
            for task in asyncio.as_completed(tasks):
                pid, full_name = await task
                count += 1
                if full_name:
                    writer.writerow([pid, full_name])
                    f.flush() # ensure it's written immediately
                
                if count % 100 == 0:
                    print(f"Progress: {count}/{len(to_scrape)}")

    print("Scraping completed!")

if __name__ == '__main__':
    asyncio.run(main())
