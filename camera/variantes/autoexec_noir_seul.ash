sleep 10000
t imgproc -slowshutter 0 0
loop 100000; do t imgproc -slowshutter 0 0; sleep 2000; done
