import os

PATH = 'contracts'
OUT = 'sol.log'


def find(obj, log):
    if obj.endswith(".sol"):  # endswith()
        log.write(str(obj)+'\n')


def print_list_dir(dir_path, log):
    dir_files = os.listdir(dir_path)  # get file list
    dir_files.sort()
    for file in dir_files:
        file_path = os.path.join(dir_path, file)  # combine path
        if os.path.isfile(file_path):  # check is file
            find(file_path, log)
        if os.path.isdir(file_path):  # traverse directory
            print_list_dir(file_path, log)


def main(path=PATH):
    l = open(OUT, 'w')
    print_list_dir(path, l)


main(PATH)
