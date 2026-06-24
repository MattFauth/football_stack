import urllib.request
from bs4 import BeautifulSoup
import sys

url = "https://www.transfermarkt.co.uk/lucio/profil/spieler/77"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    html = urllib.request.urlopen(req).read()
    soup = BeautifulSoup(html, 'html.parser')
    
    # Try to find 'Full name:' in the info table
    info_table = soup.find('div', {'class': 'info-table'})
    if info_table:
        for row in info_table.find_all('span', {'class': 'info-table__content'}):
            if 'Full name:' in row.text or 'Name in home country:' in row.text:
                next_span = row.find_next_sibling('span')
                if next_span:
                    print(f"FOUND: {next_span.text.strip()}")
                    sys.exit(0)
                    
    print("Not found in info-table")
except Exception as e:
    print(f"Error: {e}")
