import sched, time
import grequests
import datetime


s = sched.scheduler(time.time, time.sleep)

def do_something(sc):
    url = 'http://127.0.0.1:8000/handlers/external/received/4cd4708c-ea6a-4904-95cc-13b89b39aab7/?sender=%s&message=%s&ts=%d&id=%s'

    datas = []
    for i in range(100):

        url_tmp = url%(str(i),  datetime.datetime.now().strftime('%H:%M:%S'), 1, 4212341234)
        datas.append(url_tmp)
    rs = (grequests.post(url) for url in datas)
    lista =  grequests.map(rs)
    for i in lista:
        if i:
            print (i.status_code, i.content)
        else:
            print "Nada"
    s.enter(60, 1, do_something, (sc,))

s.enter(60, 1, do_something, (s,))
s.run()
