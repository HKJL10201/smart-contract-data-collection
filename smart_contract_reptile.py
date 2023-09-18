# import csv
import requests
# from bs4 import BeautifulSoup
import time
import json

KEY1 = 'smart%20contract'
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
    return html
    # soup = BeautifulSoup(html, 'html.parser')
    # return soup


def get_url(key, category, page=1):
    url = 'https://github.com/search?q=%s%%20%s&type=repositories&p=%d' % (
        key, category, page)
    return url

def get_json(url, tm=10):
    while True:
        try:
            html = req(url)
            js=json.loads(html)
            return js
        except:
            time.sleep(tm)
            tm+=10

def reptile(key, category, page=1):
    def result_handler(payload:list)->list:
        '''
        return the names of repositories
        '''
        results=payload['results']
        return [r['hl_name'] for r in results]
    
    def result_writer(writer,results:list):
        writer.write('\n'.join(results).replace('<em>','').replace('</em>','')+'\n')
    
    url = get_url(key, category, page)
    dic = get_json(url)

    payload = dic['payload']
    page_count = payload['page_count']
    result_count = payload['result_count']
    print('%d %s %s repository results found' % (result_count, category, key))

    if result_count==0:
        return

    writer = open(key+'_'+category+'.log', 'w', encoding='utf-8')
    repo_names=result_handler(payload)
    result_writer(writer,repo_names)

    start = time.perf_counter()
    while page<page_count:
        dur = time.perf_counter() - start
        print("\r[{}/{}]{:.2f}s".format(page, page_count, dur), end="")
        
        page += 1
        url = get_url(key, category, page)
        dic = get_json(url)

        payload = dic['payload']
        repo_names=result_handler(payload)
        if len(repo_names)==0:
            break
        result_writer(writer,repo_names)

        # time.sleep(tm)
    writer.close()
    print("\n"+"done")


def main():
    for k in KEY:
        for c in classes:
            print('reptile start')
            reptile(k,c)
            print('>> reptile done.')


def test():
    url = 'https://github.com/search?q=smart+contract+wallet&type=repositories&p=101'
    html = req(url)
    # print(url)
    print(html)
    js=json.loads(html)
    print(js)


main()
# test()
