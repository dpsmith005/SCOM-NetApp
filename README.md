# SCOM-NetApp
This is the SCOM management pack I created to monitor Netapp volumes.  This is the first version with basic volume discovery and used space monitor.  I plan to add additional monitors and discoveries as time permits.

The full Visual Studio folder was added to this repository.

The initial discovery is based on a registry value on a SCOM management server.  Upon discovery of this item, the server is added as a Netapp computer proxy.  There is a registry string which contains a comma separated list of the Netapp clusters.  Once detected the Netapp Clusters are discovered.  After the Netapp clusters are discovered, the volumes are discovered.

There are only a few basic steps to get this working.  First import the management pack into SCOM.  Then add a registry entry at HKLM\SOFTWARE\WSH\NetApp\Controllers on one of the SCOM management server.  Controllers should be a string with a comma separated list of the Netapp cluster names.  Then let the magic begin.

The management pack can be downloaded here in the bin\release folder. 
 XML found here https://github.com/dpsmith005/SCOM-NetApp/tree/main/Windows.Computer.Netapp/bin/Release

There are 2 monitors in this MP.  The one is a 3 state monior for the volume used space.  The second monitor is a 2 state monitor for the files used percent.  In addition, there are ping monitors for the computer acting as the proxy and the Netapp clusters.

Relationsips are created so the diagram view will work to see all the volumes of a particular cluster.  This also allows all the volumes to be placed in maintenance mode when the cluster is placed in maintenance mode.  If you need some assistance send questions to dpsmith005@mail.com.

### return to website https://dpsmith005.github.io/
