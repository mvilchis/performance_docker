import sched, time
import grequests
import datetime



def do_something():
    start_time = time.time()
    url = 'http://127.0.0.1:8000/handlers/kannel/receive/b469a31f-0e79-438a-b28d-9a64f398ffb7/?backend=%i&sender={SENDER}&message={MESSAGE}&ts={TIME}&id={ID}&to={TO}"'

    datas = []
    for i in range(500):
        url_tmp = url.format(SENDER=str(i),
                            MESSAGE="trigger",
                            TIME=1,
                            ID=4212341234,
                            TO=12345)
        datas.append(url_tmp)
    rs = (grequests.post(url) for url in datas)
    lista =  grequests.map(rs)
    print time.time() - start_time
    with open("mensajes_raw", "a") as myfile:
        for i in lista:
            if i:
                myfile.write(str(i.status_code)+ ","+str(i.content)+"\n")
            else:
                myfile.write("Nada\n")

while True:
    do_something()
    time.sleep(60)
