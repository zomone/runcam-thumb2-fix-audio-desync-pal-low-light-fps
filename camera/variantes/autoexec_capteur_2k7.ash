sleep 2600
t sensor write 0 1 0x343 0x1a
sleep 3000
t sensor write 0 1 0x343 0x1a
t sensor dump 0 1 0x0342 2
sleep 2000
t imgproc -slowshutter 0 0
loop 100000; do t imgproc -slowshutter 0 0; sleep 2000; done
