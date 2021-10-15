# UDP Pub/Sub Protocol
From the assignment1 folder, run : `docker build -t assignment1 . && docker create --name broker -ti --net cs2031 -P assignment1 broker --port 50001 && docker create --name sub -ti --net cs2031  -P assignment1 sub --brokerip 172.18.0.3 --port 50001 && docker create --name pub -ti --net cs2031 -P  assignment1 pub --brokerip 172.18.0.3 --port 50001`

Open the broker, sub then pub in that order by running:
* `docker start -i broker`
* `docker start -i sub`
* `docker start -i pub`
  
To send example pub messages, type for example `temp: 45` or `humidity: 33%`
