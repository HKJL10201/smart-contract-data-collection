import os
import csv

PATH = 'contracts'

classes=['auction','trading','wallet','lottery','dice','voting']

def get_links(file):
    res = []
    r = csv.reader(open(file, 'r', encoding='utf-8'))
    for line in r:
        name, url = line
        if url[:5] == 'https':
            res.append(url)
    return res


def download(links, path='contracts'):
    if not os.path.exists(path):
        os.makedirs(path)
    print('start cloning...')
    idx = 1
    for link in links:
        folder = '%03d' % idx
        print('\r%s'%folder,end='')
        os.system('cd ' + path+' && mkdir '+folder+' && cd '+folder +
                  ' && git clone '+link.strip())
        idx += 1
    print('\n>> finish cloning.')


def main():
    global classes, PATH
    for c in classes:
        print('>>>>>>>>>>>>'+c)
        fn='dapp_'+c+'.csv'
        path=PATH+'/'+c
        download(get_links(fn), path)

main()