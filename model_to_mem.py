#input vertex coordiates as ints
def print_line(v1, v2, v3, c):
    line = format_v(v1) + format_v(v2) + format_v(v3) + format_c(c)
    hstr = '%0*X' % ((len(line) + 3) // 4, int(line, 2))
    print(hstr)


def format_c(c):
    return '{0:b}'.format(c[0]).zfill(3) + '{0:b}'.format(c[1]).zfill(4) + '{0:b}'.format(c[2]).zfill(3)


def format_v(v):
    s = ''
    for i in v:
        if i<0:
            s += '{0:b}'.format(i % (1<<6)).zfill(6)
        else:
            s += '{0:b}'.format(i).zfill(6)

    return s




if __name__ == '__main__':
    LINES = 4
    #each list should be same length of tuple (x,y,z) in ints (r,g,b) for color
    V1 = [(-15,-15,-20), (-15, 15, -20),  (-15, 15, -20), (15, 15, -20)]
    V2 = [(15,-15, -20), (-15, -15, -20), (15, 15, -20),  (15, -15, -20)]
    V3 = [(0,0, 20),   (0, 0, 20),    (0, 0, 20),    (0, 0, 20)]
    C = [(0,8,0), (0, 0, 7), (7,0,0), (4,4,4)]

    for i in range(LINES):
        print_line(V1[i], V2[i], V3[i], C[i])