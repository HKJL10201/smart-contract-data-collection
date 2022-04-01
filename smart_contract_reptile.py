import csv
import requests
from bs4 import BeautifulSoup
import time

KEY1 = 'smart+contract'
KEY2 = 'dapp'
KEY = [KEY1, KEY2]

classes = ['auction', 'trading', 'wallet', 'lottery', 'dice', 'voting']


def req(url):
    # define header
    header = {}
    header['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'
    # create Request with header
    req = requests.get(url, headers=header)
    html = req.text
    soup = BeautifulSoup(html, 'html.parser')
    return soup


def get_sum(category):
    global KEY
    max_sum = 0
    max_k = ''
    tm = 0
    for k in KEY:
        url = 'https://github.com/search?q=%s+%s' % (k, category)
        soup = req(url)
        while soup.find('title').string == 'Rate limit · GitHub':
            tm += 10
            time.sleep(tm)
            soup = req(url)
        h3 = soup.find_all('h3')
        for h in h3:
            s = h.string.strip()
            if s.endswith('repository results'):
                n = int(s.split()[0].replace(',', ''))
                if n > max_sum:
                    max_sum = n
                    max_k = k
                break
        time.sleep(tm)
    return max_sum, max_k


def reptile(category, page=1, idx=0, tm=10):
    max_idx, key = get_sum(category)
    if max_idx == None:
        max_idx = 100
    else:
        print('%d %s %s repository results found' % (max_idx, category, key))

    scale = 50

    writer = csv.writer(open('dapp_'+category+'.csv', 'w',
                        newline='', encoding='utf-8'))

    print("START".center(scale, "-"))
    start = time.perf_counter()
    url = 'https://github.com/search?p=%d&q=%s+%s&type=Repositories' % (
        page, key, category)

    # while idx <= max_idx:
    while True:
        i = int(idx/max_idx*scale)
        a = "*" * i
        b = "." * (scale - i)
        c = (i / scale) * 100
        dur = time.perf_counter() - start
        print("\r{:^3.0f}%[{}->{}]{:.2f}s".format(c, a, b, dur), end="")

        soup = req(url)

        if soup.find('title').string == 'Rate limit · GitHub':    # Rate limit
            print(
                "\r{:^3.0f}%[{}->{}]{:.2f}s (waiting)".format(c, a, b, dur), end="")
            # print('waiting...')
            time.sleep(30+tm)
            tm += 10
            continue

        links = soup.find_all('a', class_='v-align-middle')

        # writer.writerow([page,max_page])

        if links == None:
            break

        for link in links:
            name = link['href'][1:]
            dapp_url = 'https://github.com/'+name
            writer.writerow([name, dapp_url])
            idx += 1

        next_page = soup.find('a', class_='next_page')
        if next_page == None:
            # print(soup)
            break
        else:
            url = 'https://github.com/'+next_page['href']
        time.sleep(tm)
    print("\n"+"END".center(scale, "-"))
    # print("\n"+"done")


def main(category):
    print('reptile start')
    reptile(category)
    print('>> reptile done.')


def test():
    for c in classes:
        #print(c, get_sum(c))
        main(c)


# main()
test()
