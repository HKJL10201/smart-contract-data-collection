import os
import csv

PATH = 'contracts'

KEY1 = 'smart%20contract'
KEY2 = 'dapp'
KEY = [KEY1, KEY2]
# KEY = [KEY1]

classes = ['auction', 'trading', 'wallet', 'lottery', 'dice', 'voting']


def get_links(file):
    res = []
    r = open(file, 'r', encoding='utf-8')
    for line in r:
        url = line.strip()
        res.append(url)
    return res


def download(links, path='contracts'):
    if not os.path.exists(path):
        os.makedirs(path)
    print('start cloning...')
    n = len(str(len(links)))
    idx = 1
    for link in links:
        url = 'https://github.com/'+link.strip()+'.git'
        folder = ('{:0>'+str(n)+'d}').format(idx)
        print('\r%s' % folder, end='')
        os.system('cd ' + path+' && mkdir '+folder+' && cd '+folder +
                  ' && git clone '+url)
        idx += 1
    print('\n>> finish cloning.')


def main():
    global classes, PATH,KEY
    for k in KEY:
        for c in classes:
            print('>>>>>>>>>>>>'+c)
            fn = k+'_'+c+'.log'
            path = PATH+'/'+c
            download(get_links(fn), path)


main()
