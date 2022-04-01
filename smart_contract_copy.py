import os

LOG = 'sol.log'
PATH = 'smart_contracts'


def main():
    with open(LOG, 'r') as f:
        for line in f:
            line = line.strip()
            word = line.split('/')
            filename = '.'.join(word[2:])
            path = PATH+'/'+word[1]
            filepath = path+'/'+filename
            if not os.path.exists(path):
                os.makedirs(path)
            os.system('cp "%s" "%s"' % (line, filepath))


main()
