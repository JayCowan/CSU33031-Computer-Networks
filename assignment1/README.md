# UDP Pub/Sub Protocol
From the assignment1 folder, run : `docker build -t assignment1 . && docker create --name broker -ti --net cs2031 -P assignment1 broker --port 50001 && docker create --name sub -ti --net cs2031  -P assignment1 sub --port 50001 && docker create --name pub -ti --net cs2031 -P  assignment1 pub --port 50001 `

Open the broker, sub then pub in that order by running:
* `docker start -i broker`
* `docker start -i sub`
  * Then enter the subjects you would like to subscribe to seperated by spaces then hit enter like this `temp humidity weather`
* `docker start -i pub`
  * Type the subject of the message you would like to send, then ': ' and then the message like this `subject: message`
  
To send example pub messages, type for example `temp: 45` or `humidity: 33%`

## How does it work?
First, all subscribers continuously send a registry request for their provided subjects to the broker until they recieve an acknowlegement. The subscriber sends a broadcast udp packet (which is interceptable) with the information it is sending on to the broker. The broker is listening for any UDP broadcast packets with the "type":"pub" in the header. Upon recieving a pub message, the broker then checks through all registered subscribers for the subject provided in the pub message. The broker also sends an acknowledgement through a unicast packet to the publisher who sent the packet. It then converts the message to a "forward" message and sends it on to the aforementioned subscribers provided for the subject in pub through a unicast direct UDP packet (which is not interceptible). 